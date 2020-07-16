#!/usr/bin/env python3
#
# Add country to OSM entries
# 2020-04-30
# 
# Digitization Program Office, 
# Office of the Chief Information Officer,
# Smithsonian Institution
# https://dpo.si.edu
#
#Import modules
import os, logging, sys, locale, uuid, subprocess
import pandas as pd
from time import localtime, strftime
from pyfiglet import Figlet
import psycopg2, psycopg2.extras
from psycopg2.extras import execute_batch


#Get settings
import settings



#Script variables
script_title = "OSM add country"
subtitle = "Digitization Program Office\nOffice of the Chief Information Officer\nSmithsonian Institution\nhttps://dpo.si.edu"
ver = "0.1"
repo = "https://github.com/Smithsonian/DPO-GIS"
lic = "Available under the Apache 2.0 License"


# Set locale to UTF-8
locale.setlocale(locale.LC_ALL, 'en_US.utf8')



#print script title and info
f = Figlet(font='slant')
print("\n")
print (f.renderText(script_title))
print("{subtitle}\n\n{repo}\n{lic}\n\nver. {ver}".format(subtitle = subtitle, ver = ver, repo = repo, lic = lic))




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
logger1 = logging.getLogger("add_country")





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
cur.execute("SELECT uid, name_0 from gadm0")
logger1.debug(cur.query)
countries = cur.fetchall()
for country in countries:
    logger1.info("country: {}".format(country['name_0']))
    for i in range(15000):
        ii = i * 100000
        #Get records for the country
        cur.execute("""WITH records as (
                                SELECT 
                                    uid,
                                    the_geom
                                FROM 
                                    osm
                                ORDER BY uid
                                    LIMIT 1000
                                    offset {i}
                            ),

                            data AS (
                                SELECT 
                                    w.uid,
                                    g.name_0 as loc
                                FROM 
                                    records w,
                                    gadm0 g
                                WHERE 
                                    ST_INTERSECTS(w.the_geom, g.the_geom) AND
                                    g.name_0 = '{country}'
                                    )
                            UPDATE osm g SET country = d.loc FROM data d WHERE g.uid = d.uid;
""".format(i = ii, country = country['uid']))
        logger1.info(cur.query)



#Compress logs
script_dir = os.getcwd()
os.chdir('{}/logs'.format(script_dir))
for file in glob.glob('*.log'):
    subprocess.run(["zip", "{}.zip".format(file), file])
    os.remove(file)
os.chdir(script_dir)


sys.exit(0)
