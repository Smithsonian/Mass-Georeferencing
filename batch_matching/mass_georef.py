#!/usr/bin/env python3
#
# Mass Georeferencing script
# Version 0.1
#
# 2020-07-10
# 
# Digitization Program Office, 
# Office of the Chief Information Officer,
# Smithsonian Institution
# https://dpo.si.edu
#
#Import modules
import os, logging, sys, locale, uuid, glob, tqdm
import unicodedata, subprocess, pycountry, swifter
import pandas as pd
import numpy as np
from time import localtime, strftime
from fuzzywuzzy import fuzz
from pyfiglet import Figlet
import psycopg2, psycopg2.extras
from psycopg2.extras import execute_batch
import random
from nltk.corpus import stopwords
from tqdm import tqdm


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
#cur.execute(collex['collex_definition'])
cur.execute(queries.get_collex_species, (settings.collex_id,))
logger1.debug(cur.query)
scinames = cur.fetchall()
if len(scinames) == 0:
    logger1.error("Query did not find species")
    sys.exit(1)

#Delete previous records matches
logger1.info("Deleting old matches...")
cur.execute(queries.delete_collex_matches, (settings.collex_id,))
logger1.debug(cur.query)


#Randomize species
random.shuffle(scinames)


#To remove stop words
stop = stopwords.words('english')


