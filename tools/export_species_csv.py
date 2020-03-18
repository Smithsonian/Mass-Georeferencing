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

logfile_name = 'logs/spp_{}.log'.format(current_time)
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
logger1 = logging.getLogger("export_spp")





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
cur.execute('SELECT * FROM mg_collex WHERE collex_id = %s', (settings.collex_id,))
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





if os.path.exists('species'):
    shutil.rmtree('species')
os.makedirs('species')


i = 1
#Loop the species
for sciname in scinames:
    logger1.info("sciname: {}".format(sciname['species']))
    #Get countrycodes for the species
    cur.execute("SELECT countrycode FROM mg_occurrences WHERE species = %s AND decimallatitude IS NULL AND countrycode IS NOT NULL AND lower(locality) <> ANY(ARRAY['none', 'unknown', 'no locality data']) GROUP BY countrycode", (sciname['species'],))
    logger1.debug(cur.query)
    countries = cur.fetchall()
    #Records with countrycode
    for country in countries:
        #Get records for the country
        cur.execute("SELECT locality, stateprovince, countrycode, recordedby, kingdom, phylum, class, _order, family, genus, species, count(*) AS no_records FROM mg_occurrences WHERE species = %(species)s AND countrycode = %(countrycode)s AND decimallatitude IS NULL AND lower(locality) <> ANY(ARRAY['none', 'unknown', 'no locality data', 'no further locality data']) GROUP BY locality, stateprovince, countrycode, recordedby, kingdom, phylum, class, _order, family, genus, species", {'species': sciname['species'], 'countrycode': country['countrycode']})
        logger1.debug(cur.query)
        records = pd.DataFrame(cur.fetchall())
        if pycountry.countries.get(alpha_2 = country['countrycode']) != None:
            records.to_csv("species/{}_{}_{}.csv".format(i, sciname['species'].replace(" ", "_"), pycountry.countries.get(alpha_2 = country['countrycode']).alpha_3), index=False, quoting = csv.QUOTE_ALL)
            i += 1


print("Top i: {}".format(i-1))


sys.exit(0)
