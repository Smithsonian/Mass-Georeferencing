#!/usr/bin/env python3
#
# Mass Georeferencing script
# Version 0.1
#
# 2020-02-27
# 
# Digitization Program Office, 
# Office of the Chief Information Officer,
# Smithsonian Institution
# https://dpo.si.edu
#
#Import modules
import os, logging, sys, locale, uuid, glob, subprocess, pycountry, swifter, re
import pandas as pd
from time import localtime, strftime
from fuzzywuzzy import fuzz
from pyfiglet import Figlet
import psycopg2, psycopg2.extras
from psycopg2.extras import execute_batch


#Get settings
import settings



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



import queries
from functions import *



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





#Connect to the database
try:
    logger1.info("Connecting to the database.")
    conn = psycopg2.connect(host = settings.pg_host, database = settings.pg_db, user = settings.pg_user, connect_timeout = 60)
except:
    logger1.error("Could not connect to server.")
    sys.exit(1)
conn.autocommit = True
cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
#Get collection to run from settings
cur.execute(queries.get_collex, (settings.collex_id,))
logger1.debug(cur.query)
collex = cur.fetchone()
if collex == None:
    logger1.error("Collection not found")
    sys.exit(1)
#Select species
cur.execute(collex['collex_definition'])
logger1.debug(cur.query)
scinames = cur.fetchall()
if len(scinames) == 0:
    logger1.error("Query did not find species")
    sys.exit(1)
#Delete previous records matches
logger1.info("Deleting old matches...")
for sciname in scinames:
    #logger1.info("Deleting old matches for {}".format(sciname['species']))
    cur.execute(queries.delete_spp_records, (sciname['species'],))
    logger1.debug(cur.query)    




