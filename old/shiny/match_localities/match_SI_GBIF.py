#!/usr/bin/env python3
#
# Match SI GBIF records without coordinates to other GBIF records for the species/genus
#
import psycopg2, os, logging, sys, locale, psycopg2.extras
import pandas as pd
from time import localtime, strftime
from fuzzywuzzy import fuzz
import pycountry


#Import settings
import settings

#Set locale for number format
locale.setlocale(locale.LC_ALL, 'en_US.UTF-8')



#Get current time
current_time = strftime("%Y%m%d_%H%M%S", localtime())

# Set Logging
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
logger1 = logging.getLogger("si_georef")


#search_fuzzy(record['locality'], record['stateprovince'], candidates, method = 'set', threshold = 80)
def search_fuzzy(locality, stateprovince, data, filter_stateprovince = True, method = 'partial', threshold = 80):
    """Search localities in the databases for matches using fuzzywuzzy."""
    try:
        int(threshold)
    except:
        print('invalid threshold value')
        sys.exit(1)
    #Check results
    if method == 'partial':
        data['score1'] = data.apply(lambda row : fuzz.partial_ratio(locality, row['name']), axis = 1)
        if filter_stateprovince == True:
            data['score2'] = data.apply(lambda row : fuzz.partial_ratio(stateprovince, row['stateprovince']), axis = 1)
            data['score'] = (data['score1'] + data['score2'])/2
            results = data.drop(columns = ['score1', 'score2'])
        else:
            data['score'] = data['score1']
            results = data.drop(columns = ['score1'])            
    elif method == 'set':
        data['score1'] = data.apply(lambda row : fuzz.token_set_ratio(locality, row['name']), axis = 1)
        if filter_stateprovince == True:
            data['score2'] = data.apply(lambda row : fuzz.token_set_ratio(stateprovince, row['stateprovince']), axis = 1)
            data['score'] = (data['score1'] + data['score2'])/2
            results = data.drop(columns = ['score1', 'score2'])
        else:
            data['score'] = data['score1']
            results = data.drop(columns = ['score1'])            
    results = results[results.score > threshold]
    #print(results)
    return results



#Connect to the dpogis database
try:
    logger1.info("Connecting to the database.")
    conn = psycopg2.connect(host = settings.pg_host, database = settings.pg_db, user = settings.pg_user, connect_timeout = 60)
except:
    print(" ERROR: Could not connect to server.")
    sys.exit(1)

conn.autocommit = True
cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)