#Loop the species
for sciname in scinames:
    logger1.info("sciname: {}".format(sciname['species']))
    #Get countrycodes for the species
    # country can be comma-separated array
    cur.execute(queries.get_spp_countries, (sciname['species'], settings.collex_id))
    logger1.debug(cur.query)
    countries = cur.fetchall()
    #Records with countrycode
    for country in countries:
        #Get records for the country
        cur.execute(queries.get_records_for_country, {'species': sciname['species'], 'countrycode': country['countrycode'], 'collex_id': settings.collex_id})
        logger1.debug(cur.query)
        records_g = pd.DataFrame(cur.fetchall())
        #Create unique id
        records_g['recgroup_id'] = [uuid.uuid4() for _ in range(len(records_g.index))]
        records_g['recgroup_id'] = records_g['recgroup_id'].astype('str')
        logger1.info("Found {} records of {} in {}".format(len(records_g), sciname['species'], country['countrycode']))
        records_g['collex_id'] = settings.collex_id
        #Create column without stop words
        records_g['locality_without_stopwords1'] = records_g['locality'].apply(lambda x: ' '.join([word for word in x.split() if word not in (stop)]))
        #Remove diacritic characters
        records_g['locality_without_stopwords'] = records_g['locality_without_stopwords1'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
        del records_g['locality_without_stopwords1']
        records_g['stateprovince'] = records_g['stateprovince'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
        records_g_insert = records_g[['recgroup_id', 'collex_id', 'locality', 'stateprovince', 'countrycode', 'recordedby', 'kingdom', 'phylum', 'class', '_order', 'family', 'genus', 'species', 'no_records']].copy()
        records_g_insert2 = records_g_insert.values.tolist()
        psycopg2.extras.execute_batch(cur, queries.insert_mg_recordgroups, records_g_insert2)
        #Insert link to records by group
        for index, record in records_g.iterrows():
            cur.execute(queries.insert_mg_records, {'species': sciname['species'], 'countrycode': country['countrycode'], 'locality': record['locality'], 'stateprovince': record['stateprovince'], 'kingdom': record['kingdom'], 'phylum': record['phylum'], 'class': record['class'], '_order': record['_order'], 'family': record['family'], 'genus': record['genus'], 'recgroup_id': record['recgroup_id']})
            logger1.debug(cur.query)
        #GBIF - species
        if 'gbif.species' in settings.layers:
            if country['countrycode'] == "":
                cur.execute(queries.gbif_species.replace('\n', ' ').format(species = sciname['species']))
            else:
                cur.execute(queries.gbif_species_country.replace('\n', ' ').format(species = sciname['species'], countrycode = country['countrycode']))
            logger1.debug(cur.query)
            allcandidates = pd.DataFrame(cur.fetchall())
            logger1.info("No. of GBIF candidates for species: {}".format(len(allcandidates)))
            if len(allcandidates) > 0:
                #Iterate each record
                for index, record in records_g.iterrows():
                    candidates = allcandidates.copy()
                    candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
                    candidates['candidate_id'] = candidates['candidate_id'].astype('str')
                    #Remove diacritic characters
                    candidates['name'].replace(np.nan, "", inplace=True)
                    candidates['stateprovince'].replace(np.nan, "", inplace=True)                        
                    candidates['name_ascii'] = candidates['name'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
                    candidates['stateprovince_ascii'] = candidates['stateprovince'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
                    ##################
                    #Execute matches
                    ##################
                    #locality.partial_ratio
                    candidates['score1'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name_ascii']), axis = 1)
                    candidates['score1_type'] = "locality.partial_ratio"
                    #stateprovince
                    candidates['score2'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince_ascii']), axis = 1)
                    candidates['score2_type'] = "stateprovince"
                    #locality.token_set_ratio
                    candidates['score3'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality_without_stopwords'], row['name_ascii']), axis = 1)
                    candidates['score3_type'] = "locality.token_set_ratio"
                    #Remove candidates with average score less than settings.min_score
                    candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                    if len(candidates) == 0:
                            continue
                    #candidates['recgroup_id'] = record['recgroup_id']
                    candidates.insert(len(candidates.columns), 'recgroup_id', record['recgroup_id'])
                    #candidates['data_source'] = 'gbif.species'
                    #candidates.insert(len(candidates.columns), 'data_source', 'gbif.species')
                    #Insert candidates and each score
                    insert_candidates(candidates[['candidate_id', 'recgroup_id', 'data_source', 'uid', 'no_features']].copy(), cur, logger1)
                    insert_scores(candidates[['candidate_id', 'score1_type', 'score1']].copy(), cur, logger1)
                    insert_scores(candidates[['candidate_id', 'score2_type', 'score2']].copy(), cur, logger1)
                    insert_scores(candidates[['candidate_id', 'score3_type', 'score3']].copy(), cur, logger1)
                    del candidates
        #GBIF - Genus
        if 'gbif.genus' in settings.layers:
            if country['countrycode'] == "":
                cur.execute(queries.gbif_genus.replace('\n', ' ').format(genus = sciname['species'].split(' ')[0], species = sciname['species']))
            else:
                cur.execute(queries.gbif_genus_country.replace('\n', ' ').format(genus = sciname['species'].split(' ')[0], species = sciname['species'], countrycode = country['countrycode']))
            logger1.debug(cur.query)
            allcandidates = pd.DataFrame(cur.fetchall())
            logger1.info("No. of GBIF candidates for genus: {}".format(len(allcandidates)))
            if len(allcandidates) > 0:
                #Iterate each record
                for index, record in records_g.iterrows():
                    candidates = allcandidates.copy()
                    candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
                    candidates['candidate_id'] = candidates['candidate_id'].astype('str')
                    #Remove diacritic characters
                    candidates['name'].replace(np.nan, "", inplace=True)
                    candidates['stateprovince'].replace(np.nan, "", inplace=True)                        
                    candidates['name_ascii'] = candidates['name'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
                    candidates['stateprovince_ascii'] = candidates['stateprovince'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
                    ##################
                    #Execute matches
                    ##################
                    #locality.partial_ratio
                    candidates['score1'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name_ascii']), axis = 1)
                    candidates['score1_type'] = "locality.partial_ratio"
                    #stateprovince
                    candidates['score2'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince_ascii']), axis = 1)
                    candidates['score2_type'] = "stateprovince"
                    #locality.token_set_ratio
                    candidates['score3'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality_without_stopwords'], row['name_ascii']), axis = 1)
                    candidates['score3_type'] = "locality.token_set_ratio"
                    #Remove candidates with average score less than settings.min_score
                    candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                    if len(candidates) == 0:
                            continue
                    #candidates['data_source'] = 'gbif.genus'
                    candidates.insert(len(candidates.columns), 'recgroup_id', record['recgroup_id'])
                    #candidates.insert(len(candidates.columns), 'data_source', 'gbif.genus')
                    #Insert candidates and each score
                    insert_candidates(candidates[['candidate_id', 'recgroup_id', 'data_source', 'uid', 'no_features']].copy(), cur, logger1)
                    insert_scores(candidates[['candidate_id', 'score1_type', 'score1']].copy(), cur, logger1)
                    insert_scores(candidates[['candidate_id', 'score2_type', 'score2']].copy(), cur, logger1)
                    insert_scores(candidates[['candidate_id', 'score3_type', 'score3']].copy(), cur, logger1)
                    del candidates
        #WDPA
        if 'wdpa' in settings.layers:
            if pycountry.countries.get(alpha_2 = country['countrycode']) != None:
                for state in records_g['stateprovince'].unique():
                    if state == "":
                        cur.execute(queries.wdpa_iso.replace('\n', ' ').format(iso = pycountry.countries.get(alpha_2 = country['countrycode']).alpha_3))
                    else:
                        #cur.execute(queries.gnis_query_state, (state, ))
                        cur.execute(queries.wdpa_iso_state.replace('\n', ' ').format(stateprovince = state, iso = pycountry.countries.get(alpha_2 = country['countrycode']).alpha_3))
                    logger1.debug(cur.query)
                    allcandidates = pd.DataFrame(cur.fetchall())
                    logger1.info("No. of WDPA candidates ({}, {}): {}".format(state, country['countrycode'], len(allcandidates)))
                    if len(allcandidates) > 0:
                        #Iterate each record
                        for index, record in records_g[records_g.stateprovince == state].iterrows():
                            candidates = allcandidates.copy()
                            candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
                            candidates['candidate_id'] = candidates['candidate_id'].astype('str')
                            #Remove diacritic characters
                            candidates['name'].replace(np.nan, "", inplace=True)
                            candidates['stateprovince'].replace(np.nan, "", inplace=True)                        
                            candidates['name_ascii'] = candidates['name'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
                            candidates['stateprovince_ascii'] = candidates['stateprovince'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
                            ##################
                            #Execute matches
                            ##################
                            #locality.partial_ratio
                            candidates['score1'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name_ascii']), axis = 1)
                            candidates['score1_type'] = "locality.partial_ratio"
                            #stateprovince
                            candidates['score2'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince_ascii']), axis = 1)
                            candidates['score2_type'] = "stateprovince"
                            #locality.token_set_ratio
                            candidates['score3'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality_without_stopwords'], row['name_ascii']), axis = 1)
                            candidates['score3_type'] = "locality.token_set_ratio"
                            #Remove candidates with average score less than settings.min_score
                            candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                            if len(candidates) == 0:
                                continue
                            #candidates['recgroup_id'] = record['recgroup_id']
                            candidates = candidates.assign(recgroup_id = record['recgroup_id'])
                            #candidates['no_features'] = 1
                            candidates = candidates.assign(no_features = 1)
                            #Insert candidates and each score
                            insert_candidates(candidates[['candidate_id', 'recgroup_id', 'data_source', 'uid', 'no_features']].copy(), cur, logger1)
                            insert_scores(candidates[['candidate_id', 'score1_type', 'score1']].copy(), cur, logger1)
                            insert_scores(candidates[['candidate_id', 'score2_type', 'score2']].copy(), cur, logger1)
                            insert_scores(candidates[['candidate_id', 'score3_type', 'score3']].copy(), cur, logger1)
                            del candidates
        #GADM
        if 'gadm' in settings.layers:
            if pycountry.countries.get(alpha_2 = country['countrycode']) != None:
                for state in records_g['stateprovince'].unique():
                    if state == "":
                        cur.execute(queries.gadm_country.replace('\n', ' '), {'iso': pycountry.countries.get(alpha_2 = country['countrycode']).alpha_3})
                    else:
                        cur.execute(queries.gadm_country_state.replace('\n', ' '), {'iso': pycountry.countries.get(alpha_2 = country['countrycode']).alpha_3, 'stateprovince': "%{}%".format(state)})
                    logger1.debug(cur.query)
                    allcandidates = pd.DataFrame(cur.fetchall())
                    logger1.info("No. of GADM candidates ({}, {}): {}".format(state, country['countrycode'], len(allcandidates)))
                    if len(allcandidates) > 0:
                        #Iterate each record
                        for index, record in records_g[records_g.stateprovince == state].iterrows():
                            candidates = allcandidates.copy()
                            candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
                            candidates['candidate_id'] = candidates['candidate_id'].astype('str')
                            #Remove diacritic characters
                            candidates['name'].replace(np.nan, "", inplace=True)
                            candidates['stateprovince'].replace(np.nan, "", inplace=True)                        
                            candidates['name_ascii'] = candidates['name'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
                            candidates['stateprovince_ascii'] = candidates['stateprovince'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
                            ##################
                            #Execute matches
                            ##################
                            #locality.partial_ratio
                            candidates['score1'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name_ascii']), axis = 1)
                            candidates['score1_type'] = "locality.partial_ratio"
                            #stateprovince
                            candidates['score2'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince_ascii']), axis = 1)
                            candidates['score2_type'] = "stateprovince"
                            #locality.token_set_ratio
                            candidates['score3'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality_without_stopwords'], row['name_ascii']), axis = 1)
                            candidates['score3_type'] = "locality.token_set_ratio"
                            #Remove candidates with average score less than settings.min_score
                            candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                            if len(candidates) == 0:
                                continue
                            #candidates['recgroup_id'] = record['recgroup_id']
                            candidates = candidates.assign(recgroup_id = record['recgroup_id'])
                            #candidates['no_features'] = 1
                            candidates = candidates.assign(no_features = 1)
                            #Insert candidates and each score
                            insert_candidates(candidates[['candidate_id', 'recgroup_id', 'data_source', 'uid', 'no_features']].copy(), cur, logger1)
                            insert_scores(candidates[['candidate_id', 'score1_type', 'score1']].copy(), cur, logger1)
                            insert_scores(candidates[['candidate_id', 'score2_type', 'score2']].copy(), cur, logger1)
                            insert_scores(candidates[['candidate_id', 'score3_type', 'score3']].copy(), cur, logger1)
                            del candidates
        #GNIS
        if 'gnis' in settings.layers and country['countrycode'] == 'US':
            for state in records_g['stateprovince'].unique():
                if state == "":
                    cur.execute(queries.gnis_query)
                else:
                    cur.execute(queries.gnis_query_state, {'state': "%{}%, United States".format(state)})
                logger1.debug(cur.query)
                allcandidates = pd.DataFrame(cur.fetchall())
                logger1.info("No. of GNIS candidates ({}, {}): {}".format(state, country['countrycode'], len(allcandidates)))
                if len(allcandidates) > 0:
                    #Iterate each record
                    for index, record in records_g[records_g.stateprovince == state].iterrows():
                        candidates = allcandidates.copy()
                        candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
                        candidates['candidate_id'] = candidates['candidate_id'].astype('str')
                        #Remove diacritic characters
                        candidates['name'].replace(np.nan, "", inplace=True)
                        candidates['stateprovince'].replace(np.nan, "", inplace=True)                        
                        candidates['name_ascii'] = candidates['name'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
                        candidates['stateprovince_ascii'] = candidates['stateprovince'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
                        ##################
                        #Execute matches
                        ##################
                        #locality.partial_ratio
                        candidates['score1'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name_ascii']), axis = 1)
                        candidates['score1_type'] = "locality.partial_ratio"
                        #stateprovince
                        candidates['score2'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince_ascii']), axis = 1)
                        candidates['score2_type'] = "stateprovince"
                        #locality.token_set_ratio
                        candidates['score3'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality_without_stopwords'], row['name_ascii']), axis = 1)
                        candidates['score3_type'] = "locality.token_set_ratio"
                        #Remove candidates with average score less than settings.min_score
                        candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                        if len(candidates) == 0:
                            continue
                        #candidates['recgroup_id'] = record['recgroup_id'].astype('str')
                        #candidates['recgroup_id'] = record['recgroup_id']
                        candidates = candidates.assign(recgroup_id = record['recgroup_id'])
                        #candidates['no_features'] = 1
                        candidates = candidates.assign(no_features = 1)
                        #Insert candidates and each score
                        insert_candidates(candidates[['candidate_id', 'recgroup_id', 'data_source', 'uid', 'no_features']].copy(), cur, logger1)
                        insert_scores(candidates[['candidate_id', 'score1_type', 'score1']].copy(), cur, logger1)
                        insert_scores(candidates[['candidate_id', 'score2_type', 'score2']].copy(), cur, logger1)
                        insert_scores(candidates[['candidate_id', 'score3_type', 'score3']].copy(), cur, logger1)
                        del candidates
        #Historical_Counties
        if 'hist_counties' in settings.layers and country['countrycode'] == 'US':
            for state in records_g['stateprovince'].unique():
                if state == "":
                    cur.execute(queries.hist_counties_query_nodate)
                else:
                    cur.execute(queries.hist_counties_query_nodate_state, {'state': "%{}%".format(state)})
                logger1.debug(cur.query)
                allcandidates = pd.DataFrame(cur.fetchall())
                logger1.info("No. of Hist_Counties candidates ({}, {}): {}".format(state, country['countrycode'], len(allcandidates)))
                if len(allcandidates) > 0:
                    #Iterate each record
                    for index, record in records_g[records_g.stateprovince == state].iterrows():
                        candidates = allcandidates.copy()
                        candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
                        candidates['candidate_id'] = candidates['candidate_id'].astype('str')
                        #Remove diacritic characters
                        candidates['name'].replace(np.nan, "", inplace=True)
                        candidates['stateprovince'].replace(np.nan, "", inplace=True)                        
                        candidates['name_ascii'] = candidates['name'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
                        candidates['stateprovince_ascii'] = candidates['stateprovince'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
                        ##################
                        #Execute matches
                        ##################
                        #locality.partial_ratio
                        candidates['score1'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name_ascii']), axis = 1)
                        candidates['score1_type'] = "locality.partial_ratio"
                        #locality.token_set_ratio
                        candidates['score2'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality_without_stopwords'], row['name_ascii']), axis = 1)
                        candidates['score2_type'] = "locality.token_set_ratio"
                        #Remove candidates with average score less than settings.min_score
                        candidates = candidates[(candidates.score1 + candidates.score2) > (settings.min_score * 2)]
                        if len(candidates) == 0:
                            continue
                        #candidates['recgroup_id'] = record['recgroup_id']
                        candidates = candidates.assign(recgroup_id = record['recgroup_id'])
                        #candidates['no_features'] = 1
                        candidates = candidates.assign(no_features = 1)
                        #Insert candidates and each score
                        insert_candidates(candidates[['candidate_id', 'recgroup_id', 'data_source', 'uid', 'no_features']].copy(), cur, logger1)
                        insert_scores(candidates[['candidate_id', 'score1_type', 'score1']].copy(), cur, logger1)
                        insert_scores(candidates[['candidate_id', 'score2_type', 'score2']].copy(), cur, logger1)
                        del candidates
        #Tiger (US Census)
        if 'tiger' in settings.layers and country['countrycode'] == 'US':
            for state in records_g['stateprovince'].unique():
                if state == "":
                    cur.execute(queries.tiger_query)
                else:
                    cur.execute(queries.tiger_query_state, {'state': "%{}%, United States".format(state)})
                #cur.execute(queries.tiger_query)
                logger1.debug(cur.query)
                allcandidates = pd.DataFrame(cur.fetchall())
                logger1.info("No. of TIGER candidates ({}, {}): {}".format(state, country['countrycode'], len(allcandidates)))
                if len(allcandidates) > 0:
                    #Iterate each record
                    for index, record in records_g[records_g.stateprovince == state].iterrows():
                        candidates = allcandidates.copy()
                        candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
                        candidates['candidate_id'] = candidates['candidate_id'].astype('str')
                        #Remove diacritic characters
                        candidates['name'].replace(np.nan, "", inplace=True)
                        candidates['stateprovince'].replace(np.nan, "", inplace=True)                        
                        candidates['name_ascii'] = candidates['name'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
                        candidates['stateprovince_ascii'] = candidates['stateprovince'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
                        ##################
                        #Execute matches
                        ##################
                        #locality.partial_ratio
                        candidates['score1'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name_ascii']), axis = 1)
                        candidates['score1_type'] = "locality.partial_ratio"
                        #stateprovince
                        candidates['score2'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince_ascii']), axis = 1)
                        candidates['score2_type'] = "stateprovince"
                        #locality.token_set_ratio
                        candidates['score3'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality_without_stopwords'], row['name_ascii']), axis = 1)
                        candidates['score3_type'] = "locality.token_set_ratio"
                        #Remove candidates with average score less than settings.min_score
                        candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                        if len(candidates) == 0:
                            continue
                        #candidates['recgroup_id'] = record['recgroup_id']
                        candidates = candidates.assign(recgroup_id = record['recgroup_id'])
                        #candidates['no_features'] = 1
                        candidates = candidates.assign(no_features = 1)
                        #Insert candidates and each score
                        insert_candidates(candidates[['candidate_id', 'recgroup_id', 'data_source', 'uid', 'no_features']].copy(), cur, logger1)
                        insert_scores(candidates[['candidate_id', 'score1_type', 'score1']].copy(), cur, logger1)
                        insert_scores(candidates[['candidate_id', 'score2_type', 'score2']].copy(), cur, logger1)
                        insert_scores(candidates[['candidate_id', 'score3_type', 'score3']].copy(), cur, logger1)
                        del candidates
        #Topos (US)
        if 'topos' in settings.layers and country['countrycode'] == 'US':
            for state in records_g['stateprovince'].unique():
                if state == "":
                    cur.execute(queries.topos_query)
                else:
                    cur.execute(queries.topos_query_state, {'state': "%{}%, United States".format(state)})
                logger1.debug(cur.query)
                allcandidates = pd.DataFrame(cur.fetchall())
                logger1.info("No. of Topos candidates ({}, {}): {}".format(state, country['countrycode'], len(allcandidates)))
                if len(allcandidates) > 0:
                    #Iterate each record
                    for index, record in records_g[records_g.stateprovince == state].iterrows():
                        candidates = allcandidates.copy()
                        candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
                        candidates['candidate_id'] = candidates['candidate_id'].astype('str')
                        #Remove diacritic characters
                        candidates['name'].replace(np.nan, "", inplace=True)
                        candidates['stateprovince'].replace(np.nan, "", inplace=True)
                        candidates['name_ascii'] = candidates['name'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
                        candidates['stateprovince_ascii'] = candidates['stateprovince'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
                        ##################
                        #Execute matches
                        ##################
                        #locality.partial_ratio
                        candidates['score1'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name_ascii']), axis = 1)
                        candidates['score1_type'] = "locality.partial_ratio"
                        #stateprovince
                        candidates['score2'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince_ascii']), axis = 1)
                        candidates['score2_type'] = "stateprovince"
                        #locality.token_set_ratio
                        candidates['score3'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality_without_stopwords'], row['name_ascii']), axis = 1)
                        candidates['score3_type'] = "locality.token_set_ratio"
                        #Remove candidates with average score less than settings.min_score
                        candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                        if len(candidates) == 0:
                            continue
                        #candidates['recgroup_id'] = record['recgroup_id']
                        candidates = candidates.assign(recgroup_id = record['recgroup_id'])
                        #candidates['no_features'] = 1
                        candidates = candidates.assign(no_features = 1)
                        #Total score
                        candidates['score_total'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : row['score1'] + row['score2'] + row['score3'], axis = 1)
                        #Due to repetitions across multiple topos, filter this layer to the top 20 
                        candidates_subset = candidates.copy().nlargest(20, 'score_total')
                        #Insert candidates and each score
                        insert_candidates(candidates_subset[['candidate_id', 'recgroup_id', 'data_source', 'uid', 'no_features']].copy(), cur, logger1)
                        insert_scores(candidates_subset[['candidate_id', 'score1_type', 'score1']].copy(), cur, logger1)
                        insert_scores(candidates_subset[['candidate_id', 'score2_type', 'score2']].copy(), cur, logger1)
                        insert_scores(candidates_subset[['candidate_id', 'score3_type', 'score3']].copy(), cur, logger1)
                        del candidates
        #Rivers (US)
        if 'usa_rivers' in settings.layers and country['countrycode'] == 'US':
            for state in records_g['stateprovince'].unique():
                if state == "":
                    cur.execute(queries.usa_rivers_query)
                else:
                    cur.execute(queries.usa_rivers_query_state, {'state': "%{}%, United States".format(state)})
                logger1.debug(cur.query)
                allcandidates = pd.DataFrame(cur.fetchall())
                logger1.info("No. of river candidates ({}, {}): {}".format(state, country['countrycode'], len(allcandidates)))
                if len(allcandidates) > 0:
                    #Iterate each record
                    for index, record in records_g[records_g.stateprovince == state].iterrows():
                        candidates = allcandidates.copy()
                        candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
                        candidates['candidate_id'] = candidates['candidate_id'].astype('str')
                        #Remove diacritic characters
                        candidates['name'].replace(np.nan, "", inplace=True)
                        candidates['stateprovince'].replace(np.nan, "", inplace=True)
                        candidates['name_ascii'] = candidates['name'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
                        candidates['stateprovince_ascii'] = candidates['stateprovince'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
                        ##################
                        #Execute matches
                        ##################
                        #locality.partial_ratio
                        candidates['score1'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name_ascii']), axis = 1)
                        candidates['score1_type'] = "locality.partial_ratio"
                        #stateprovince
                        candidates['score2'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince_ascii']), axis = 1)
                        candidates['score2_type'] = "stateprovince"
                        #locality.token_set_ratio
                        candidates['score3'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality_without_stopwords'], row['name_ascii']), axis = 1)
                        candidates['score3_type'] = "locality.token_set_ratio"
                        #Remove candidates with average score less than settings.min_score
                        candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                        if len(candidates) == 0:
                            continue
                        #candidates['recgroup_id'] = record['recgroup_id']
                        candidates = candidates.assign(recgroup_id = record['recgroup_id'])
                        #candidates['no_features'] = 1
                        candidates = candidates.assign(no_features = 1)
                        #Total score
                        candidates['score_total'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : row['score1'] + row['score2'] + row['score3'], axis = 1)
                        #Due to repetitions across multiple topos, filter this layer to the top 20 
                        candidates_subset = candidates.copy().nlargest(20, 'score_total')
                        #Insert candidates and each score
                        insert_candidates(candidates_subset[['candidate_id', 'recgroup_id', 'data_source', 'uid', 'no_features']].copy(), cur, logger1)
                        insert_scores(candidates_subset[['candidate_id', 'score1_type', 'score1']].copy(), cur, logger1)
                        insert_scores(candidates_subset[['candidate_id', 'score2_type', 'score2']].copy(), cur, logger1)
                        insert_scores(candidates_subset[['candidate_id', 'score3_type', 'score3']].copy(), cur, logger1)
                        del candidates
        #Historical places (US)
        if 'usa_histplaces' in settings.layers and country['countrycode'] == 'US':
            for state in records_g['stateprovince'].unique():
                if state == "":
                    cur.execute(queries.usa_histplaces_query)
                else:
                    cur.execute(queries.usa_histplaces_query_state, {'state': "%{}%, United States".format(state)})
                logger1.debug(cur.query)
                allcandidates = pd.DataFrame(cur.fetchall())
                logger1.info("No. of historical places candidates ({}, {}): {}".format(state, country['countrycode'], len(allcandidates)))
                if len(allcandidates) > 0:
                    #Iterate each record
                    for index, record in records_g[records_g.stateprovince == state].iterrows():
                        candidates = allcandidates.copy()
                        candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
                        candidates['candidate_id'] = candidates['candidate_id'].astype('str')
                        #Remove diacritic characters
                        candidates['name'].replace(np.nan, "", inplace=True)
                        candidates['stateprovince'].replace(np.nan, "", inplace=True)
                        candidates['name_ascii'] = candidates['name'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
                        candidates['stateprovince_ascii'] = candidates['stateprovince'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
                        ##################
                        #Execute matches
                        ##################
                        #locality.partial_ratio
                        candidates['score1'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name_ascii']), axis = 1)
                        candidates['score1_type'] = "locality.partial_ratio"
                        #stateprovince
                        candidates['score2'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince_ascii']), axis = 1)
                        candidates['score2_type'] = "stateprovince"
                        #locality.token_set_ratio
                        candidates['score3'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality_without_stopwords'], row['name_ascii']), axis = 1)
                        candidates['score3_type'] = "locality.token_set_ratio"
                        #Remove candidates with average score less than settings.min_score
                        candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                        if len(candidates) == 0:
                            continue
                        #candidates['recgroup_id'] = record['recgroup_id']
                        candidates = candidates.assign(recgroup_id = record['recgroup_id'])
                        #candidates['no_features'] = 1
                        candidates = candidates.assign(no_features = 1)
                        #Total score
                        candidates['score_total'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : row['score1'] + row['score2'] + row['score3'], axis = 1)
                        #Due to repetitions across multiple topos, filter this layer to the top 20 
                        candidates_subset = candidates.copy().nlargest(20, 'score_total')
                        #Insert candidates and each score
                        insert_candidates(candidates_subset[['candidate_id', 'recgroup_id', 'data_source', 'uid', 'no_features']].copy(), cur, logger1)
                        insert_scores(candidates_subset[['candidate_id', 'score1_type', 'score1']].copy(), cur, logger1)
                        insert_scores(candidates_subset[['candidate_id', 'score2_type', 'score2']].copy(), cur, logger1)
                        insert_scores(candidates_subset[['candidate_id', 'score3_type', 'score3']].copy(), cur, logger1)
                        del candidates
        #USGS National Structures (US)
        if 'usgs_nat_struct' in settings.layers and country['countrycode'] == 'US':
            for state in records_g['stateprovince'].unique():
                if state == "":
                    cur.execute(queries.usgs_nat_struct_query)
                else:
                    cur.execute(queries.usgs_nat_struct_query_state, {'state': "%{}%, United States".format(state)})
                logger1.debug(cur.query)
                allcandidates = pd.DataFrame(cur.fetchall())
                logger1.info("No. of USGS National Structures candidates ({}, {}): {}".format(state, country['countrycode'], len(allcandidates)))
                if len(allcandidates) > 0:
                    #Iterate each record
                    for index, record in records_g[records_g.stateprovince == state].iterrows():
                        candidates = allcandidates.copy()
                        candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
                        candidates['candidate_id'] = candidates['candidate_id'].astype('str')
                        #Remove diacritic characters
                        candidates['name'].replace(np.nan, "", inplace=True)
                        candidates['stateprovince'].replace(np.nan, "", inplace=True)
                        candidates['name_ascii'] = candidates['name'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
                        candidates['stateprovince_ascii'] = candidates['stateprovince'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
                        ##################
                        #Execute matches
                        ##################
                        #locality.partial_ratio
                        candidates['score1'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name_ascii']), axis = 1)
                        candidates['score1_type'] = "locality.partial_ratio"
                        #stateprovince
                        candidates['score2'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince_ascii']), axis = 1)
                        candidates['score2_type'] = "stateprovince"
                        #locality.token_set_ratio
                        candidates['score3'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality_without_stopwords'], row['name_ascii']), axis = 1)
                        candidates['score3_type'] = "locality.token_set_ratio"
                        #Remove candidates with average score less than settings.min_score
                        candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                        if len(candidates) == 0:
                            continue
                        #candidates['recgroup_id'] = record['recgroup_id']
                        candidates = candidates.assign(recgroup_id = record['recgroup_id'])
                        #candidates['no_features'] = 1
                        candidates = candidates.assign(no_features = 1)
                        #Total score
                        candidates['score_total'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : row['score1'] + row['score2'] + row['score3'], axis = 1)
                        #Due to repetitions across multiple topos, filter this layer to the top 20 
                        candidates_subset = candidates.copy().nlargest(20, 'score_total')
                        #Insert candidates and each score
                        insert_candidates(candidates_subset[['candidate_id', 'recgroup_id', 'data_source', 'uid', 'no_features']].copy(), cur, logger1)
                        insert_scores(candidates_subset[['candidate_id', 'score1_type', 'score1']].copy(), cur, logger1)
                        insert_scores(candidates_subset[['candidate_id', 'score2_type', 'score2']].copy(), cur, logger1)
                        insert_scores(candidates_subset[['candidate_id', 'score3_type', 'score3']].copy(), cur, logger1)
                        del candidates
        #GNS - Not US
        if 'gns' in settings.layers and country['countrycode'] != 'US':
            if country['countrycode'] == "":
                cur.execute(queries.gns_query.replace('\n', ' '))
            else:
                for state in records_g['stateprovince'].unique():
                    if state == "":
                        cur.execute(queries.gns_query_country.replace('\n', ' '), {'country': pycountry.countries.get(alpha_2 = country['countrycode']).name})
                    else:
                        cur.execute(queries.gns_query_country_state.replace('\n', ' '), {'statecountry': "%{state}%, {country}".format(state = state, country = pycountry.countries.get(alpha_2 = country['countrycode']).name)})
            logger1.debug(cur.query)
            allcandidates = pd.DataFrame(cur.fetchall())
            logger1.info("No. of GNS candidates ({}): {}".format(country['countrycode'], len(allcandidates)))
            if len(allcandidates) > 0:
                #Iterate each record
                for index, record in records_g.iterrows():
                    candidates = allcandidates.copy()
                    candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
                    candidates['candidate_id'] = candidates['candidate_id'].astype('str')
                    #Remove diacritic characters
                    candidates['name'].replace(np.nan, "", inplace=True)
                    candidates['stateprovince'].replace(np.nan, "", inplace=True)                        
                    candidates['name_ascii'] = candidates['name'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
                    candidates['stateprovince_ascii'] = candidates['stateprovince'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
                    ##################
                    #Execute matches
                    ##################
                    #locality.partial_ratio
                    candidates['score1'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name_ascii']), axis = 1)
                    candidates['score1_type'] = "locality.partial_ratio"
                    #stateprovince
                    candidates['score2'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince_ascii']), axis = 1)
                    candidates['score2_type'] = "stateprovince"
                    #locality.token_set_ratio
                    candidates['score3'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality_without_stopwords'], row['name_ascii']), axis = 1)
                    candidates['score3_type'] = "locality.token_set_ratio"
                    #Remove candidates with average score less than settings.min_score
                    candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                    if len(candidates) == 0:
                        continue
                    #candidates['recgroup_id'] = record['recgroup_id']
                    candidates = candidates.assign(recgroup_id = record['recgroup_id'])
                    #candidates['no_features'] = 1
                    candidates = candidates.assign(no_features = 1)
                    #Insert candidates and each score
                    insert_candidates(candidates[['candidate_id', 'recgroup_id', 'data_source', 'uid', 'no_features']].copy(), cur, logger1)
                    insert_scores(candidates[['candidate_id', 'score1_type', 'score1']].copy(), cur, logger1)
                    insert_scores(candidates[['candidate_id', 'score2_type', 'score2']].copy(), cur, logger1)
                    insert_scores(candidates[['candidate_id', 'score3_type', 'score3']].copy(), cur, logger1)
                    del candidates
        #Lakes
        if 'global_lakes' in settings.layers:
            if pycountry.countries.get(alpha_2 = country['countrycode']) != None:
                cur.execute(queries.global_lakes.replace('\n', ' '), {'country': pycountry.countries.get(alpha_2 = country['countrycode']).name.replace("'", "''")})
            else:
                cur.execute(queries.global_lakes_null)
            logger1.debug(cur.query)
            allcandidates = pd.DataFrame(cur.fetchall())
            logger1.info("No. of GlobalLakes candidates ({}): {}".format(country['countrycode'], len(allcandidates)))
            if len(allcandidates) > 0:
                #Iterate each record
                for index, record in records_g.iterrows():
                    candidates = allcandidates.copy()
                    candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
                    candidates['candidate_id'] = candidates['candidate_id'].astype('str')
                    #Remove diacritic characters
                    candidates['name'].replace(np.nan, "", inplace=True)
                    candidates['stateprovince'].replace(np.nan, "", inplace=True)                        
                    candidates['name_ascii'] = candidates['name'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
                    candidates['stateprovince_ascii'] = candidates['stateprovince'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
                    ##################
                    #Execute matches
                    ##################
                    #locality.partial_ratio
                    candidates['score1'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name_ascii']), axis = 1)
                    candidates['score1_type'] = "locality.partial_ratio"
                    #stateprovince
                    candidates['score2'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince_ascii']), axis = 1)
                    candidates['score2_type'] = "stateprovince"
                    #locality.token_set_ratio
                    candidates['score3'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality_without_stopwords'], row['name_ascii']), axis = 1)
                    candidates['score3_type'] = "locality.token_set_ratio"
                    #Remove candidates with average score less than settings.min_score
                    candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                    if len(candidates) == 0:
                        continue
                    #candidates['recgroup_id'] = record['recgroup_id']
                    candidates = candidates.assign(recgroup_id = record['recgroup_id'])
                    #candidates['no_features'] = 1
                    candidates = candidates.assign(no_features = 1)
                    #Insert candidates and each score
                    insert_candidates(candidates[['candidate_id', 'recgroup_id', 'data_source', 'uid', 'no_features']].copy(), cur, logger1)
                    insert_scores(candidates[['candidate_id', 'score1_type', 'score1']].copy(), cur, logger1)
                    insert_scores(candidates[['candidate_id', 'score2_type', 'score2']].copy(), cur, logger1)
                    insert_scores(candidates[['candidate_id', 'score3_type', 'score3']].copy(), cur, logger1)
                    del candidates
        #Geonames
        if 'geonames' in settings.layers and country['countrycode'] != "":
            for state in records_g['stateprovince'].unique():
                if state == "":
                    cur.execute(queries.geonames.replace('\n', ' '), {'countrycode': country['countrycode']})
                else:
                    cur.execute(queries.geonames_state.replace('\n', ' '), {'countrycode': country['countrycode'], 'stateprovince': "%{stateprovince}%".format(stateprovince = state)})
                logger1.debug(cur.query)
                allcandidates = pd.DataFrame(cur.fetchall())
                logger1.info("No. of Geonames candidates ({}, {}): {}".format(state, country['countrycode'], len(allcandidates)))
                if len(allcandidates) > 0:
                    #Iterate each record
                    for index, record in records_g[records_g.stateprovince == state].iterrows():
                        candidates = allcandidates.copy()
                        candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
                        candidates['candidate_id'] = candidates['candidate_id'].astype('str')
                        #Remove diacritic characters
                        candidates['name'].replace(np.nan, "", inplace=True)
                        candidates['stateprovince'].replace(np.nan, "", inplace=True)                        
                        candidates['name_ascii'] = candidates['name'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
                        candidates['stateprovince_ascii'] = candidates['stateprovince'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
                        ##################
                        #Execute matches
                        ##################
                        #locality.partial_ratio
                        candidates['score1'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name_ascii']), axis = 1)
                        candidates['score1_type'] = "locality.partial_ratio"
                        #stateprovince
                        candidates['score2'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince_ascii']), axis = 1)
                        candidates['score2_type'] = "stateprovince"
                        #locality.token_set_ratio
                        candidates['score3'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality_without_stopwords'], row['name_ascii']), axis = 1)
                        candidates['score3_type'] = "locality.token_set_ratio"
                        #Remove candidates with average score less than settings.min_score
                        candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                        if len(candidates) == 0:
                            continue
                        #candidates['recgroup_id'] = record['recgroup_id']
                        candidates = candidates.assign(recgroup_id = record['recgroup_id'])
                        #candidates['no_features'] = 1
                        candidates = candidates.assign(no_features = 1)
                        #Insert candidates and each score
                        insert_candidates(candidates[['candidate_id', 'recgroup_id', 'data_source', 'uid', 'no_features']].copy(), cur, logger1)
                        insert_scores(candidates[['candidate_id', 'score1_type', 'score1']].copy(), cur, logger1)
                        insert_scores(candidates[['candidate_id', 'score2_type', 'score2']].copy(), cur, logger1)
                        insert_scores(candidates[['candidate_id', 'score3_type', 'score3']].copy(), cur, logger1)
                        del candidates
        #wikidata
        if 'wikidata' in settings.layers and country['countrycode'] != "":
            if pycountry.countries.get(alpha_2 = country['countrycode']) != None:
                for state in records_g['stateprovince'].unique():
                    if state == "":
                        cur.execute(queries.wikidata_by_country.replace('\n', ' '), {'country': "%, {country}".format(country = pycountry.countries.get(alpha_2 = country['countrycode']).name.replace("'", "''"))})
                    else:
                        cur.execute(queries.wikidata_by_country_state.replace('\n', ' '), {'statecountry': "%{stateprovince}%, {country}".format(stateprovince = state, country = pycountry.countries.get(alpha_2 = country['countrycode']).name.replace("'", "''"))})
                    #Too many candidates if there is no country
                    logger1.debug(cur.query)
                    allcandidates = pd.DataFrame(cur.fetchall())
                    logger1.info("No. of Wikidata candidates ({}, {}): {}".format(state, country['countrycode'], len(allcandidates)))
                    if len(allcandidates) > 0:
                        #Iterate each record
                        for index, record in records_g[records_g.stateprovince == state].iterrows():
                            candidates = allcandidates.copy()
                            candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
                            candidates['candidate_id'] = candidates['candidate_id'].astype('str')
                            #Remove diacritic characters
                            candidates['name'].replace(np.nan, "", inplace=True)
                            candidates['stateprovince'].replace(np.nan, "", inplace=True)                        
                            candidates['name_ascii'] = candidates['name'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
                            candidates['stateprovince_ascii'] = candidates['stateprovince'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
                            ##################
                            #Execute matches
                            ##################
                            #locality.partial_ratio
                            candidates['score1'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name_ascii']), axis = 1)
                            candidates['score1_type'] = "locality.partial_ratio"
                            #stateprovince
                            candidates['score2'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince_ascii']), axis = 1)
                            candidates['score2_type'] = "stateprovince"
                            #locality.token_set_ratio
                            candidates['score3'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality_without_stopwords'], row['name_ascii']), axis = 1)
                            candidates['score3_type'] = "locality.token_set_ratio"
                            #Remove candidates with average score less than settings.min_score
                            candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                            if len(candidates) == 0:
                                continue
                            #candidates['recgroup_id'] = record['recgroup_id']
                            candidates = candidates.assign(recgroup_id = record['recgroup_id'])
                            #candidates['no_features'] = 1
                            candidates = candidates.assign(no_features = 1)
                            #Insert candidates and each score
                            insert_candidates(candidates[['candidate_id', 'recgroup_id', 'data_source', 'uid', 'no_features']].copy(), cur, logger1)
                            insert_scores(candidates[['candidate_id', 'score1_type', 'score1']].copy(), cur, logger1)
                            insert_scores(candidates[['candidate_id', 'score2_type', 'score2']].copy(), cur, logger1)
                            insert_scores(candidates[['candidate_id', 'score3_type', 'score3']].copy(), cur, logger1)
                            del candidates
        #osm
        if 'osm' in settings.layers:
            if pycountry.countries.get(alpha_2 = country['countrycode']) != None:
                for state in records_g['stateprovince'].unique():
                    if state == "":
                        cur.execute(queries.osm_by_country.replace('\n', ' '), {'country': "%, {country}".format(country = pycountry.countries.get(alpha_2 = country['countrycode']).name.replace("'", "''"))})
                    else:
                        cur.execute(queries.osm_by_country_state.replace('\n', ' '), {'statecountry': "%{stateprovince}%, {country}".format(stateprovince = state, country = pycountry.countries.get(alpha_2 = country['countrycode']).name.replace("'", "''"))})
                    logger1.debug(cur.query)
                    allcandidates = pd.DataFrame(cur.fetchall())
                    logger1.info("No. of OSM candidates ({}, {}): {}".format(state, country['countrycode'], len(allcandidates)))
                    if len(allcandidates) > 0:
                        #Iterate each record
                        for index, record in records_g[records_g.stateprovince == state].iterrows():
                            candidates = allcandidates.copy()
                            candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
                            candidates['candidate_id'] = candidates['candidate_id'].astype('str')
                            #Remove diacritic characters
                            candidates['name'].replace(np.nan, "", inplace=True)
                            candidates['stateprovince'].replace(np.nan, "", inplace=True)                        
                            candidates['name_ascii'] = candidates['name'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
                            candidates['stateprovince_ascii'] = candidates['stateprovince'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
                            ##################
                            #Execute matches
                            ##################
                            #locality.partial_ratio
                            candidates['score1'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name_ascii']), axis = 1)
                            candidates['score1_type'] = "locality.partial_ratio"
                            #stateprovince
                            candidates['score2'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince_ascii']), axis = 1)
                            candidates['score2_type'] = "stateprovince"
                            #locality.token_set_ratio
                            candidates['score3'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality_without_stopwords'], row['name_ascii']), axis = 1)
                            candidates['score3_type'] = "locality.token_set_ratio"
                            #Remove candidates with average score less than settings.min_score
                            candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                            if len(candidates) == 0:
                                continue
                            #candidates['recgroup_id'] = record['recgroup_id']
                            candidates = candidates.assign(recgroup_id = record['recgroup_id'])
                            #candidates['no_features'] = 1
                            candidates = candidates.assign(no_features = 1)
                            #Insert candidates and each score
                            insert_candidates(candidates[['candidate_id', 'recgroup_id', 'data_source', 'uid', 'no_features']].copy(), cur, logger1)
                            insert_scores(candidates[['candidate_id', 'score1_type', 'score1']].copy(), cur, logger1)
                            insert_scores(candidates[['candidate_id', 'score2_type', 'score2']].copy(), cur, logger1)
                            insert_scores(candidates[['candidate_id', 'score3_type', 'score3']].copy(), cur, logger1)
                            del candidates
        #Calculate elevation, if available
        # if 'elevation' in settings.layers and country['countrycode'] == 'US':
        #     #Iterate each record
        #     for index, record in records_g.iterrows():
        #         #If the record had an elevation, get elevation of candidates
        #         if record['elevation'] != None:
        #             cur.execute(queries.get_candidates_country, {'species': sciname['species'], 'collex_id': settings.collex_id, 'countrycode': country['countrycode']})
        #             logger1.debug(cur.query)
        #             allcandidates = pd.DataFrame(cur.fetchall())
        #             if len(allcandidates) > 0:
        #                 logger1.info("Matching elevation for {} records of {}".format(len(allcandidates), sciname['species']))
        #                 #Get elevation
        #                 for index1, cand_record in allcandidates.iterrows():
        #                     check_elev(cand_record['data_source'], sciname['species'], record['elevation'], cand_record['candidate_id'], cand_record['feature_id'], cur, logger1)
    #Spatial Match
    if settings.spatial_match == True and settings.backend == "database":
        cur.execute(queries.get_species_candidates, {'species': sciname['species'], 'collex_id': settings.collex_id})
        logger1.debug(cur.query)
        allcandidates = pd.DataFrame(cur.fetchall())
        if len(allcandidates) > 0:
            logger1.info("Matching spatial location for {} candidates of {}".format(len(allcandidates), sciname['species']))
            #allcandidates.progress_apply(check_spatial, (allcandidates['data_source'], sciname['species'], allcandidates['candidate_id'], allcandidates['feature_id'], cur, logger1))
            allcandidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : check_spatial(row['data_source'], sciname['species'], row['candidate_id'], row['feature_id'], cur, logger1), axis = 1)
            # for index, row in allcandidates.iterrows():
            #     #Check each candidate
            #     #print("Running row {}".format(index))
            #     print(".")
            #     check_spatial(row['data_source'], sciname['species'], row['candidate_id'], row['feature_id'], cur, logger1)
        del allcandidates
        #Limit the matches to a polygon for the collection
        if settings.collex_polygon == True:
            cur.execute(queries.get_species_candidates, {'species': sciname['species'], 'collex_id': settings.collex_id})
            logger1.debug(cur.query)
            allcandidates = pd.DataFrame(cur.fetchall())
            if len(allcandidates) > 0:
                logger1.info("Limiting candidates to collex polygon for {} records of {}".format(len(allcandidates), sciname['species']))
                #allcandidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : check_spatial_extent(row['data_source'], row['feature_id'], row['candidate_id'], settings.collex_id, sciname['species'], cur, logger1), axis = 1)
                #tqdm.pandas()
                tqdm.pandas(tqdm(total = allcandidates.shape[0]))
                allcandidates.progress_apply(lambda row: check_spatial_extent(row['data_source'], row['feature_id'], row['candidate_id'], settings.collex_id, sciname['species'], cur, logger1), axis = 1)
                # for index, row in allcandidates.iterrows():
                #     print("Running row {}".format(index))
                #     check_spatial_extent(row['data_source'], row['feature_id'], row['candidate_id'], settings.collex_id, sciname['species'], cur, logger1)
            del allcandidates
    #Calculate candidates by recordgroup
    cur.execute(queries.recordgroups_stats, {'species': sciname['species'], 'collex_id': settings.collex_id})
    logger1.debug(cur.query)
    #Remove recgroups without candidates
    logger1.info("Cleanup...")
    cur.execute("DELETE FROM mg_recordgroups WHERE collex_id = '{collex_id}' AND species = '{species}' AND no_candidates = 0".format(collex_id = settings.collex_id, species = sciname['species']))
    logger1.debug(cur.query)
    
    



#Compress logs
script_dir = os.getcwd()
logger1.info("Compressing logs...")
os.chdir('{}/logs'.format(script_dir))
for file in glob.glob('*.log'):
    subprocess.run(["zip", "{}.zip".format(file), file])
    os.remove(file)
os.chdir(script_dir)


sys.exit(0)
