#!/usr/bin/env python3
#
# Export text from PostGIS layers
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
import os, logging, sys, locale, pycountry, glob, shutil, csv
import pandas as pd
from time import localtime, strftime
import psycopg2, psycopg2.extras
from psycopg2.extras import execute_batch


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
logger1 = logging.getLogger("export_text")





#Connect to the database
try:
    logger1.info("Connecting to the database.")
    conn = psycopg2.connect(host = settings.pg_host, database = settings.pg_db, user = settings.pg_user, connect_timeout = 60)
except:
    logger1.error("Could not connect to server.")
    sys.exit(1)
conn.autocommit = True
cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)



#GADM
print("GADM")
if os.path.exists('gadm'):
    shutil.rmtree('gadm')
os.makedirs('gadm')
countries_query = "SELECT name_0 AS country FROM gadm0"
cur.execute(countries_query)
logger1.debug(cur.query)
countries = cur.fetchall()
for country in countries:
    #Get records for the country
    gadm_query = """
            SELECT uid, name_1 AS name, name_1 AS stateprovince, 'gadm1' AS data_source FROM gadm1 WHERE name_0 = %(country)s 
            UNION 
            SELECT uid, varname_1 AS name, name_1 AS stateprovince, 'gadm1' AS data_source FROM gadm1 WHERE name_0 = %(country)s AND varname_1 IS NOT NULL
            UNION
            SELECT uid, name_2 AS name, name_1 || ', ' || name_0 AS stateprovince, 'gadm2' AS data_source FROM gadm2 WHERE name_0 = %(country)s 
            UNION 
            SELECT uid, varname_2 AS name, name_1 || ', ' || name_0 AS stateprovince, 'gadm2' AS data_source FROM gadm2 WHERE name_0 = %(country)s AND varname_2 IS NOT NULL
            UNION
            SELECT uid, name_3 AS name, name_2 || ', ' || name_1 || ', ' || name_0 AS stateprovince, 'gadm3' AS data_source FROM gadm3 WHERE name_0 = %(country)s 
            UNION 
            SELECT uid, varname_3 AS name, name_2 || ', ' || name_1 || ', ' || name_0 AS stateprovince, 'gadm3' AS data_source FROM gadm3 WHERE name_0 = %(country)s AND varname_3 IS NOT NULL
            UNION
            SELECT uid, name_4 AS name, name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0 AS stateprovince, 'gadm4' AS data_source FROM gadm4 WHERE name_0 = %(country)s 
            UNION 
            SELECT uid, varname_4 AS name, name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0 AS stateprovince, 'gadm4' AS data_source FROM gadm4 WHERE name_0 = %(country)s AND varname_4 IS NOT NULL
            UNION 
            SELECT uid, name_5 AS name, name_4 || ', ' || name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0 AS stateprovince, 'gadm5' AS data_source FROM gadm5 WHERE name_0 = %(country)s
                """
    cur.execute(gadm_query, {'country': country['country']})
    logger1.debug(cur.query)
    records = pd.DataFrame(cur.fetchall())
    print(country['country'])
    if pycountry.countries.get(name = country['country']) != None:
        records.to_csv("gadm/gadm_{}.csv".format(
                    pycountry.countries.get(name = country['country']).alpha_3
        ), index=False, quoting = csv.QUOTE_ALL)






#WDPA
print("WDPA")
if os.path.exists('wdpa'):
    shutil.rmtree('wdpa')
os.makedirs('wdpa')
countries_query = "SELECT DISTINCT unnest(string_to_array(parent_iso, ';')) AS country FROM wdpa_polygons"
cur.execute(countries_query)
logger1.debug(cur.query)
countries = cur.fetchall()
for country in countries:
    #Get records for the country
    query = """
            WITH data AS (
                SELECT uid, name, gadm2 AS stateprovince, 'wdpa_polygons' AS data_source FROM wdpa_polygons WHERE parent_iso LIKE '%{iso}%' AND lower(name) != 'unknown'
                UNION 
                SELECT uid, orig_name AS name, gadm2 AS stateprovince, 'wdpa_polygons' AS data_source FROM wdpa_polygons WHERE parent_iso LIKE '%{iso}%' AND lower(name) != 'unknown'
                UNION 
                SELECT uid, name, gadm2 AS stateprovince, 'wdpa_points' AS data_source FROM wdpa_points WHERE parent_iso LIKE '%{iso}%' AND lower(name) != 'unknown'
                UNION 
                SELECT uid, orig_name AS name, gadm2 AS stateprovince, 'wdpa_points' AS data_source FROM wdpa_points WHERE parent_iso LIKE '%{iso}%' AND lower(name) != 'unknown'
            )
            SELECT uid, name, stateprovince, data_source FROM data GROUP BY uid, name, stateprovince, data_source
                """
    cur.execute(query.format(iso = country['country']))
    logger1.debug(cur.query)
    records = pd.DataFrame(cur.fetchall())
    print(country['country'])
    records.to_csv("wdpa/wdpa_{}.csv".format(country['country']), index=False, quoting = csv.QUOTE_ALL)





