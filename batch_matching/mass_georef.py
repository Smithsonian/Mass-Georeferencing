#!/usr/bin/env python3
#
# Mass Georeferencing script
# Version 0.1
#
# 25 Feb 2020
# 
# Digitization Program Office, 
# Office of the Chief Information Officer,
# Smithsonian Institution
# https://dpo.si.edu
#

#Import modules
import psycopg2, os, logging, sys, locale, psycopg2.extras, uuid, glob, subprocess
import pandas as pd
from time import localtime, strftime
from fuzzywuzzy import fuzz
import pycountry
from pyfiglet import Figlet
#import numpy as np
#from multiprocessing import  Pool
import swifter
from psycopg2.extras import execute_batch


#Script variables
script_title = "Mass Georeferencing"
subtitle = "Digitization Program Office\nOffice of the Chief Information Officer\nSmithsonian Institution\nhttps://dpo.si.edu"
ver = "0.1"
repo = "https://github.com/Smithsonian/Mass-Georeferencing"
lic = "Available under the Apache 2.0 License"


# Set locale to UTF-8
locale.setlocale(locale.LC_ALL, 'en_US.utf8')




#print script title and info
f = Figlet(font='slant')
print("\n")
print (f.renderText(script_title))
print("{subtitle}\n\n{repo}\n{lic}\n\nver. {ver}".format(subtitle = subtitle, ver = ver, repo = repo, lic = lic))



import settings




#################
# Set Logging
#################
#Get current time
current_time = strftime("%Y%m%d_%H%M%S", localtime())

if not os.path.exists('logs'):
    os.makedirs('logs')

logfile_name = 'logs/{}.log'.format(current_time)
# from http://stackoverflow.com/a/9321890
logging.basicConfig(level=logging.DEBUG,
                format='%(asctime)s %(name)-12s %(levelname)-8s %(message)s',
                datefmt='%m-%d %H:%M:%S',
                filename=logfile_name,
                filemode='a')
console = logging.StreamHandler()
console.setLevel(logging.INFO)
formatter = logging.Formatter('%(name)-12s: %(levelname)-8s %(message)s')
console.setFormatter(formatter)
logging.getLogger('').addHandler(console)
logger1 = logging.getLogger("mass_georef")






#Connect to the dpogis database
try:
    logger1.info("Connecting to the database.")
    conn = psycopg2.connect(host = settings.pg_host, database = settings.pg_db, user = settings.pg_user, connect_timeout = 60)
except:
    print(" ERROR: Could not connect to server.")
    sys.exit(1)

conn.autocommit = True
cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)


def check_spatial(data_source, species, candidate_id, feature_id, cur, logger1):
    if data_source == 'gbif.species' or data_source == 'gbif.genus':
        return
    else:
        cur.execute("""
            WITH data AS (
                    SELECT 
                        ST_Union(the_geom) as the_geom
                    FROM 
                        iucn
                    WHERE
                        sciname = '{species}'

                    UNION ALL

                    SELECT 
                        ST_ConvexHull(ST_Collect(the_geom)) as the_geom
                    FROM 
                        gbif
                    WHERE
                        species = '{species}'
            ),
            range AS (
                SELECT 
                    ST_Transform(ST_Union(the_geom), 3857) as the_geom_webmercator
                FROM
                    data
                ),
            calc AS (
                SELECT 
                    '{candidate_id}' as candidate_id, 
                    'locality.spatial' as score_type, 
                    ST_Distance(l.the_geom_webmercator, r.the_geom_webmercator) AS geom_dist 
                FROM 
                    {data_source} l, range r
                WHERE l.uid = '{feature_id}'::uuid
            )
            INSERT INTO mg_candidates_scores 
            (candidate_id, score_type, score) 
            (
                SELECT 
                    '{candidate_id}' as candidate_id, 
                    'locality.spatial' as score_type, 
                    CASE 
                        WHEN geom_dist = 0 THEN 100 
                        WHEN geom_dist > 0 AND geom_dist < 10000 THEN 95 
                        WHEN geom_dist > 0 AND geom_dist <= 10000 THEN 95 
                        WHEN geom_dist > 10000 AND geom_dist <= 50000 THEN 85 
                        WHEN geom_dist > 50000 AND geom_dist <= 100000 THEN 75
                        WHEN geom_dist > 100000 AND geom_dist <= 100000 THEN 65
                        ELSE 60
                        END AS score 
                FROM 
                    calc
            )""".format(candidate_id = candidate_id, data_source = data_source, species = species, feature_id = feature_id))
    logger1.debug(cur.query)



#Get collection to run from settings
cur.execute("SELECT * FROM mg_collex WHERE collex_id = %s", (settings.collex_id,))
logger1.debug(cur.query)
collex = cur.fetchone()
if collex == None:
    logger1.error("Collection not found")
    sys.exit(1)


#Select species
cur.execute(collex['collex_definition'])
logger1.debug(cur.query)
scinames = cur.fetchall()


#Delete previous records matches
for sciname in scinames:
    logger1.info("Deleting old matches for {}".format(sciname['species']))
    cur.execute("DELETE FROM mg_recordgroups WHERE species = %s", (sciname['species'],))
    logger1.debug(cur.query)