if len(sys.argv) > 1:
    arg = sys.argv[1]
    if arg == "plants":
        sel_species = "SELECT species, kingdom, phylum, class, _order, family, genus FROM gbif_si WHERE species != '' AND decimallatitude is null and decimallongitude is null AND locality != '' AND phylum = 'Tracheophyta' GROUP BY species, kingdom, phylum, class, _order, family, genus"
        #sel_species = "SELECT DISTINCT species FROM gbif_si WHERE species != '' AND ((decimallatitude is null and decimallongitude is null) OR (georeferenceprotocol LIKE '%%unknown%%') OR (locality != '')) AND phylum = 'Tracheophyta'"
    elif arg == "birds":
        sel_species = "SELECT species, kingdom, phylum, class, _order, family, genus FROM gbif_si WHERE species != '' AND decimallatitude is null and decimallongitude is null AND locality != '' AND class = 'Aves' GROUP BY species, kingdom, phylum, class, _order, family, genus"
    elif arg == "mammals":
        sel_species = "SELECT species, kingdom, phylum, class, _order, family, genus FROM gbif_si WHERE species != '' AND decimallatitude is null and decimallongitude is null AND locality != '' AND class = 'Mammalia' GROUP BY species, kingdom, phylum, class, _order, family, genus"
    elif arg == "reptiles":
        sel_species = "SELECT species, kingdom, phylum, class, _order, family, genus FROM gbif_si WHERE species != '' AND decimallatitude is null and decimallongitude is null AND  locality != '' AND class = 'Reptilia' GROUP BY species, kingdom, phylum, class, _order, family, genus"
    elif arg == "amphibians":
        sel_species = "SELECT species, kingdom, phylum, class, _order, family, genus FROM gbif_si WHERE species != '' AND decimallatitude is null and decimallongitude is null AND locality != '' AND class = 'Amphibia' GROUP BY species, kingdom, phylum, class, _order, family, genus"
    elif arg == "bivalves":
        sel_species = "SELECT species, kingdom, phylum, class, _order, family, genus FROM gbif_si WHERE species != '' AND decimallatitude is null and decimallongitude is null AND locality != '' AND basisofrecord = 'FOSSIL_SPECIMEN' AND class = 'Bivalvia' GROUP BY species, kingdom, phylum, class, _order, family, genus"
    elif arg == "gastropods":
        sel_species = "SELECT species, kingdom, phylum, class, _order, family, genus FROM gbif_si WHERE species != '' AND decimallatitude is null and decimallongitude is null AND locality != '' AND basisofrecord = 'FOSSIL_SPECIMEN' AND class = 'Gastropoda' GROUP BY species, kingdom, phylum, class, _order, family, genus"
    elif arg == "crabs":
        sel_species = "SELECT species, kingdom, phylum, class, _order, family, genus FROM gbif_si WHERE species != '' AND decimallatitude is null and decimallongitude is null AND locality != '' AND basisofrecord = 'FOSSIL_SPECIMEN' AND class = 'Malacostraca' GROUP BY species, kingdom, phylum, class, _order, family, genus"
    elif arg == "echinoids":
        sel_species = "SELECT species, kingdom, phylum, class, _order, family, genus FROM gbif_si WHERE species != '' AND decimallatitude is null and decimallongitude is null AND locality != '' AND basisofrecord = 'FOSSIL_SPECIMEN' AND class = 'Echinoidea' GROUP BY species, kingdom, phylum, class, _order, family, genus"
    elif arg == "iz":
        sel_species = "SELECT species, kingdom, phylum, class, _order, family, genus FROM gbif_si WHERE species != '' AND decimallatitude is null and decimallongitude is null AND locality != '' AND family = 'Unionidae' GROUP BY species, kingdom, phylum, class, _order, family, genus"
    else:
        print("Invalid argument")
        sys.exit(1)



#Select species
cur.execute(sel_species)
logger1.debug(cur.query)
scinames = cur.fetchall()



for sciname in scinames:
    cur.execute("DELETE FROM gbif_si_matches WHERE species = %s", (sciname['species'],))
    logger1.debug(cur.query)
    cur.execute("DELETE FROM gbif_si_summary WHERE species = %(species)s AND kingdom = %(kingdom)s AND phylum = %(phylum)s AND class = %(class)s AND _order = %(_order)s AND family = %(family)s AND genus = %(genus)s", {'species': sciname['species'], 'kingdom': sciname['kingdom'], 'phylum': sciname['phylum'], 'class': sciname['class'], '_order': sciname['_order'], 'family': sciname['family'], 'genus': sciname['genus']})
    logger1.debug(cur.query)