#GNIS
print("GNIS")
if os.path.exists('gnis'):
    shutil.rmtree('gnis')
os.makedirs('gnis')
cur.execute("SELECT uid, full_name_nd_ro AS name, gadm2 AS stateprovince, 'gns' AS data_source FROM gns")
logger1.debug(cur.query)
records = pd.DataFrame(cur.fetchall())
records.to_csv("gnis/gnis_USA.csv", index=False, quoting = csv.QUOTE_ALL)





#GNS - Not US
print("GNS")
if os.path.exists('gns'):
    shutil.rmtree('gns')
os.makedirs('gns')
countries_query = "SELECT DISTINCT unnest(string_to_array(cc1, ',')) AS country FROM gns"
cur.execute(countries_query)
logger1.debug(cur.query)
countries = cur.fetchall()
for country in countries:
    #Get records for the country
    gadm_query = """SELECT uid, full_name_nd_ro AS name, gadm2 AS stateprovince, 'gns' AS data_source FROM gns WHERE cc1 LIKE '%{countrycode}%'"""
    cur.execute(gadm_query.format(countrycode = country['country']))
    logger1.debug(cur.query)
    records = pd.DataFrame(cur.fetchall())
    print(country['country'])
    if pycountry.countries.get(alpha_2 = country['country']) != None:
        records.to_csv("gns/gns_{}.csv".format(
                    pycountry.countries.get(alpha_2 = country['country']).alpha_3
        ), index=False, quoting = csv.QUOTE_ALL)




#Global Lakes
print("Global Lakes")
if os.path.exists('gl'):
    shutil.rmtree('gl')
os.makedirs('gl')
countries_query = "SELECT DISTINCT country FROM global_lakes"
cur.execute(countries_query)
logger1.debug(cur.query)
countries = cur.fetchall()
for country in countries:
    #Get records for the country
    gadm_query = "SELECT uid, lake_name AS name, gadm2 AS stateprovince, 'global_lakes' AS data_source FROM global_lakes WHERE country = %(country)s"
    cur.execute(gadm_query, {'country': country['country']})
    logger1.debug(cur.query)
    records = pd.DataFrame(cur.fetchall())
    print(country['country'])
    if pycountry.countries.get(name = country['country']) != None:
        records.to_csv("gl/gl_{}.csv".format(
                    pycountry.countries.get(name = country['country']).alpha_3
        ), index=False, quoting = csv.QUOTE_ALL)





#Geonames
print("Geonames")
if os.path.exists('geonames'):
    shutil.rmtree('geonames')
os.makedirs('geonames')
countries_query = "SELECT DISTINCT country_code AS country FROM geonames where country_code != ''"
cur.execute(countries_query)
logger1.debug(cur.query)
countries = cur.fetchall()
for country in countries:
    #Get records for the country
    query = """
             WITH data AS (
                SELECT uid, name, gadm2 AS stateprovince, 'geonames' AS data_source FROM geonames WHERE country_code = %(country)s
                UNION
                SELECT uid, unnest(string_to_array(alternatenames, ',')) AS name, gadm2 AS stateprovince, 'geonames' AS data_source FROM geonames WHERE country_code = %(country)s
                )
            SELECT uid, name, stateprovince, data_source FROM data GROUP BY uid, name, stateprovince, data_source
                """
    cur.execute(query, {'country': country['country']})
    logger1.debug(cur.query)
    records = pd.DataFrame(cur.fetchall())
    print(country['country'])
    if pycountry.countries.get(alpha_2 = country['country']) != None:
        records.to_csv("geonames/geonames_{}.csv".format(
                    pycountry.countries.get(alpha_2 = country['country']).alpha_3
        ), index=False, quoting = csv.QUOTE_ALL)





sys.exit(0)
