#!/usr/bin/env python3
#
# Mass Georeferencing script
# to convert messy country name fields to countrycode arrays
#
# 2020-04-14
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
from pyfiglet import Figlet
import psycopg2, psycopg2.extras
from psycopg2.extras import execute_batch


#Get settings
import settings



#Script variables
script_title = "Cleanup Countrycode"
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
cur.execute("SELECT countryverbatim, TRIM(regexp_replace(countryverbatim, '[^a-zA-Z \\\\]', '', 'g')) as country FROM mg_occurrences WHERE countrycode IS NULL GROUP BY countryverbatim")
logger1.debug(cur.query)
countries = cur.fetchall()
for country in countries:
    logger1.info("Country: {}".format(country['country']))
    if country['country'] == None:
        #Empty, go to next
        continue
    else:
        countryname = country['country'].lower().capitalize()
        countryname_lower = country['country'].lower()
        if pycountry.countries.get(name = countryname) != None:
            #Found name
            cur.execute("UPDATE mg_occurrences SET countrycode = '{}' WHERE countryverbatim = '{}'".format(pycountry.countries.get(name = countryname).alpha_2, country['countryverbatim'].replace("'", "''")))
            logger1.info(cur.query)
        elif pycountry.countries.get(common_name = countryname) != None:
            #Found name using common_name
            cur.execute("UPDATE mg_occurrences SET countrycode = '{}' WHERE countryverbatim = '{}'".format(pycountry.countries.get(common_name = countryname).alpha_2, country['countryverbatim'].replace("'", "''")))
            logger1.info(cur.query)
        else:
            #Split names and try to find matches
            country_split = countryname_lower.split("/")
            if len(country_split) == 1:
                #Try another separator
                country_split = countryname_lower.split(" or ")
            if len(country_split) == 1:
                #Try another separator
                country_split = countryname_lower.split(" and ")
            country_codes = []
            for c1 in country_split:
                c2 = c1.capitalize().strip()
                if pycountry.countries.get(name = c2) != None:
                    country_codes.append(pycountry.countries.get(name = c2).alpha_2)
                elif pycountry.countries.get(common_name = c2) != None:
                    country_codes.append(pycountry.countries.get(common_name = c2).alpha_2)
            country_codes = ','.join(country_codes)
            if country_codes != "":
                cur.execute("UPDATE mg_occurrences SET countrycode = '{}' WHERE countryverbatim = '{}'".format(country_codes, country['countryverbatim'].replace("'", "''")))
                logger1.info(cur.query)



#Compress logs
script_dir = os.getcwd()
os.chdir('{}/logs'.format(script_dir))
for file in glob.glob('*.log'):
    subprocess.run(["zip", "{}.zip".format(file), file])
    os.remove(file)
os.chdir(script_dir)


sys.exit(0)
