#!/bin/bash
# 
# Update the BHL tables
#
# v 2019-10-15
#
# 

script_date=$(date +'%Y-%m-%d')

#Download dump
wget https://www.biodiversitylibrary.org/data/data.zip

unzip data.zip
rm data.zip

#Tables
# creator.txt
# doi.txt
# item.txt
# page.txt
# pagename.txt
# part.txt
# partcreator.txt

# fromdos Data/creator.txt
# fromdos Data/doi.txt
# fromdos Data/item.txt
# fromdos Data/page.txt
# fromdos Data/pagename.txt
# fromdos Data/part.txt
# fromdos Data/partcreator.txt


#Store old tables
echo "Backing up BHL..."
echo ""
pg_dump -h localhost -U gisuser -t bhl_creator -t bhl_doi -t bhl_item -t bhl_page -t bhl_pagename -t bhl_part -t bhl_partcreator gis > bhl_$script_date.dump.sql
gzip bhl_$script_date.dump.sql &


#Turn datasource offline
#psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 'f' WHERE datasource_id = 'bhl';"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS bhl_creator CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS bhl_doi CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS bhl_item CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS bhl_page CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS bhl_pagename CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS bhl_part CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS bhl_partcreator CASCADE;"


#Remove header
cd Data
sed -i '1d' creator.txt
sed -i '1d' doi.txt
sed -i '1d' item.txt
sed -i '1d' page.txt
sed -i '1d' pagename.txt
sed -i '1d' part.txt
sed -i '1d' partcreator.txt
cd ..


#Create tables and load
psql -U gisuser -h localhost gis < bhl_tables.sql

rm *.txt