#search_fuzzy(locality, scientificname, countrycode, db, cur, rank = 'species', method = 'partial', threshold = 80):
#Loop the species
for sciname in scinames:
    logger1.info("sciname: {}".format(sciname['species']))
    
    #Get countries
    cur.execute("SELECT countrycode FROM gbif_si WHERE species = %s AND decimallatitude is null and decimallongitude is null AND lower(locality) != 'unknown' AND locality != '' GROUP BY countrycode", (sciname['species'],))
    logger1.debug(cur.query)
    countries = cur.fetchall()
    for country in countries:
        #Get records for the country
        cur.execute("SELECT MAX(gbifid::bigint)::text as gbifid, countrycode, stateprovince, locality, kingdom, phylum, class, _order, family, genus FROM gbif_si WHERE species = %(species)s AND countrycode = %(countrycode)s AND decimallatitude is null and decimallongitude is null AND lower(locality) != 'unknown' AND locality != '' GROUP BY countrycode, stateprovince, locality, kingdom, phylum, class, _order, family, genus", {'species': sciname['species'], 'countrycode': country['countrycode']})
        logger1.debug(cur.query)
        records = pd.DataFrame(cur.fetchall())
        ################
        #Get candidates
        ################
        #GBIF - species
        logger1.info("GBIF: {}".format(country['countrycode']))
        query_template = "SELECT MAX(gbifid::bigint)::text as uid, locality as name, count(*) as no_records, countrycode, trim(leading ', ' from replace(municipality || ', ' || county || ', ' || stateprovince || ', ' || countrycode, ', , ', '')) as located_at, stateprovince, recordedBy FROM gbif WHERE {rank} = '{scientificname}' AND lower(locality) != 'unknown' AND countrycode = '{countrycode}' GROUP BY countrycode, locality, municipality, county, stateprovince, recordedBy"
        cur.execute(query_template.format(rank = 'species', scientificname = sciname['species'], countrycode = country['countrycode']))
        logger1.debug(cur.query)
        candidates = pd.DataFrame(cur.fetchall())
        logger1.info("No. of GBIF candidates: {}".format(len(candidates)))
        if len(candidates) > 0:
            #Iterate each record
            for index, record in records.iterrows():
                logger1.info("record gbifid: {}".format(record['gbifid']))
                logger1.info("locality: {}, {}, {}".format(record['locality'], record['stateprovince'], record['countrycode']))
                if record['stateprovince'] == '':
                    data = search_fuzzy(record['locality'], record['stateprovince'], candidates, filter_stateprovince = False, method = 'set', threshold = 80)
                else:
                    data = search_fuzzy(record['locality'], record['stateprovince'], candidates, filter_stateprovince = True, method = 'set', threshold = 80)
                logger1.info("No. of possible matches: {}".format(len(data)))
                if len(data) > 0:
                    for index, row in data.iterrows():
                        cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, no_records, species, match, score, located_at, timestamp) VALUES 
                                                                (%(gbifid)s, %(source)s, %(no_records)s, %(species)s, %(match)s, %(score)s, %(located_at)s, NOW())""", {'gbifid': record['gbifid'], 'source': 'gbif.species', 'no_records': str(row['no_records']), 'species': sciname['species'], 'match': str(row['uid']), 'score': row['score'], 'located_at': row['located_at']})
                        logger1.debug(cur.query)
        #GBIF - genus
        logger1.info("GBIF genus: {}".format(country['countrycode']))
        query_template = "SELECT MAX(gbifid::bigint)::text as uid, locality as name, count(*) as no_records, countrycode, trim(leading ', ' from replace(municipality || ', ' || county || ', ' || stateprovince || ', ' || countrycode, ', , ', '')) as located_at, stateprovince, recordedBy FROM gbif WHERE {rank} = '{genus}' AND species != '{scientificname}' AND lower(locality) != 'unknown' AND countrycode = '{countrycode}' GROUP BY countrycode, locality, municipality, county, stateprovince, recordedBy"
        cur.execute(query_template.format(rank = 'genus', genus = sciname['genus'], scientificname = sciname['species'], countrycode = country['countrycode']))
        logger1.debug(cur.query)
        candidates = pd.DataFrame(cur.fetchall())
        logger1.info("No. of GBIF candidates: {}".format(len(candidates)))
        if len(candidates) > 0:
            #Iterate each record
            for index, record in records.iterrows():
                logger1.info("record gbifid: {}".format(record['gbifid']))
                logger1.info("locality: {}, {}, {}".format(record['locality'], record['stateprovince'], record['countrycode']))
                if record['stateprovince'] == '':
                    data = search_fuzzy(record['locality'], record['stateprovince'], candidates, filter_stateprovince = False, method = 'set', threshold = 80)
                else:
                    data = search_fuzzy(record['locality'], record['stateprovince'], candidates, filter_stateprovince = True, method = 'set', threshold = 80)
                logger1.info("No. of possible matches: {}".format(len(data)))
                if len(data) > 0:
                    for index, row in data.iterrows():
                        cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, no_records, species, match, score, located_at, timestamp) VALUES 
                                                                (%(gbifid)s, %(source)s, %(no_records)s, %(species)s, %(match)s, %(score)s, %(located_at)s, NOW())""", {'gbifid': record['gbifid'], 'source': 'gbif.genus', 'no_records': str(row['no_records']), 'species': sciname['species'], 'match': str(row['uid']), 'score': row['score'], 'located_at': row['located_at']})
                        logger1.debug(cur.query)
        ######################
        #WDPA
        logger1.info("WDPA: {}".format(country['countrycode']))
        if pycountry.countries.get(alpha_2 = record['countrycode']) != None:
            iso = pycountry.countries.get(alpha_2 = record['countrycode']).alpha_3
            query_template = """
                    SELECT uid, name, gadm2 as stateprovince, 'wdpa_polygons' as source FROM wdpa_polygons WHERE parent_iso = '{iso}' AND lower(name) != 'unknown'
                    UNION 
                    SELECT uid, orig_name AS name, gadm2 as stateprovince, 'wdpa_polygons' as source FROM wdpa_polygons WHERE parent_iso = '{iso}' AND lower(name) != 'unknown'
                    UNION 
                    SELECT uid, name, gadm2 as stateprovince, 'wdpa_points' as source FROM wdpa_points WHERE parent_iso = '{iso}' AND lower(name) != 'unknown'
                    UNION 
                    SELECT uid, orig_name AS name, gadm2 as stateprovince, 'wdpa_points' as source FROM wdpa_points WHERE parent_iso = '{iso}' AND lower(name) != 'unknown'
                    """
            cur.execute(query_template.format(iso = iso))
            logger1.debug(cur.query)
            candidates = pd.DataFrame(cur.fetchall())
            logger1.info("No. of WDPA candidates: {}".format(len(candidates)))
            if len(candidates) > 0:
                #Iterate each record
                for index, record in records.iterrows():
                    logger1.info("record gbifid: {}".format(record['gbifid']))
                    logger1.info("locality: {}, {}, {}".format(record['locality'], record['stateprovince'], record['countrycode']))
                    data = search_fuzzy(record['locality'], record['stateprovince'], candidates, method = 'set', threshold = 80)
                    logger1.info("No. of possible matches: {}".format(len(data)))
                    if len(data) > 0:
                        for index, row in data.iterrows():
                            cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, species, match, score, located_at, timestamp) VALUES 
                                                                    (%(gbifid)s, %(source)s, %(species)s, %(match)s, %(score)s, %(stateprovince)s, NOW())""", {'gbifid': record['gbifid'], 'source': row['source'], 'species': sciname['species'], 'match': str(row['uid']), 'score': row['score'], 'stateprovince': row['stateprovince']})
                            logger1.debug(cur.query)
        ######################
        #GADM
        logger1.info("GADM: {}".format(country['countrycode']))
        if pycountry.countries.get(alpha_2 = record['countrycode']) != None:
            country = pycountry.countries.get(alpha_2 = record['countrycode']).name
            #GADM1
            query_template = "SELECT uid, name_1 as name, name_0 as stateprovince, 'gadm1' as source FROM gadm1 WHERE name_0 = '{country}' UNION SELECT uid, varname_1 as name, name_0 as stateprovince, 'gadm1' as source FROM gadm1 WHERE name_0 = '{country}' AND varname_1 IS NOT NULL"
            cur.execute(query_template.format(country = country.replace("'", "''")))
            data = pd.DataFrame(cur.fetchall())
            #GADM2
            query_template = "SELECT uid, name_2 as name, name_1 || ', ' || name_0 as stateprovince, 'gadm2' as source FROM gadm2 WHERE name_0 = '{country}' UNION SELECT uid, varname_2 as name, name_1 || ', ' || name_0 as stateprovince, 'gadm2' as source FROM gadm2 WHERE name_0 = '{country}' AND varname_2 IS NOT NULL"
            cur.execute(query_template.format(country = country.replace("'", "''")))
            data1 = pd.DataFrame(cur.fetchall())
            data = pd.concat([data, data1], ignore_index=True)
            #GADM3
            query_template = "SELECT uid, name_3 as name, name_2 || ', ' || name_1 || ', ' || name_0 as stateprovince, 'gadm3' as source FROM gadm3 WHERE name_0 = '{country}' UNION SELECT uid, varname_3 as name, name_2 || ', ' || name_1 || ', ' || name_0 as stateprovince, 'gadm3' as source FROM gadm3 WHERE name_0 = '{country}' AND varname_3 IS NOT NULL"
            cur.execute(query_template.format(country = country.replace("'", "''")))
            data1 = pd.DataFrame(cur.fetchall())
            data = pd.concat([data, data1], ignore_index=True)
            #GADM4
            query_template = "SELECT uid, name_4 as name, name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0 as stateprovince, 'gadm4' as source FROM gadm4 WHERE name_0 = '{country}' UNION SELECT uid, varname_4 as name, name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0 as stateprovince, 'gadm4' as source FROM gadm4 WHERE name_0 = '{country}' AND varname_4 IS NOT NULL"
            cur.execute(query_template.format(country = country.replace("'", "''")))
            data1 = pd.DataFrame(cur.fetchall())
            data = pd.concat([data, data1], ignore_index=True)
            #GADM5
            query_template = "SELECT uid, name_5 as name, name_4 || ', ' || name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0 as stateprovince, 'gadm5' as source FROM gadm5 WHERE name_0 = '{country}'"
            cur.execute(query_template.format(country = country.replace("'", "''")))
            data1 = pd.DataFrame(cur.fetchall())
            candidates = pd.concat([data, data1], ignore_index=True)
            logger1.info("No. of GADM candidates: {}".format(len(candidates)))
            if len(candidates) > 0:
                #Iterate each record
                for index, record in records.iterrows():
                    logger1.info("record gbifid: {}".format(record['gbifid']))
                    logger1.info("locality: {}, {}, {}".format(record['locality'], record['stateprovince'], record['countrycode']))
                    data = search_fuzzy(record['locality'], record['stateprovince'], candidates, method = 'set', threshold = 80)
                    logger1.info("No. of possible matches: {}".format(len(data)))
                    if len(data) > 0:
                        for index, row in data.iterrows():
                            cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, species, match, score, located_at, timestamp) VALUES 
                                                                    (%(gbifid)s, %(source)s, %(species)s, %(match)s, %(score)s, %(stateprovince)s, NOW())""", {'gbifid': record['gbifid'], 'source': row['source'], 'species': sciname['species'], 'match': str(row['uid']), 'score': row['score'], 'stateprovince': row['stateprovince']})
                            logger1.debug(cur.query)
        ######################
        #Geonames
        # if record['countrycode'] != None:
        #     query_template = """
        #             SELECT uid, name, gadm2 as stateprovince, 'geonames' as source FROM geonames WHERE country_code = '{countrycode}'
        #             UNION
        #             SELECT uid, unnest(string_to_array(alternatenames, ',')) as name, gadm2 as stateprovince, 'geonames' as source FROM geonames WHERE country_code = '{countrycode}'
        #             """
        #     cur.execute(query_template.format(countrycode = record['countrycode']))
        #     logger1.debug(cur.query)
        #     candidates = pd.DataFrame(cur.fetchall())
        #     logger1.info("No. of candidates: {}".format(len(candidates)))
        #     if len(candidates) > 0:
        #         #Iterate each record
        #         for index, record in records.iterrows():
        #             logger1.info("locality: {}, {}, {}".format(record['locality'], record['stateprovince'], record['countrycode']))
        #             data = search_fuzzy(record['locality'], record['stateprovince'], candidates, method = 'set', threshold = 80)
        #             for index, row in data.iterrows():
        #                 cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, species, match, score, located_at, timestamp) VALUES 
        #                                                         (%(gbifid)s, %(source)s, %(species)s, %(match)s, %(score)s, %(stateprovince)s, NOW())""", {'gbifid': record['gbifid'], 'source': row['source'], 'species': sciname['species'], 'match': str(row['uid']), 'score': row['score'], 'stateprovince': row['stateprovince']})
        #                 logger1.debug(cur.query)
        ######################
        #GNIS
        if record['countrycode'] == 'US':
            logger1.info("GNIS: {}, US".format(record['stateprovince']))
            query_template = "SELECT uid, feature_name as name, gadm2 as stateprovince, 'gnis' as source FROM gnis WHERE state_alpha ILIKE '%{stateprovince}%'"
            cur.execute(query_template.format(stateprovince = record['stateprovince']))
            logger1.debug(cur.query)
            candidates = pd.DataFrame(cur.fetchall())
            logger1.info("No. of GNIS candidates: {}".format(len(candidates)))
            if len(candidates) > 0:
                #Iterate each record
                for index, record in records.iterrows():
                    logger1.info("record gbifid: {}".format(record['gbifid']))
                    logger1.info("locality: {}, {}, {}".format(record['locality'], record['stateprovince'], record['countrycode']))
                    data = search_fuzzy(record['locality'], record['stateprovince'], candidates, method = 'set', threshold = 80)
                    logger1.info("No. of possible matches: {}".format(len(data)))
                    if len(data) > 0:
                        for index, row in data.iterrows():
                            cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, species, match, score, located_at, timestamp) VALUES 
                                                                    (%(gbifid)s, %(source)s, %(species)s, %(match)s, %(score)s, %(stateprovince)s, NOW())""", {'gbifid': record['gbifid'], 'source': row['source'], 'species': sciname['species'], 'match': str(row['uid']), 'score': row['score'], 'stateprovince': row['stateprovince']})
                            logger1.debug(cur.query)
        #############
        #Lakes
        if pycountry.countries.get(alpha_2 = record['countrycode']) != None:
            country = pycountry.countries.get(alpha_2 = record['countrycode']).name
            logger1.info("Lakes: {}".format(country.replace("'", "''")))
            query_template = "SELECT uid, lake_name as name, gadm2 as stateprovince, 'global_lakes' as source FROM global_lakes WHERE country ILIKE '%{country}%'"
            cur.execute(query_template.format(country = country.replace("'", "''")))
            logger1.debug(cur.query)
        else:
            query_template = "SELECT uid, lake_name as name, gadm2 as stateprovince, 'global_lakes' as source FROM global_lakes"
            cur.execute(query_template)
        candidates = pd.DataFrame(cur.fetchall())
        logger1.info("No. of global_lakes candidates: {}".format(len(candidates)))
        if len(candidates) > 0:
            #Iterate each record
            for index, record in records.iterrows():
                logger1.info("record gbifid: {}".format(record['gbifid']))
                logger1.info("locality: {}, {}, {}".format(record['locality'], record['stateprovince'], record['countrycode']))
                data = search_fuzzy(record['locality'], record['stateprovince'], candidates, method = 'set', threshold = 80)
                logger1.info("No. of possible matches: {}".format(len(data)))
                if len(data) > 0:
                    for index, row in data.iterrows():
                        cur.execute("""INSERT INTO gbif_si_matches (gbifid, source, species, match, score, located_at, timestamp) VALUES 
                                                                (%(gbifid)s, %(source)s, %(species)s, %(match)s, %(score)s, %(stateprovince)s, NOW())""", {'gbifid': record['gbifid'], 'source': row['source'], 'species': sciname['species'], 'match': str(row['uid']), 'score': row['score'], 'stateprovince': row['stateprovince']})
                        logger1.debug(cur.query)
    #Save summary of results
    cur.execute("SELECT count(*) as no_records FROM gbif_si_matches WHERE species = %s", (sciname['species'],))
    logger1.debug(cur.query)
    no_records = cur.fetchone()
    if no_records['no_records'] > 0:
        cur.execute("""INSERT INTO gbif_si_summary (species, kingdom, phylum, class, _order, family, genus, no_records)  
                            (SELECT %(species)s, %(kingdom)s, %(phylum)s, %(class)s, %(_order)s, %(family)s, %(genus)s, count(*) FROM gbif_si_matches where species = %(species)s);""", {'species': sciname['species'], 'kingdom': sciname['kingdom'], 'phylum': sciname['phylum'], 'class': sciname['class'], '_order': sciname['_order'], 'family': sciname['family'], 'genus': sciname['genus']})
        logger1.debug(cur.query)
        cur.execute("DELETE FROM gbif_si_summary WHERE no_records = 0")
    



sys.exit(0)