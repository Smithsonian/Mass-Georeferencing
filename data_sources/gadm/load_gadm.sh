#!/bin/bash
# 
# Convert GADM shapefiles to Postgres and write them to the database.
# Download the lelevs shapfile and unzip before running script. 
# Currently: 
#    wget https://biogeo.ucdavis.edu/data/gadm3.6/gadm36_levels_shp.zip
# 
# Prefix: gadm36
# 
# v 2019-08-06
#

psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 'f' WHERE datasource_id = 'gadm';"

script_date=$(date +'%Y-%m-%d')

#Store old tables
echo "Backing up gadm0..."
echo ""
pg_dump -h localhost -U gisuser -t gadm0 gis > gadm0_$script_date.dump.sql
gzip gadm0_$script_date.dump.sql &

echo "Backing up gadm1..."
echo ""
pg_dump -h localhost -U gisuser -t gadm1 gis > gadm1_$script_date.dump.sql
gzip gadm1_$script_date.dump.sql &

echo "Backing up gadm2..."
echo ""
pg_dump -h localhost -U gisuser -t gadm2 gis > gadm2_$script_date.dump.sql
gzip gadm2_$script_date.dump.sql &

echo "Backing up gadm3..."
echo ""
pg_dump -h localhost -U gisuser -t gadm3 gis > gadm3_$script_date.dump.sql
gzip gadm3_$script_date.dump.sql &

echo "Backing up gadm4..."
echo ""
pg_dump -h localhost -U gisuser -t gadm4 gis > gadm4_$script_date.dump.sql
gzip gadm4_$script_date.dump.sql &

echo "Backing up gadm5..."
echo ""
pg_dump -h localhost -U gisuser -t gadm5 gis > gadm5_$script_date.dump.sql
gzip gadm5_$script_date.dump.sql &

rm license.txt

#level0
psql -U gisuser -h localhost -p 5432 gis -c "DROP TABLE IF EXISTS gadm0 CASCADE;"
shp2pgsql -g the_geom -D gadm36_0.shp gadm0 > gadm0.sql
psql -U gisuser -h localhost -p 5432 gis < gadm0.sql
rm gadm0.sql
rm gadm36_0.*

#level1
psql -U gisuser -h localhost -p 5432 gis -c "DROP TABLE IF EXISTS gadm1 CASCADE;"
shp2pgsql -g the_geom -D gadm36_1.shp gadm1 > gadm1.sql
psql -U gisuser -h localhost -p 5432 gis < gadm1.sql
rm gadm1.sql
rm gadm36_1.*

#level2
psql -U gisuser -h localhost -p 5432 gis -c "DROP TABLE IF EXISTS gadm2 CASCADE;"
shp2pgsql -g the_geom -D gadm36_2.shp gadm2 > gadm2.sql
psql -U gisuser -h localhost -p 5432 gis < gadm2.sql
rm gadm2.sql
rm gadm36_2.*

#level3
psql -U gisuser -h localhost -p 5432 gis -c "DROP TABLE IF EXISTS gadm3 CASCADE;"
shp2pgsql -g the_geom -D gadm36_3.shp gadm3 > gadm3.sql
psql -U gisuser -h localhost -p 5432 gis < gadm3.sql
rm gadm3.sql
rm gadm36_3.*

#level4
psql -U gisuser -h localhost -p 5432 gis -c "DROP TABLE IF EXISTS gadm4 CASCADE;"
shp2pgsql -g the_geom -D gadm36_4.shp gadm4 > gadm4.sql
psql -U gisuser -h localhost -p 5432 gis < gadm4.sql
rm gadm4.sql
rm gadm36_4.*

#level5
psql -U gisuser -h localhost -p 5432 gis -c "DROP TABLE IF EXISTS gadm5 CASCADE;"
shp2pgsql -g the_geom -D gadm36_5.shp gadm5 > gadm5.sql
psql -U gisuser -h localhost -p 5432 gis < gadm5.sql
rm gadm5.sql
rm gadm36_5.*


#Add indices and run data checks
psql -U gisuser -h localhost -p 5432 gis < gadm_post.sql

psql -U gisuser -h localhost gis -c "WITH data AS (SELECT count(*) as no_features FROM gadm0  UNION SELECT count(*) as no_features FROM gadm1 UNION SELECT count(*) as no_features FROM gadm2 UNION SELECT count(*) as no_features FROM gadm3 UNION SELECT count(*) as no_features FROM gadm4 UNION SELECT count(*) as no_features FROM gadm5) UPDATE data_sources SET no_features = data.no_features FROM data WHERE datasource_id = 'gadm';"

psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 't', source_date = '$script_date' WHERE datasource_id = 'gadm';"