#Loop the species
for sciname in scinames:
    logger1.info("sciname: {}".format(sciname['species']))
    #Get countrycodes for the species
    cur.execute(queries.get_spp_countries, (sciname['species'],))
    logger1.debug(cur.query)
    countries = cur.fetchall()
    #Records with countrycode
    for country in countries:
        #Get records for the country
        cur.execute(queries.get_records_for_country, {'species': sciname['species'], 'countrycode': country['countrycode']})
        logger1.debug(cur.query)
        records_g = pd.DataFrame(cur.fetchall())
        records_g['recgroup_id'] = [uuid.uuid4() for _ in range(len(records_g.index))]
        records_g['recgroup_id'] = records_g['recgroup_id'].astype(str)
        logger1.info("Found {} records of {} in {}".format(len(records_g), sciname['species'], country['countrycode']))
        records_g['collex_id'] = settings.collex_id
        records_g_insert = records_g[['recgroup_id', 'collex_id', 'locality', 'stateprovince', 'countrycode', 'recordedby', 'kingdom', 'phylum', 'class', '_order', 'family', 'genus', 'species', 'no_records']].copy()
        #print(records_g_insert)
        records_g_insert2 = records_g_insert.values.tolist()
        psycopg2.extras.execute_batch(cur, queries.insert_mg_recordgroups, records_g_insert2)
        #Insert link to records by group
        for index, record in records_g.iterrows():
            cur.execute(queries.insert_mg_records, {'species': sciname['species'], 'countrycode': country['countrycode'], 'locality': record['locality'], 'stateprovince': record['stateprovince'], 'kingdom': record['kingdom'], 'phylum': record['phylum'], 'class': record['class'], '_order': record['_order'], 'family': record['family'], 'genus': record['genus'], 'recgroup_id': record['recgroup_id']})
            logger1.debug(cur.query)
        #GBIF - species
        if 'gbif.species' in settings.layers:
            cur.execute(queries.gbif_species_country, {'species': sciname['species'], 'countrycode': country['countrycode']})
            logger1.debug(cur.query)
            allcandidates = pd.DataFrame(cur.fetchall())
            logger1.info("No. of GBIF candidates for species: {}".format(len(allcandidates)))
            if len(allcandidates) > 0:
                #Iterate each record
                for index, record in records_g.iterrows():
                    candidates = allcandidates.copy()
                    candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
                    ##################
                    #Execute matches
                    ##################
                    #locality.partial_ratio
                    candidates['score1'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name']), axis = 1)
                    candidates['score1_type'] = "locality.partial_ratio"
                    #stateprovince
                    candidates['score2'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince']), axis = 1)
                    candidates['score2_type'] = "stateprovince"
                    #locality.token_set_ratio
                    candidates['score3'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality'], row['name']), axis = 1)
                    candidates['score3_type'] = "locality.token_set_ratio"
                    #Remove candidates with average score less than settings.min_score
                    candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                    candidates['recgroup_id'] = record['recgroup_id']
                    candidates['data_source'] = 'gbif.species'
                    #Insert candidates and each score
                    candidates['candidate_id'] = candidates['candidate_id'].astype(str)
                    insert_candidates(candidates[['candidate_id', 'recgroup_id', 'data_source', 'uid', 'no_features']].copy(), cur, logger1)
                    insert_scores(candidates[['candidate_id', 'score1_type', 'score1']].copy(), cur, logger1)
                    insert_scores(candidates[['candidate_id', 'score2_type', 'score2']].copy(), cur, logger1)
                    insert_scores(candidates[['candidate_id', 'score3_type', 'score3']].copy(), cur, logger1)
        #GBIF - Genus
        if 'gbif.genus' in settings.layers:
            cur.execute(queries.gbif_genus_country.format(genus = sciname['species'].split(' ')[0], species = sciname['species'], countrycode = country['countrycode']))
            logger1.debug(cur.query)
            allcandidates = pd.DataFrame(cur.fetchall())
            logger1.info("No. of GBIF candidates for genus: {}".format(len(allcandidates)))
            if len(allcandidates) > 0:
                #Iterate each record
                for index, record in records_g.iterrows():
                    candidates = allcandidates.copy()
                    candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
                    ##################
                    #Execute matches
                    ##################
                    #locality.partial_ratio
                    candidates['score1'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name']), axis = 1)
                    candidates['score1_type'] = "locality.partial_ratio"
                    #stateprovince
                    candidates['score2'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince']), axis = 1)
                    candidates['score2_type'] = "stateprovince"
                    #locality.token_set_ratio
                    candidates['score3'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality'], row['name']), axis = 1)
                    candidates['score3_type'] = "locality.token_set_ratio"
                    #Remove candidates with average score less than settings.min_score
                    candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                    candidates['recgroup_id'] = record['recgroup_id']
                    candidates['data_source'] = 'gbif.genus'
                    #Insert candidates and each score
                    candidates['candidate_id'] = candidates['candidate_id'].astype(str)
                    insert_candidates(candidates[['candidate_id', 'recgroup_id', 'data_source', 'uid', 'no_features']].copy(), cur, logger1)
                    insert_scores(candidates[['candidate_id', 'score1_type', 'score1']].copy(), cur, logger1)
                    insert_scores(candidates[['candidate_id', 'score2_type', 'score2']].copy(), cur, logger1)
                    insert_scores(candidates[['candidate_id', 'score3_type', 'score3']].copy(), cur, logger1)
        #WDPA
        if 'wdpa' in settings.layers:
            if pycountry.countries.get(alpha_2 = record['countrycode']) != None:
                cur.execute(re.sub(' +', ' ', queries.wdpa_iso.replace('\n', '')).format(iso = pycountry.countries.get(alpha_2 = record['countrycode']).alpha_3))
                logger1.debug(cur.query)
                allcandidates = pd.DataFrame(cur.fetchall())
                logger1.info("No. of WDPA candidates: {}".format(len(allcandidates)))
                if len(allcandidates) > 0:
                    #Iterate each record
                    for index, record in records_g.iterrows():
                        candidates = allcandidates.copy()
                        candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
                        candidates['candidate_id'] = candidates['candidate_id'].astype(str)
                        ##################
                        #Execute matches
                        ##################
                        #locality.partial_ratio
                        candidates['score1'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name']), axis = 1)
                        candidates['score1_type'] = "locality.partial_ratio"
                        #stateprovince
                        candidates['score2'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince']), axis = 1)
                        candidates['score2_type'] = "stateprovince"
                        #locality.token_set_ratio
                        candidates['score3'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality'], row['name']), axis = 1)
                        candidates['score3_type'] = "locality.token_set_ratio"
                        #Remove candidates with average score less than settings.min_score
                        candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                        candidates['recgroup_id'] = record['recgroup_id']
                        candidates['no_features'] = 1
                        #Insert candidates and each score
                        candidates['candidate_id'] = candidates['candidate_id'].astype(str)
                        insert_candidates(candidates[['candidate_id', 'recgroup_id', 'data_source', 'uid', 'no_features']].copy(), cur, logger1)
                        insert_scores(candidates[['candidate_id', 'score1_type', 'score1']].copy(), cur, logger1)
                        insert_scores(candidates[['candidate_id', 'score2_type', 'score2']].copy(), cur, logger1)
                        insert_scores(candidates[['candidate_id', 'score3_type', 'score3']].copy(), cur, logger1)
        #GADM
        if 'gadm' in settings.layers:
            if pycountry.countries.get(alpha_2 = record['countrycode']) != None:
                #GADM1
                cur.execute(re.sub(' +', ' ', queries.gadm_country.replace('\n', '')), {'country': pycountry.countries.get(alpha_2 = record['countrycode']).name.replace("'", "''")})
                allcandidates = pd.DataFrame(cur.fetchall())
                logger1.info("No. of GADM candidates: {}".format(len(allcandidates)))
                if len(allcandidates) > 0:
                    #Iterate each record
                    for index, record in records_g.iterrows():
                        candidates = allcandidates.copy()
                        candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
                        candidates['candidate_id'] = candidates['candidate_id'].astype(str)
                        ##################
                        #Execute matches
                        ##################
                        #locality.partial_ratio
                        candidates['score1'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name']), axis = 1)
                        candidates['score1_type'] = "locality.partial_ratio"
                        #stateprovince
                        candidates['score2'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince']), axis = 1)
                        candidates['score2_type'] = "stateprovince"
                        #locality.token_set_ratio
                        candidates['score3'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality'], row['name']), axis = 1)
                        candidates['score3_type'] = "locality.token_set_ratio"
                        #Remove candidates with average score less than settings.min_score
                        candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                        candidates['recgroup_id'] = record['recgroup_id']
                        candidates['no_features'] = 1
                        #Insert candidates and each score
                        candidates['candidate_id'] = candidates['candidate_id'].astype(str)
                        insert_candidates(candidates[['candidate_id', 'recgroup_id', 'data_source', 'uid', 'no_features']].copy(), cur, logger1)
                        insert_scores(candidates[['candidate_id', 'score1_type', 'score1']].copy(), cur, logger1)
                        insert_scores(candidates[['candidate_id', 'score2_type', 'score2']].copy(), cur, logger1)
                        insert_scores(candidates[['candidate_id', 'score3_type', 'score3']].copy(), cur, logger1)
        #GNIS
        if 'gnis' in settings.layers:
            if record['countrycode'] == 'US':
                cur.execute(re.sub(' +', ' ', queries.gnis_query.replace('\n', '')).format(record['stateprovince']))
                logger1.debug(cur.query)
                allcandidates = pd.DataFrame(cur.fetchall())
                logger1.info("No. of GNIS candidates: {}".format(len(allcandidates)))
                if len(allcandidates) > 0:
                    #Iterate each record
                    for index, record in records_g.iterrows():
                        candidates = allcandidates.copy()
                        candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
                        candidates['candidate_id'] = candidates['candidate_id'].astype(str)
                        ##################
                        #Execute matches
                        ##################
                        #locality.partial_ratio
                        candidates['score1'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name']), axis = 1)
                        candidates['score1_type'] = "locality.partial_ratio"
                        #stateprovince
                        candidates['score2'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince']), axis = 1)
                        candidates['score2_type'] = "stateprovince"
                        #locality.token_set_ratio
                        candidates['score3'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality'], row['name']), axis = 1)
                        candidates['score3_type'] = "locality.token_set_ratio"
                        #Remove candidates with average score less than settings.min_score
                        candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                        candidates['recgroup_id'] = record['recgroup_id']
                        candidates['no_features'] = 1
                        #Insert candidates and each score
                        candidates['candidate_id'] = candidates['candidate_id'].astype(str)
                        insert_candidates(candidates[['candidate_id', 'recgroup_id', 'data_source', 'uid', 'no_features']].copy(), cur, logger1)
                        insert_scores(candidates[['candidate_id', 'score1_type', 'score1']].copy(), cur, logger1)
                        insert_scores(candidates[['candidate_id', 'score2_type', 'score2']].copy(), cur, logger1)
                        insert_scores(candidates[['candidate_id', 'score3_type', 'score3']].copy(), cur, logger1)
        #GNS - Not US
        if 'gns' in settings.layers:
            if record['countrycode'] != 'US':
                cur.execute(re.sub(' +', ' ', queries.gns_query.replace('\n', '')), {'countrycode': record['countrycode']})
                logger1.debug(cur.query)
                allcandidates = pd.DataFrame(cur.fetchall())
                logger1.info("No. of GNS candidates: {}".format(len(allcandidates)))
                if len(allcandidates) > 0:
                    #Iterate each record
                    for index, record in records_g.iterrows():
                        candidates = allcandidates.copy()
                        candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
                        candidates['candidate_id'] = candidates['candidate_id'].astype(str)
                        ##################
                        #Execute matches
                        ##################
                        #locality.partial_ratio
                        candidates['score1'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name']), axis = 1)
                        candidates['score1_type'] = "locality.partial_ratio"
                        #stateprovince
                        candidates['score2'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince']), axis = 1)
                        candidates['score2_type'] = "stateprovince"
                        #locality.token_set_ratio
                        candidates['score3'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality'], row['name']), axis = 1)
                        candidates['score3_type'] = "locality.token_set_ratio"
                        #Remove candidates with average score less than settings.min_score
                        candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                        candidates['recgroup_id'] = record['recgroup_id']
                        candidates['no_features'] = 1
                        #Insert candidates and each score
                        candidates['candidate_id'] = candidates['candidate_id'].astype(str)
                        insert_candidates(candidates[['candidate_id', 'recgroup_id', 'data_source', 'uid', 'no_features']].copy(), cur, logger1)
                        insert_scores(candidates[['candidate_id', 'score1_type', 'score1']].copy(), cur, logger1)
                        insert_scores(candidates[['candidate_id', 'score2_type', 'score2']].copy(), cur, logger1)
                        insert_scores(candidates[['candidate_id', 'score3_type', 'score3']].copy(), cur, logger1)
        #Lakes
        if 'global_lakes' in settings.layers:
            if pycountry.countries.get(alpha_2 = record['countrycode']) != None:
                cur.execute(re.sub(' +', ' ', queries.global_lakes.replace('\n', '')).format(country = pycountry.countries.get(alpha_2 = record['countrycode']).name.replace("'", "''")))
                logger1.debug(cur.query)
                allcandidates = pd.DataFrame(cur.fetchall())
                logger1.info("No. of GlobalLakes candidates: {}".format(len(allcandidates)))
                if len(allcandidates) > 0:
                    #Iterate each record
                    for index, record in records_g.iterrows():
                        candidates = allcandidates.copy()
                        candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
                        candidates['candidate_id'] = candidates['candidate_id'].astype(str)
                        ##################
                        #Execute matches
                        ##################
                        #locality.partial_ratio
                        candidates['score1'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name']), axis = 1)
                        candidates['score1_type'] = "locality.partial_ratio"
                        #stateprovince
                        candidates['score2'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince']), axis = 1)
                        candidates['score2_type'] = "stateprovince"
                        #locality.token_set_ratio
                        candidates['score3'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality'], row['name']), axis = 1)
                        candidates['score3_type'] = "locality.token_set_ratio"
                        #Remove candidates with average score less than settings.min_score
                        candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                        candidates['recgroup_id'] = record['recgroup_id']
                        candidates['no_features'] = 1
                        #Insert candidates and each score
                        candidates['candidate_id'] = candidates['candidate_id'].astype(str)
                        insert_candidates(candidates[['candidate_id', 'recgroup_id', 'data_source', 'uid', 'no_features']].copy(), cur, logger1)
                        insert_scores(candidates[['candidate_id', 'score1_type', 'score1']].copy(), cur, logger1)
                        insert_scores(candidates[['candidate_id', 'score2_type', 'score2']].copy(), cur, logger1)
                        insert_scores(candidates[['candidate_id', 'score3_type', 'score3']].copy(), cur, logger1)
        #Geonames
        if 'geonames' in settings.layers:
            cur.execute(re.sub(' +', ' ', queries.geonames.replace('\n', '')), {'countrycode': record['countrycode']})
            allcandidates = pd.DataFrame(cur.fetchall())
            logger1.info("No. of Geonames candidates: {}".format(len(allcandidates)))
            if len(allcandidates) > 0:
                #Iterate each record
                    for index, record in records_g.iterrows():
                        candidates = allcandidates.copy()
                        candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
                        candidates['candidate_id'] = candidates['candidate_id'].astype(str)
                        ##################
                        #Execute matches
                        ##################
                        #locality.partial_ratio
                        candidates['score1'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name']), axis = 1)
                        candidates['score1_type'] = "locality.partial_ratio"
                        #stateprovince
                        candidates['score2'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince']), axis = 1)
                        candidates['score2_type'] = "stateprovince"
                        #locality.token_set_ratio
                        candidates['score3'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality'], row['name']), axis = 1)
                        candidates['score3_type'] = "locality.token_set_ratio"
                        #Remove candidates with average score less than settings.min_score
                        candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                        candidates['recgroup_id'] = record['recgroup_id']
                        candidates['no_features'] = 1
                        #Insert candidates and each score
                        candidates['candidate_id'] = candidates['candidate_id'].astype(str)
                        insert_candidates(candidates[['candidate_id', 'recgroup_id', 'data_source', 'uid', 'no_features']].copy(), cur, logger1)
                        insert_scores(candidates[['candidate_id', 'score1_type', 'score1']].copy(), cur, logger1)
                        insert_scores(candidates[['candidate_id', 'score2_type', 'score2']].copy(), cur, logger1)
                        insert_scores(candidates[['candidate_id', 'score3_type', 'score3']].copy(), cur, logger1)
    #Calculate candidates by recordgroup
    cur.execute(queries.recordgroups_stats, {'species': sciname['species']})
    logger1.debug(cur.query)
    #Spatial Match
    if settings.spatial_match == True and settings.backend == "database":
        cur.execute(queries.get_species_candidates, {'species': sciname['species']})
        logger1.debug(cur.query)
        allcandidates = pd.DataFrame(cur.fetchall())
        if len(allcandidates) > 0:
            logger1.info("Matching spatial location for {} records of {}".format(len(allcandidates), sciname['species']))
            #Check each candidate
            allcandidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : check_spatial(row['data_source'], sciname['species'], row['candidate_id'], row['feature_id'], cur, logger1), axis = 1)



#Compress logs
script_dir = os.getcwd()
os.chdir('{}/logs'.format(script_dir))
for file in glob.glob('*.log'):
    subprocess.run(["zip", "{}.zip".format(file), file])
    os.remove(file)
os.chdir(script_dir)


sys.exit(0)
