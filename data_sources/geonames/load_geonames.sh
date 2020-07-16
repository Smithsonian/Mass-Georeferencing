#!/bin/bash
# 
# Update the geonames tables
#
# v 2019-08-06
#

script_date=$(date +'%Y-%m-%d')

#Download dump
wget http://download.geonames.org/export/dump/allCountries.zip

unzip allCountries.zip


#Store old tables
echo "Backing up geonames..."
echo ""
pg_dump -h localhost -U gisuser -t geonames gis > geonames_$script_date.dump.sql
gzip geonames_$script_date.dump.sql &

echo "Backing up geonames_alt..."
echo ""
pg_dump -h localhost -U gisuser -t geonames_alt gis > geonames_alt_$script_date.dump.sql
gzip geonames_alt_$script_date.dump.sql &


#Turn datasource offline
psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 'f' WHERE datasource_id = 'geonames';"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS geonames CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS geonames_alt CASCADE;"

#Create table
psql -U gisuser -h localhost gis < geonames_post.sql

psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 't', source_date = '$script_date', no_features = w.no_feats FROM (select count(*) as no_feats from geonames) w WHERE datasource_id = 'geonames';"

rm allCountries.zip
rm allCountries.txt