#Loop the species
for sciname in scinames:
    logger1.debug("sciname: {}".format(sciname['species']))
    #Get countrycodes for the species
    cur.execute("SELECT countrycode FROM mg_occurrences WHERE species = %s AND decimallatitude is null AND countrycode is not null AND lower(locality) <> ANY(ARRAY['none', 'unknown', 'no locality data']) GROUP BY countrycode", (sciname['species'],))
    logger1.debug(cur.query)
    countries = cur.fetchall()
    #Records with countrycode
    for country in countries:
        #Get records for the country
        cur.execute("SELECT locality, stateprovince, countrycode, recordedby, kingdom, phylum, class, _order, family, genus, species, count(*) as no_records FROM mg_occurrences WHERE species = %(species)s AND countrycode = %(countrycode)s AND decimallatitude IS NULL AND lower(locality) <> ANY(ARRAY['none', 'unknown', 'no locality data']) GROUP BY locality, stateprovince, countrycode, recordedby, kingdom, phylum, class, _order, family, genus, species", {'species': sciname['species'], 'countrycode': country['countrycode']})
        logger1.debug(cur.query)
        records_g = pd.DataFrame(cur.fetchall())
        records_g['recgroup_id'] = [uuid.uuid4() for _ in range(len(records_g.index))]
        records_g['recgroup_id'] = records_g['recgroup_id'].astype(str)
        logger1.info("Found {} records of {} in {}".format(len(records_g), sciname['species'], country['countrycode']))
        records_g['collex_id'] = settings.collex_id
        records_g_insert = records_g[['recgroup_id', 'collex_id', 'locality', 'stateprovince', 'countrycode', 'recordedby', 'kingdom', 'phylum', 'class', '_order', 'family', 'genus', 'species', 'no_records']].copy()
        #print(records_g_insert)
        records_g_insert2 = records_g_insert.values.tolist()
        psycopg2.extras.execute_batch(cur, """INSERT INTO mg_recordgroups 
                                                (recgroup_id, collex_id, locality, stateprovince, countrycode, recordedby, kingdom, phylum, class, _order, family, genus, species, no_records)
                                            VALUES 
                                                (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)""", 
                                                records_g_insert2)
        #Insert link to records by group
        for index, record in records_g.iterrows():
            cur.execute("INSERT INTO mg_records (recgroup_id, mg_occurrenceid, updated_at) (SELECT %(recgroup_id)s as recgroup_id, mg_occurrenceid, NOW() FROM mg_occurrences WHERE species = %(species)s AND countrycode = %(countrycode)s AND decimallatitude IS NULL AND lower(locality) <> ANY(ARRAY['none', 'unknown', 'no locality data']) AND locality = %(locality)s AND stateprovince = %(stateprovince)s AND kingdom = %(kingdom)s AND phylum = %(phylum)s AND class = %(class)s AND _order = %(_order)s AND family = %(family)s AND genus = %(genus)s)", {'species': sciname['species'], 'countrycode': country['countrycode'], 'locality': record['locality'], 'stateprovince': record['stateprovince'], 'kingdom': record['kingdom'], 'phylum': record['phylum'], 'class': record['class'], '_order': record['_order'], 'family': record['family'], 'genus': record['genus'], 'recgroup_id': record['recgroup_id']})
            logger1.debug(cur.query)
        #GBIF - species
        query_template = "SELECT MAX(gbifid::bigint) as uid, locality as name, count(*) as no_records, countrycode, trim(leading ', ' from replace(municipality || ', ' || county || ', ' || stateprovince || ', ' || countrycode, ', , ', '')) as located_at, stateprovince, recordedBy, decimallatitude, decimallongitude, count(*) as no_features FROM gbif WHERE species = %(species)s AND lower(locality) <> ANY(ARRAY['none', 'unknown', 'no locality data']) AND countrycode = %(countrycode)s AND decimallatitude IS NOT NULL GROUP BY countrycode, locality, municipality, county, stateprovince, recordedBy, decimallatitude, decimallongitude"
        cur.execute(query_template, {'species': sciname['species'], 'countrycode': country['countrycode']})
        logger1.debug(cur.query)
        allcandidates = pd.DataFrame(cur.fetchall())
        logger1.info("No. of GBIF candidates: {}".format(len(allcandidates)))
        if len(allcandidates) > 0:
            #Iterate each record
            for index, record in records_g.iterrows():
                candidates = allcandidates.copy()
                candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
                ##################
                #Execute matches
                ##################
                #locality
                candidates['score1'] = candidates.swifter.allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name']), axis = 1)
                candidates['score2'] = candidates.swifter.allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince']), axis = 1)
                candidates['score3'] = candidates.swifter.allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality'], row['name']), axis = 1)
                candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                #ADJUST SCORE HERE, IF NEEDED
                #
                #Batch insert
                candidates['recgroup_id'] = record['recgroup_id']
                insert_list = candidates[['candidate_id', 'recgroup_id', 'uid', 'no_features']].copy()
                insert_list['candidate_id'] = insert_list['candidate_id'].astype(str)
                insert_list = insert_list.values.tolist()
                psycopg2.extras.execute_batch(cur, """INSERT INTO mg_candidates 
                                            (candidate_id, recgroup_id, data_source, feature_id, no_features) 
                                        VALUES 
                                            (%s, %s, 'gbif.species', %s, %s)""", 
                                            insert_list)
                logger1.debug(cur.query)
                insert_list_scores = candidates[['candidate_id', 'score1']].copy()
                insert_list_scores['candidate_id'] = insert_list_scores['candidate_id'].astype(str)
                insert_list_scores = insert_list_scores.values.tolist()
                psycopg2.extras.execute_batch(cur, """INSERT INTO mg_candidates_scores 
                                            (candidate_id, score_type, score) 
                                        VALUES 
                                            (%s, 'locality.partial_ratio', %s)""", 
                                            insert_list_scores)
                logger1.debug(cur.query)
                insert_list_scores = candidates[['candidate_id', 'score2']].copy()
                insert_list_scores['candidate_id'] = insert_list_scores['candidate_id'].astype(str)
                insert_list_scores = insert_list_scores.values.tolist()
                psycopg2.extras.execute_batch(cur, """INSERT INTO mg_candidates_scores 
                                            (candidate_id, score_type, score) 
                                        VALUES 
                                            (%s, 'stateprovince', %s)""", 
                                            insert_list_scores)
                logger1.debug(cur.query)
                insert_list_scores = candidates[['candidate_id', 'score3']].copy()
                insert_list_scores['candidate_id'] = insert_list_scores['candidate_id'].astype(str)
                insert_list_scores = insert_list_scores.values.tolist()
                psycopg2.extras.execute_batch(cur, """INSERT INTO mg_candidates_scores 
                                            (candidate_id, score_type, score) 
                                        VALUES 
                                            (%s, 'locality.token_set_ratio', %s)""", 
                                            insert_list_scores)
                logger1.debug(cur.query)
        #GBIF - Genus
        query_template = "SELECT MAX(gbifid::bigint) as uid, species, locality as name, count(*) as no_records, countrycode, trim(leading ', ' from replace(municipality || ', ' || county || ', ' || stateprovince || ', ' || countrycode, ', , ', '')) as located_at, stateprovince, recordedBy, decimallatitude, decimallongitude, count(*) as no_features FROM gbif WHERE species LIKE '{species}%' AND species != '{species}' AND lower(locality) <> ANY(ARRAY['none', 'unknown', 'no locality data']) AND countrycode = '{countrycode}' AND decimallatitude IS NOT NULL GROUP BY species, countrycode, locality, municipality, county, stateprovince, recordedBy, decimallatitude, decimallongitude"
        cur.execute(query_template.format(species = sciname['species'].split(' ')[0], countrycode = country['countrycode']))
        logger1.debug(cur.query)
        allcandidates = pd.DataFrame(cur.fetchall())
        logger1.info("No. of GBIF candidates: {}".format(len(allcandidates)))
        if len(allcandidates) > 0:
            #Iterate each record
            for index, record in records_g.iterrows():
                candidates = allcandidates.copy()
                candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
                ##################
                #Execute matches
                ##################
                #locality
                candidates['score1'] = candidates.swifter.allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name']), axis = 1)
                candidates['score2'] = candidates.swifter.allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince']), axis = 1)
                candidates['score3'] = candidates.swifter.allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality'], row['name']), axis = 1)
                candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                #candidates['score'] = candidates.swifter.allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name']), axis = 1)
                #ADJUST SCORE HERE, IF NEEDED
                #
                #Batch insert
                candidates['recgroup_id'] = record['recgroup_id']
                insert_list = candidates[['candidate_id', 'recgroup_id', 'uid', 'no_features']].copy()
                insert_list['candidate_id'] = insert_list['candidate_id'].astype(str)
                insert_list = insert_list.values.tolist()
                psycopg2.extras.execute_batch(cur, """INSERT INTO mg_candidates 
                                            (candidate_id, recgroup_id, data_source, feature_id, no_features) 
                                        VALUES 
                                            (%s, %s, 'gbif.genus', %s, %s)""", 
                                            insert_list)
                logger1.debug(cur.query)
                insert_list_scores = candidates[['candidate_id', 'score1']].copy()
                insert_list_scores['candidate_id'] = insert_list_scores['candidate_id'].astype(str)
                insert_list_scores = insert_list_scores.values.tolist()
                psycopg2.extras.execute_batch(cur, """INSERT INTO mg_candidates_scores 
                                            (candidate_id, score_type, score) 
                                        VALUES 
                                            (%s, 'locality.partial_ratio', %s)""", 
                                            insert_list_scores)
                logger1.debug(cur.query)
                insert_list_scores = candidates[['candidate_id', 'score2']].copy()
                insert_list_scores['candidate_id'] = insert_list_scores['candidate_id'].astype(str)
                insert_list_scores = insert_list_scores.values.tolist()
                psycopg2.extras.execute_batch(cur, """INSERT INTO mg_candidates_scores 
                                            (candidate_id, score_type, score) 
                                        VALUES 
                                            (%s, 'stateprovince', %s)""", 
                                            insert_list_scores)
                logger1.debug(cur.query)
                insert_list_scores = candidates[['candidate_id', 'score3']].copy()
                insert_list_scores['candidate_id'] = insert_list_scores['candidate_id'].astype(str)
                insert_list_scores = insert_list_scores.values.tolist()
                psycopg2.extras.execute_batch(cur, """INSERT INTO mg_candidates_scores 
                                            (candidate_id, score_type, score) 
                                        VALUES 
                                            (%s, 'locality.token_set_ratio', %s)""", 
                                            insert_list_scores)
                logger1.debug(cur.query)
        #WDPA
        if pycountry.countries.get(alpha_2 = record['countrycode']) != None:
            query_template = """
                        WITH data AS (SELECT uid, name, gadm2 as stateprovince, 'wdpa_polygons' as source FROM wdpa_polygons WHERE parent_iso = %(iso)s AND lower(name) != 'unknown'
                        UNION 
                        SELECT uid, orig_name AS name, gadm2 as stateprovince, 'wdpa_polygons' as source FROM wdpa_polygons WHERE parent_iso = %(iso)s AND lower(name) != 'unknown'
                        UNION 
                        SELECT uid, name, gadm2 as stateprovince, 'wdpa_points' as source FROM wdpa_points WHERE parent_iso = %(iso)s AND lower(name) != 'unknown'
                        UNION 
                        SELECT uid, orig_name AS name, gadm2 as stateprovince, 'wdpa_points' as source FROM wdpa_points WHERE parent_iso = %(iso)s AND lower(name) != 'unknown')
                        SELECT uid, name, stateprovince, source FROM data GROUP BY uid, name, stateprovince, source
                            """
            cur.execute(query_template, {'iso': pycountry.countries.get(alpha_2 = record['countrycode']).alpha_3})
            logger1.debug(cur.query)
            allcandidates = pd.DataFrame(cur.fetchall())
            logger1.info("No. of WDPA candidates: {}".format(len(allcandidates)))
            if len(allcandidates) > 0:
                #Iterate each record
                for index, record in records_g.iterrows():
                    candidates = allcandidates.copy()
                    candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
                    ##################
                    #Execute matches
                    ##################
                    #locality
                    candidates['score1'] = candidates.swifter.allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name']), axis = 1)
                    candidates['score2'] = candidates.swifter.allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince']), axis = 1)
                    candidates['score3'] = candidates.swifter.allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality'], row['name']), axis = 1)
                    candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                    #ADJUST SCORE HERE, IF NEEDED
                    #
                    #Batch insert
                    candidates['recgroup_id'] = record['recgroup_id']
                    insert_list = candidates[['candidate_id', 'recgroup_id', 'source', 'uid']].copy()
                    insert_list['candidate_id'] = insert_list['candidate_id'].astype(str)
                    insert_list = insert_list.values.tolist()
                    psycopg2.extras.execute_batch(cur, """INSERT INTO mg_candidates 
                                                (candidate_id, recgroup_id, data_source, feature_id, no_features) 
                                            VALUES 
                                                (%s, %s, %s, %s, 1)""", 
                                                insert_list)
                    logger1.debug(cur.query)
                    insert_list_scores = candidates[['candidate_id', 'score1']].copy()
                    insert_list_scores['candidate_id'] = insert_list_scores['candidate_id'].astype(str)
                    insert_list_scores = insert_list_scores.values.tolist()
                    psycopg2.extras.execute_batch(cur, """INSERT INTO mg_candidates_scores 
                                                (candidate_id, score_type, score) 
                                            VALUES 
                                                (%s, 'locality.partial_ratio', %s)""", 
                                                insert_list_scores)
                    logger1.debug(cur.query)
                    insert_list_scores = candidates[['candidate_id', 'score2']].copy()
                    insert_list_scores['candidate_id'] = insert_list_scores['candidate_id'].astype(str)
                    insert_list_scores = insert_list_scores.values.tolist()
                    psycopg2.extras.execute_batch(cur, """INSERT INTO mg_candidates_scores 
                                                (candidate_id, score_type, score) 
                                            VALUES 
                                                (%s, 'stateprovince', %s)""", 
                                                insert_list_scores)
                    logger1.debug(cur.query)
                    insert_list_scores = candidates[['candidate_id', 'score3']].copy()
                    insert_list_scores['candidate_id'] = insert_list_scores['candidate_id'].astype(str)
                    insert_list_scores = insert_list_scores.values.tolist()
                    psycopg2.extras.execute_batch(cur, """INSERT INTO mg_candidates_scores 
                                                (candidate_id, score_type, score) 
                                            VALUES 
                                                (%s, 'locality.token_set_ratio', %s)""", 
                                                insert_list_scores)
                    logger1.debug(cur.query)
        #GADM
        if pycountry.countries.get(alpha_2 = record['countrycode']) != None:
            #GADM1
            query_template = "SELECT uid, name_1 as name, name_0 as stateprovince, 'gadm1' as source FROM gadm1 WHERE name_0 = %(country)s UNION SELECT uid, varname_1 as name, name_0 as stateprovince, 'gadm1' as source FROM gadm1 WHERE name_0 = %(country)s AND varname_1 IS NOT NULL"
            cur.execute(query_template, {'country': pycountry.countries.get(alpha_2 = record['countrycode']).name.replace("'", "''")})
            data1 = pd.DataFrame(cur.fetchall())
            #GADM2
            query_template = "SELECT uid, name_2 as name, name_1 || ', ' || name_0 as stateprovince, 'gadm2' as source FROM gadm2 WHERE name_0 = %(country)s UNION SELECT uid, varname_2 as name, name_1 || ', ' || name_0 as stateprovince, 'gadm2' as source FROM gadm2 WHERE name_0 = %(country)s AND varname_2 IS NOT NULL"
            cur.execute(query_template, {'country': pycountry.countries.get(alpha_2 = record['countrycode']).name.replace("'", "''")})
            data2 = pd.DataFrame(cur.fetchall())
            #GADM3
            query_template = "SELECT uid, name_3 as name, name_2 || ', ' || name_1 || ', ' || name_0 as stateprovince, 'gadm3' as source FROM gadm3 WHERE name_0 = %(country)s UNION SELECT uid, varname_3 as name, name_2 || ', ' || name_1 || ', ' || name_0 as stateprovince, 'gadm3' as source FROM gadm3 WHERE name_0 = %(country)s AND varname_3 IS NOT NULL"
            cur.execute(query_template, {'country': pycountry.countries.get(alpha_2 = record['countrycode']).name.replace("'", "''")})
            data3 = pd.DataFrame(cur.fetchall())
            #GADM4
            query_template = "SELECT uid, name_4 as name, name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0 as stateprovince, 'gadm4' as source FROM gadm4 WHERE name_0 = %(country)s UNION SELECT uid, varname_4 as name, name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0 as stateprovince, 'gadm4' as source FROM gadm4 WHERE name_0 = %(country)s AND varname_4 IS NOT NULL"
            cur.execute(query_template, {'country': pycountry.countries.get(alpha_2 = record['countrycode']).name.replace("'", "''")})
            data4 = pd.DataFrame(cur.fetchall())
            #GADM5
            query_template = "SELECT uid, name_5 as name, name_4 || ', ' || name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0 as stateprovince, 'gadm5' as source FROM gadm5 WHERE name_0 = %(country)s"
            cur.execute(query_template, {'country': pycountry.countries.get(alpha_2 = record['countrycode']).name.replace("'", "''")})
            data5 = pd.DataFrame(cur.fetchall())
            allcandidates = pd.concat([data1, data2, data3, data4, data5], ignore_index=True)
            logger1.info("No. of GADM candidates: {}".format(len(allcandidates)))
            if len(allcandidates) > 0:
                #Iterate each record
                for index, record in records_g.iterrows():
                    candidates = allcandidates.copy()
                    candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
                    ##################
                    #Execute matches
                    ##################
                    #locality
                    candidates['score1'] = candidates.swifter.allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name']), axis = 1)
                    candidates['score2'] = candidates.swifter.allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince']), axis = 1)
                    candidates['score3'] = candidates.swifter.allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality'], row['name']), axis = 1)
                    candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                    #ADJUST SCORE HERE, IF NEEDED
                    #
                    #Batch insert
                    candidates['recgroup_id'] = record['recgroup_id']
                    insert_list = candidates[['candidate_id', 'recgroup_id', 'source', 'uid']].copy()
                    insert_list['candidate_id'] = insert_list['candidate_id'].astype(str)
                    insert_list = insert_list.values.tolist()
                    psycopg2.extras.execute_batch(cur, """INSERT INTO mg_candidates 
                                                (candidate_id, recgroup_id, data_source, feature_id, no_features) 
                                            VALUES 
                                                (%s, %s, %s, %s, 1)""", 
                                                insert_list)
                    logger1.debug(cur.query)
                    insert_list_scores = candidates[['candidate_id', 'score1']].copy()
                    insert_list_scores['candidate_id'] = insert_list_scores['candidate_id'].astype(str)
                    insert_list_scores = insert_list_scores.values.tolist()
                    psycopg2.extras.execute_batch(cur, """INSERT INTO mg_candidates_scores 
                                                (candidate_id, score_type, score) 
                                            VALUES 
                                                (%s, 'locality.partial_ratio', %s)""", 
                                                insert_list_scores)
                    logger1.debug(cur.query)
                    insert_list_scores = candidates[['candidate_id', 'score2']].copy()
                    insert_list_scores['candidate_id'] = insert_list_scores['candidate_id'].astype(str)
                    insert_list_scores = insert_list_scores.values.tolist()
                    psycopg2.extras.execute_batch(cur, """INSERT INTO mg_candidates_scores 
                                                (candidate_id, score_type, score) 
                                            VALUES 
                                                (%s, 'stateprovince', %s)""", 
                                                insert_list_scores)
                    logger1.debug(cur.query)
                    insert_list_scores = candidates[['candidate_id', 'score3']].copy()
                    insert_list_scores['candidate_id'] = insert_list_scores['candidate_id'].astype(str)
                    insert_list_scores = insert_list_scores.values.tolist()
                    psycopg2.extras.execute_batch(cur, """INSERT INTO mg_candidates_scores 
                                                (candidate_id, score_type, score) 
                                            VALUES 
                                                (%s, 'locality.token_set_ratio', %s)""", 
                                                insert_list_scores)
                    logger1.debug(cur.query)
        #Geonames
        # query_template = """
        #             WITH data AS (
        #                 SELECT uid, name, gadm2 as stateprovince, 'geonames' as source FROM geonames WHERE country_code = %(countrycode)s
        #                 UNION
        #                 SELECT uid, unnest(string_to_array(alternatenames, ',')) as name, gadm2 as stateprovince, 'geonames' as source FROM geonames WHERE country_code = %(countrycode)s
        #                 )
        #             SELECT uid, name, stateprovince, source FROM data GROUP BY uid, name, stateprovince, source
        #                 """
        # cur.execute(query_template, {'countrycode': record['countrycode']})
        # allcandidates = pd.DataFrame(cur.fetchall())
        # logger1.info("No. of Geonames candidates: {}".format(len(allcandidates)))
        # if len(allcandidates) > 0:
        #     #Iterate each record
        #     for index, record in records_g.iterrows():
        #         candidates = allcandidates.copy()
        #         candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
        #         ##################
        #         #Execute matches
        #         ##################
        #         #locality
        #         candidates['score1'] = candidates.swifter.allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name']), axis = 1)
        #         candidates['score2'] = candidates.swifter.allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince']), axis = 1)
        #         candidates['score3'] = candidates.swifter.allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality'], row['name']), axis = 1)
        #         candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
        #         #ADJUST SCORE HERE, IF NEEDED
        #         #
        #         #Batch insert
        #         candidates['recgroup_id'] = record['recgroup_id']
        #         insert_list = candidates[['candidate_id', 'recgroup_id', 'source', 'uid']].copy()
        #         insert_list['candidate_id'] = insert_list['candidate_id'].astype(str)
        #         insert_list = insert_list.values.tolist()
        #         psycopg2.extras.execute_batch(cur, """INSERT INTO mg_candidates 
        #                                     (candidate_id, recgroup_id, data_source, feature_id, no_features) 
        #                                 VALUES 
        #                                     (%s, %s, %s, %s, 1)""", 
        #                                     insert_list)
        #         logger1.debug(cur.query)
        #         insert_list_scores = candidates[['candidate_id', 'score1']].copy()
        #         insert_list_scores['candidate_id'] = insert_list_scores['candidate_id'].astype(str)
        #         insert_list_scores = insert_list_scores.values.tolist()
        #         psycopg2.extras.execute_batch(cur, """INSERT INTO mg_candidates_scores 
        #                                     (candidate_id, score_type, score) 
        #                                 VALUES 
        #                                     (%s, 'locality.partial_ratio', %s)""", 
        #                                     insert_list_scores)
        #         logger1.debug(cur.query)
        #         insert_list_scores = candidates[['candidate_id', 'score2']].copy()
        #         insert_list_scores['candidate_id'] = insert_list_scores['candidate_id'].astype(str)
        #         insert_list_scores = insert_list_scores.values.tolist()
        #         psycopg2.extras.execute_batch(cur, """INSERT INTO mg_candidates_scores 
        #                                     (candidate_id, score_type, score) 
        #                                 VALUES 
        #                                     (%s, 'stateprovince', %s)""", 
        #                                     insert_list_scores)
        #         logger1.debug(cur.query)
        #         insert_list_scores = candidates[['candidate_id', 'score3']].copy()
        #         insert_list_scores['candidate_id'] = insert_list_scores['candidate_id'].astype(str)
        #         insert_list_scores = insert_list_scores.values.tolist()
        #         psycopg2.extras.execute_batch(cur, """INSERT INTO mg_candidates_scores 
        #                                     (candidate_id, score_type, score) 
        #                                 VALUES 
        #                                     (%s, 'locality.token_set_ratio', %s)""", 
        #                                     insert_list_scores)
        #         logger1.debug(cur.query)
        #GNIS
        if record['countrycode'] == 'US':
            query_template = "SELECT uid, feature_name as name, gadm2 as stateprovince, 'gnis' as source FROM gnis WHERE gadm2 ILIKE '%{}, United States'"
            cur.execute(query_template.format(record['stateprovince']))
            logger1.debug(cur.query)
            allcandidates = pd.DataFrame(cur.fetchall())
            logger1.info("No. of GNIS candidates: {}".format(len(allcandidates)))
            if len(allcandidates) > 0:
                #Iterate each record
                for index, record in records_g.iterrows():
                    candidates = allcandidates.copy()
                    candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
                    ##################
                    #Execute matches
                    ##################
                    #locality
                    candidates['score1'] = candidates.swifter.allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name']), axis = 1)
                    candidates['score2'] = candidates.swifter.allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince']), axis = 1)
                    candidates['score3'] = candidates.swifter.allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality'], row['name']), axis = 1)
                    candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                    #ADJUST SCORE HERE, IF NEEDED
                    #
                    #Batch insert
                    candidates['recgroup_id'] = record['recgroup_id']
                    insert_list = candidates[['candidate_id', 'recgroup_id', 'source', 'uid']].copy()
                    insert_list['candidate_id'] = insert_list['candidate_id'].astype(str)
                    insert_list = insert_list.values.tolist()
                    psycopg2.extras.execute_batch(cur, """INSERT INTO mg_candidates 
                                                (candidate_id, recgroup_id, data_source, feature_id, no_features) 
                                            VALUES 
                                                (%s, %s, %s, %s, 1)""", 
                                                insert_list)
                    logger1.debug(cur.query)
                    insert_list_scores = candidates[['candidate_id', 'score1']].copy()
                    insert_list_scores['candidate_id'] = insert_list_scores['candidate_id'].astype(str)
                    insert_list_scores = insert_list_scores.values.tolist()
                    psycopg2.extras.execute_batch(cur, """INSERT INTO mg_candidates_scores 
                                                (candidate_id, score_type, score) 
                                            VALUES 
                                                (%s, 'locality.partial_ratio', %s)""", 
                                                insert_list_scores)
                    logger1.debug(cur.query)
                    insert_list_scores = candidates[['candidate_id', 'score2']].copy()
                    insert_list_scores['candidate_id'] = insert_list_scores['candidate_id'].astype(str)
                    insert_list_scores = insert_list_scores.values.tolist()
                    psycopg2.extras.execute_batch(cur, """INSERT INTO mg_candidates_scores 
                                                (candidate_id, score_type, score) 
                                            VALUES 
                                                (%s, 'stateprovince', %s)""", 
                                                insert_list_scores)
                    logger1.debug(cur.query)
                    insert_list_scores = candidates[['candidate_id', 'score3']].copy()
                    insert_list_scores['candidate_id'] = insert_list_scores['candidate_id'].astype(str)
                    insert_list_scores = insert_list_scores.values.tolist()
                    psycopg2.extras.execute_batch(cur, """INSERT INTO mg_candidates_scores 
                                                (candidate_id, score_type, score) 
                                            VALUES 
                                                (%s, 'locality.token_set_ratio', %s)""", 
                                                insert_list_scores)
                    logger1.debug(cur.query)
        #GNS - Not US
        if record['countrycode'] != 'US':
            query_template = "SELECT uid, full_name_nd_ro as name, gadm2 as stateprovince, 'gns' as source FROM gns WHERE cc1 = %(countrycode)s"
            cur.execute(query_template, {'countrycode': record['countrycode']})
            logger1.debug(cur.query)
            allcandidates = pd.DataFrame(cur.fetchall())
            logger1.info("No. of GNS candidates: {}".format(len(allcandidates)))
            if len(allcandidates) > 0:
                #Iterate each record
                for index, record in records_g.iterrows():
                    candidates = allcandidates.copy()
                    candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
                    ##################
                    #Execute matches
                    ##################
                    #locality
                    candidates['score1'] = candidates.swifter.allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name']), axis = 1)
                    candidates['score2'] = candidates.swifter.allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince']), axis = 1)
                    candidates['score3'] = candidates.swifter.allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality'], row['name']), axis = 1)
                    candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                    #ADJUST SCORE HERE, IF NEEDED
                    #
                    #Batch insert
                    candidates['recgroup_id'] = record['recgroup_id']
                    insert_list = candidates[['candidate_id', 'recgroup_id', 'source', 'uid']].copy()
                    insert_list['candidate_id'] = insert_list['candidate_id'].astype(str)
                    insert_list = insert_list.values.tolist()
                    psycopg2.extras.execute_batch(cur, """INSERT INTO mg_candidates 
                                                (candidate_id, recgroup_id, data_source, feature_id, no_features) 
                                            VALUES 
                                                (%s, %s, %s, %s, 1)""", 
                                                insert_list)
                    logger1.debug(cur.query)
                    insert_list_scores = candidates[['candidate_id', 'score1']].copy()
                    insert_list_scores['candidate_id'] = insert_list_scores['candidate_id'].astype(str)
                    insert_list_scores = insert_list_scores.values.tolist()
                    psycopg2.extras.execute_batch(cur, """INSERT INTO mg_candidates_scores 
                                                (candidate_id, score_type, score) 
                                            VALUES 
                                                (%s, 'locality.partial_ratio', %s)""", 
                                                insert_list_scores)
                    logger1.debug(cur.query)
                    insert_list_scores = candidates[['candidate_id', 'score2']].copy()
                    insert_list_scores['candidate_id'] = insert_list_scores['candidate_id'].astype(str)
                    insert_list_scores = insert_list_scores.values.tolist()
                    psycopg2.extras.execute_batch(cur, """INSERT INTO mg_candidates_scores 
                                                (candidate_id, score_type, score) 
                                            VALUES 
                                                (%s, 'stateprovince', %s)""", 
                                                insert_list_scores)
                    logger1.debug(cur.query)
                    insert_list_scores = candidates[['candidate_id', 'score3']].copy()
                    insert_list_scores['candidate_id'] = insert_list_scores['candidate_id'].astype(str)
                    insert_list_scores = insert_list_scores.values.tolist()
                    psycopg2.extras.execute_batch(cur, """INSERT INTO mg_candidates_scores 
                                                (candidate_id, score_type, score) 
                                            VALUES 
                                                (%s, 'locality.token_set_ratio', %s)""", 
                                                insert_list_scores)
                    logger1.debug(cur.query)
        #Lakes
        if pycountry.countries.get(alpha_2 = record['countrycode']) != None:
            query_template = "SELECT uid, lake_name as name, gadm2 as stateprovince, 'global_lakes' as source FROM global_lakes WHERE country ILIKE '%{country}%'"
            cur.execute(query_template.format(country = pycountry.countries.get(alpha_2 = record['countrycode']).name.replace("'", "''")))
            logger1.debug(cur.query)
            allcandidates = pd.DataFrame(cur.fetchall())
            logger1.info("No. of GlobalLakes candidates: {}".format(len(allcandidates)))
            if len(allcandidates) > 0:
                #Iterate each record
                for index, record in records_g.iterrows():
                    candidates = allcandidates.copy()
                    candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
                    ##################
                    #Execute matches
                    ##################
                    #locality
                    candidates['score1'] = candidates.swifter.allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name']), axis = 1)
                    candidates['score2'] = candidates.swifter.allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince']), axis = 1)
                    candidates['score3'] = candidates.swifter.allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality'], row['name']), axis = 1)
                    candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                    #ADJUST SCORE HERE, IF NEEDED
                    #
                    #Batch insert
                    candidates['recgroup_id'] = record['recgroup_id']
                    insert_list = candidates[['candidate_id', 'recgroup_id', 'source', 'uid']].copy()
                    insert_list['candidate_id'] = insert_list['candidate_id'].astype(str)
                    insert_list = insert_list.values.tolist()
                    psycopg2.extras.execute_batch(cur, """INSERT INTO mg_candidates 
                                                (candidate_id, recgroup_id, data_source, feature_id, no_features) 
                                            VALUES 
                                                (%s, %s, %s, %s, 1)""", 
                                                insert_list)
                    logger1.debug(cur.query)
                    insert_list_scores = candidates[['candidate_id', 'score1']].copy()
                    insert_list_scores['candidate_id'] = insert_list_scores['candidate_id'].astype(str)
                    insert_list_scores = insert_list_scores.values.tolist()
                    psycopg2.extras.execute_batch(cur, """INSERT INTO mg_candidates_scores 
                                                (candidate_id, score_type, score) 
                                            VALUES 
                                                (%s, 'locality.partial_ratio', %s)""", 
                                                insert_list_scores)
                    logger1.debug(cur.query)
                    insert_list_scores = candidates[['candidate_id', 'score2']].copy()
                    insert_list_scores['candidate_id'] = insert_list_scores['candidate_id'].astype(str)
                    insert_list_scores = insert_list_scores.values.tolist()
                    psycopg2.extras.execute_batch(cur, """INSERT INTO mg_candidates_scores 
                                                (candidate_id, score_type, score) 
                                            VALUES 
                                                (%s, 'stateprovince', %s)""", 
                                                insert_list_scores)
                    logger1.debug(cur.query)
                    insert_list_scores = candidates[['candidate_id', 'score3']].copy()
                    insert_list_scores['candidate_id'] = insert_list_scores['candidate_id'].astype(str)
                    insert_list_scores = insert_list_scores.values.tolist()
                    psycopg2.extras.execute_batch(cur, """INSERT INTO mg_candidates_scores 
                                                (candidate_id, score_type, score) 
                                            VALUES 
                                                (%s, 'locality.token_set_ratio', %s)""", 
                                                insert_list_scores)
                    logger1.debug(cur.query)
    #Cleanup species
    cur.execute("DELETE FROM mg_recordgroups WHERE species = %(species)s AND recgroup_id NOT IN (SELECT recgroup_id FROM mg_candidates GROUP BY recgroup_id)", {'species': sciname['species']})
    logger1.debug(cur.query)
    #Spatial Match
    cur.execute("select candidate_id, data_source, feature_id, %(species)s as species from mg_candidates mc where recgroup_id in (select recgroup_id from mg_recordgroups where species = %(species)s) GROUP BY candidate_id, data_source, feature_id", {'species': sciname['species']})
    logger1.debug(cur.query)
    allcandidates = pd.DataFrame(cur.fetchall())
    if len(allcandidates) > 0:
        logger1.info("Matching spatial location for {} records of {}".format(len(allcandidates), sciname['species']))
        #Iterate each record
        allcandidates.swifter.allow_dask_on_strings(enable=True).apply(lambda row : check_spatial(row['data_source'], sciname['species'], row['candidate_id'], row['feature_id'], cur, logger1), axis = 1)
        #check_spatial(data_source, species, candidate_id, feature_id, cur, logger1)
        # for index, record in allcandidates.iterrows():
        #     if record['data_source'] == 'gbif.species' or record['data_source'] == 'gbif.genus':
        #         continue
        #     cur.execute("""
        #             WITH data AS (
        #                     SELECT 
        #                         ST_Union(the_geom) as the_geom
        #                     FROM 
        #                         iucn
        #                     WHERE
        #                         sciname = '{species}'

        #                     UNION ALL

        #                     SELECT 
        #                         ST_ConvexHull(ST_Collect(the_geom)) as the_geom
        #                     FROM 
        #                         gbif
        #                     WHERE
        #                         species = '{species}'
        #             ),
        #             range AS (
        #                 SELECT 
        #                     ST_Transform(ST_Union(the_geom), 3857) as the_geom_webmercator
        #                 FROM
        #                     data
        #                 ),
        #             calc AS (
        #                 SELECT 
        #                     '{candidate_id}' as candidate_id, 
        #                     'locality.spatial' as score_type, 
        #                     ST_Distance(l.the_geom_webmercator, r.the_geom_webmercator) AS geom_dist 
        #                 FROM 
        #                     {data_source} l, range r
        #                 WHERE l.uid = '{feature_id}'::uuid
        #             )
        #             INSERT INTO mg_candidates_scores 
        #             (candidate_id, score_type, score) 
        #             (
        #                 SELECT 
        #                     '{candidate_id}' as candidate_id, 
        #                     'locality.spatial' as score_type, 
        #                     CASE 
        #                         WHEN geom_dist = 0 THEN 100 
        #                         WHEN geom_dist > 0 AND geom_dist < 10000 THEN 95 
        #                         WHEN geom_dist > 0 AND geom_dist <= 10000 THEN 95 
        #                         WHEN geom_dist > 10000 AND geom_dist <= 50000 THEN 85 
        #                         WHEN geom_dist > 50000 AND geom_dist <= 100000 THEN 75
        #                         WHEN geom_dist > 100000 AND geom_dist <= 100000 THEN 65
        #                         ELSE 60
        #                         END AS score 
        #                 FROM 
        #                     calc
        #             )""".format(candidate_id = record['candidate_id'], data_source = record['data_source'], species = sciname['species'], feature_id = record['feature_id']))
        #     logger1.debug(cur.query)




#Compress logs
script_dir = os.getcwd()
os.chdir('{}/logs'.format(script_dir))
for file in glob.glob('*.log'):
    subprocess.run(["zip", "{}.zip".format(file), file])
    os.remove(file)
os.chdir(script_dir)

sys.exit(0)
