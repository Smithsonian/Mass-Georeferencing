#!/bin/bash
# 
# Update the gns table
#
# v 2020-02-18
#

script_date=$(date +'%Y-%m-%d')

#Download dataset from http://geonames.nga.mil/gns/html/namefiles.html
# Example:
#   wget http://geonames.nga.mil/gns/html/cntyfile/geonames_20200217.zip
#   unzip geonames_20200217.zip

#Remove first line
sed -i '1d' Countries.txt

#Store old tables
echo "Backing up GNS..."
echo ""
pg_dump -h localhost -U gisuser -t gns gis > gns_$script_date.dump.sql
gzip gns_$script_date.dump.sql &


#Turn datasource offline
psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 'f' WHERE datasource_id = 'gns';"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS gns CASCADE;"

#Create table
psql -U gisuser -h localhost gis < gns.sql

psql -U gisuser -h localhost gis -c "WITH data AS (SELECT count(*) as no_features FROM gns) UPDATE data_sources SET no_features = data.no_features FROM data WHERE datasource_id = 'gns';"

psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 't', source_date = '$script_date' WHERE datasource_id = 'gns';"

rm geonames_*.zip
rm Countries.txt
