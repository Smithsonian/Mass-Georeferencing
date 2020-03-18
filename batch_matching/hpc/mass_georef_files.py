#!/usr/bin/env python3
#
# Mass Georeferencing script, files version
# Version 0.1
#
# 2020-03-02
# 
# Digitization Program Office, 
# Office of the Chief Information Officer,
# Smithsonian Institution
# https://dpo.si.edu
#
#Import modules
import os, logging, sys, locale, uuid, glob, pycountry, swifter, re, glob, csv
import pandas as pd
from time import localtime, strftime
from fuzzywuzzy import fuzz



#Get settings
import settings



# Set locale to UTF-8
locale.setlocale(locale.LC_ALL, 'en_US.utf8')





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

if not os.path.exists('results'):
    os.makedirs('results')




def run_species(filename):
    species_fname = filename.replace('.csv', '').replace('species/', '')
    fname = filename.replace('.csv', '').replace('species/', '').split('_')
    sciname = fname[1] + ' ' + fname[2]
    country = fname[3]
    #Get records for the country
    records_g = pd.read_csv(filename)
    records_g['recgroup_id'] = [uuid.uuid4() for _ in range(len(records_g.index))]
    records_g['recgroup_id'] = records_g['recgroup_id'].astype(str)
    logger1.info("Found {} records of {} in {}".format(len(records_g), sciname, country))
    records_g['collex_id'] = settings.collex_id
    records_g_insert = records_g[['recgroup_id', 'collex_id', 'locality', 'stateprovince', 'countrycode', 'recordedby', 'kingdom', 'phylum', 'class', '_order', 'family', 'genus', 'species', 'no_records']].copy()
    records_g_insert.to_csv('results/recgroupid_' + species_fname + '.csv', index=False, quoting = csv.QUOTE_ALL)
    #Iterate each record
    for index, record in records_g.iterrows():
        #WDPA
        if os.path.exists("wdpa/wdpa_{}.csv".format(country)):
            allcandidates = pd.read_csv("wdpa/wdpa_{}.csv".format(country))
            logger1.info("No. of WDPA candidates: {}".format(len(allcandidates)))
            if len(allcandidates) > 0:
                candidates = allcandidates.copy()
                candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
                candidates['candidate_id'] = candidates['candidate_id'].astype(str)
                ##################
                #Execute matches
                ##################
                #locality.partial_ratio
                #Disable progress bar
                # df.swifter.progress_bar(False).apply
                candidates['score1'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name']), axis = 1)
                candidates['score1_type'] = "locality.partial_ratio"
                #stateprovince
                candidates['score2'] = candidates[candidates.stateprovince.notnull()].swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince']), axis = 1)
                candidates['score2_type'] = "stateprovince"
                #locality.token_set_ratio
                candidates['score3'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality'], row['name']), axis = 1)
                candidates['score3_type'] = "locality.token_set_ratio"
                #Remove candidates with average score less than settings.min_score
                candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                candidates['recgroup_id'] = record['recgroup_id']
                candidates['no_features'] = 1
                #If there are any left, write to csv
                if len(candidates) > 0:
                    candidates.to_csv('results/candidates_wdpa_' + species_fname + '.csv', index=False, quoting = csv.QUOTE_ALL)
        #GADM
        if os.path.exists("gadm/gadm_{}.csv".format(country)):
            allcandidates = pd.read_csv("gadm/gadm_{}.csv".format(country))
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
                    candidates['score2'] = candidates[candidates.stateprovince.notnull()].swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince']), axis = 1)
                    candidates['score2_type'] = "stateprovince"
                    #locality.token_set_ratio
                    candidates['score3'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality'], row['name']), axis = 1)
                    candidates['score3_type'] = "locality.token_set_ratio"
                    #Remove candidates with average score less than settings.min_score
                    candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                    candidates['recgroup_id'] = record['recgroup_id']
                    candidates['no_features'] = 1
                    #If there are any left, write to csv
                    if len(candidates) > 0:
                        candidates.to_csv('results/candidates_gadm_' + species_fname + '.csv', index=False, quoting = csv.QUOTE_ALL)
        #GNIS
        # if country == 'USA':
        #     allcandidates = pd.read_csv("gnis/gnis_USA.csv")
        #     logger1.info("No. of GNIS candidates: {}".format(len(allcandidates)))
        #     if len(allcandidates) > 0:
        #         #Iterate each record
        #         for index, record in records_g.iterrows():
        #             candidates = allcandidates.copy()
        #             candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
        #             candidates['candidate_id'] = candidates['candidate_id'].astype(str)
        #             ##################
        #             #Execute matches
        #             ##################
        #             #locality.partial_ratio
        #             candidates['score1'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name']), axis = 1)
        #             candidates['score1_type'] = "locality.partial_ratio"
        #             #stateprovince
        #             candidates['score2'] = candidates[candidates.stateprovince.notnull()].swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince']), axis = 1)
        #             candidates['score2_type'] = "stateprovince"
        #             #locality.token_set_ratio
        #             candidates['score3'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality'], row['name']), axis = 1)
        #             candidates['score3_type'] = "locality.token_set_ratio"
        #             #Remove candidates with average score less than settings.min_score
        #             candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
        #             candidates['recgroup_id'] = record['recgroup_id']
        #             candidates['no_features'] = 1
        #             #If there are any left, write to csv
        #             if len(candidates) > 0:
        #                 candidates['candidate_id'] = candidates['candidate_id'].astype(str)
        #                 candidates.to_csv('results/candidates_gnis_' + species_fname + '.csv', index=False, quoting = csv.QUOTE_ALL)
        #GNS - Not US
        if country != 'USA':
            if os.path.exists("gns/gns_{}.csv".format(country)):
                allcandidates = pd.read_csv("gns/gns_{}.csv".format(country))
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
                        candidates['score2'] = candidates[candidates.stateprovince.notnull()].swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince']), axis = 1)
                        candidates['score2_type'] = "stateprovince"
                        #locality.token_set_ratio
                        candidates['score3'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality'], row['name']), axis = 1)
                        candidates['score3_type'] = "locality.token_set_ratio"
                        #Remove candidates with average score less than settings.min_score
                        candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                        candidates['recgroup_id'] = record['recgroup_id']
                        candidates['no_features'] = 1
                        #If there are any left, write to csv
                        if len(candidates) > 0:
                            candidates.to_csv('results/candidates_gns_' + species_fname + '.csv', index=False, quoting = csv.QUOTE_ALL)
        #Lakes
        if os.path.exists("gl/gl_{}.csv".format(country)):
            allcandidates = pd.read_csv("gl/gl_{}.csv".format(country))
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
                    candidates['score2'] = candidates[candidates.stateprovince.notnull()].swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince']), axis = 1)
                    candidates['score2_type'] = "stateprovince"
                    #locality.token_set_ratio
                    candidates['score3'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality'], row['name']), axis = 1)
                    candidates['score3_type'] = "locality.token_set_ratio"
                    #Remove candidates with average score less than settings.min_score
                    candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                    candidates['recgroup_id'] = record['recgroup_id']
                    candidates['no_features'] = 1
                    #If there are any left, write to csv
                    if len(candidates) > 0:
                        candidates.to_csv('results/candidates_gl_' + species_fname + '.csv', index=False, quoting = csv.QUOTE_ALL)
        #Geonames
        if os.path.exists("geonames/geonames_{}.csv".format(country)):
            allcandidates = pd.read_csv("geonames/geonames_{}.csv".format(country))
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
                        candidates['score2'] = candidates[candidates.stateprovince.notnull()].swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince']), axis = 1)
                        candidates['score2_type'] = "stateprovince"
                        #locality.token_set_ratio
                        candidates['score3'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality'], row['name']), axis = 1)
                        candidates['score3_type'] = "locality.token_set_ratio"
                        #Remove candidates with average score less than settings.min_score
                        candidates = candidates[(candidates.score1 + candidates.score2 + candidates.score3) > (settings.min_score * 3)]
                        candidates['recgroup_id'] = record['recgroup_id']
                        candidates['no_features'] = 1
                        #If there are any left, write to csv
                        if len(candidates) > 0:
                            candidates.to_csv('results/candidates_geonames_' + species_fname + '.csv', index=False, quoting = csv.QUOTE_ALL)




#Get argument from HPC manager in range
listing = glob.glob('species/' + sys.argv[1] + "_*.csv")
for sp_file in listing:
    #Run parallel
    print(sp_file)
    run_species(sp_file)



sys.exit(0)
