#!/bin/bash
# 
# Update the BHL tables
#
# v 2021-08-02
#
# 

script_date=$(date +'%Y-%m-%d')

#Download dump
wget https://www.biodiversitylibrary.org/data/hosted/data.zip

unzip data.zip
rm data.zip


fromdos Data/creator.txt
fromdos Data/creatoridentifier.txt
fromdos Data/doi.txt
fromdos Data/item.txt
fromdos Data/page.txt
fromdos Data/pagename.txt
fromdos Data/part.txt
fromdos Data/partcreator.txt
fromdos Data/partidentifier.txt
fromdos Data/subject.txt
fromdos Data/title.txt
fromdos Data/titleidentifier.txt



#Store old tables
echo "Backing up BHL..."
echo ""
pg_dump -h localhost -U gisuser -t bhl_creator -t bhl_doi -t bhl_item -t bhl_page -t bhl_pagename -t bhl_part -t bhl_partcreator gis > bhl_$script_date.dump.sql
gzip bhl_$script_date.dump.sql &


#Turn datasource offline
#psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 'f' WHERE datasource_id = 'bhl';"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS bhl_creator CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS bhl_creatoridentifier CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS bhl_doi CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS bhl_item CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS bhl_page CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS bhl_pagename CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS bhl_part CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS bhl_partcreator CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS bhl_partidentifier CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS bhl_subject CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS bhl_title CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS bhl_titleidentifier CASCADE;"



#Remove header
cd Data
sed -i '1d' creator.txt
sed -i '1d' creatoridentifier.txt
sed -i '1d' doi.txt
sed -i '1d' item.txt
sed -i '1d' page.txt
sed -i '1d' pagename.txt
sed -i '1d' part.txt
sed -i '1d' partcreator.txt
sed -i '1d' partidentifier.txt
sed -i '1d' subject.txt
sed -i '1d' title.txt
sed -i '1d' titleidentifier.txt
cd ..


#Replace backslash
sed -i 's/\\//g' Data/item.txt
sed -i 's/\\//g' Data/pagename.txt
sed -i 's/\\//g' Data/title.txt

#Create tables and load
psql -U gisuser -h localhost gis < bhl_tables.sql

rm *.txt
