#!/bin/bash

#Today's date
script_date=$(date +'%Y-%m-%d')

#Download dump
wget https://geonames.usgs.gov/docs/stategaz/NationalFile.zip

unzip NationalFile.zip

#Turn datasource offline
psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 'f' WHERE datasource_id = 'gnis';"


#Store old tables
echo "Backing up gnis..."
echo ""
pg_dump -h localhost -U gisuser -t gnis gis > gnis_$script_date.dump.sql
gzip gnis_$script_date.dump.sql &

psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS gnis CASCADE;"

#Create table
psql -U gisuser -h localhost gis -c "CREATE TABLE gnis (
    feature_id int,
    feature_name text,
    feature_class text,
    state_alpha text,
    state_numeric int,
    county_name text,
    county_numeric int,
    primary_lat_dms text,
    prim_long_dms text,
    prim_lat_dec float,
    prim_long_dec float,
    source_lat_dms text,
    source_long_dms text,
    source_lat_dec text,
    source_long_dec text,
    elev_in_m int,
    elev_in_ft int,
    map_name text,
    date_created text,
    date_edited text
    );"


datafile=`ls NationalFile_*.txt`

psql -U gisuser -h localhost gis -c "\copy gnis from '$datafile' DELIMITER '|' CSV HEADER;"

psql -U gisuser -h localhost gis < gnis_post.sql

psql -U gisuser -h localhost gis -c "WITH data AS (SELECT count(*) as no_features FROM gnis) UPDATE data_sources SET no_features = data.no_features FROM data WHERE datasource_id = 'gnis';"

psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 't', source_date = '$script_date', no_features = w.no_feats FROM (select count(*) as no_feats from gnis) w WHERE datasource_id = 'gnis';"

rm *.zip
rm *.txt
