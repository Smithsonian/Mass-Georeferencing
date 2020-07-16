#!/bin/bash
#
# Download shapefile from https://mrdata.usgs.gov/geology/state/
#
#

#Today's date
script_date=$(date +'%Y-%m-%d')

#Reproject to wgs84 before loading


#Turn datasource offline
psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 'f' WHERE datasource_id = 'usgs_geologicmaps';"


#Store old tables
echo "Backing up usgs_geology..."
echo ""
pg_dump -h localhost -U gisuser -t usgs_geology gis > usgs_geology_$script_date.dump.sql
gzip usgs_geology_$script_date.dump.sql &

psql -U gisuser -h localhost gis -c "DROP TABLE usgs_geology CASCADE;"

#Convert shapefiles to PostGIS format
shp2pgsql -g the_geom -D usgs_geology.shp usgs_geology > usgs_geology.sql

#Load PostGIS files to database
psql -U gisuser -h localhost gis < usgs_geology.sql

#indices and new columns
psql -U gisuser -h localhost gis < usgs_post.sql

psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 't', source_date = '$script_date', no_features = w.no_feats FROM (select count(*) as no_feats from usgs_geology) w WHERE datasource_id = 'usgs_geology';"



#del files
cd ..
rm -r USGS_SGMC_Shapefiles
