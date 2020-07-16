#!/bin/bash
#
# Download shapefiles from https://www.protectedplanet.net/
#
# wget -O wdpa.zip https://www.protectedplanet.net/downloads/WDPA_[DATE]?type=shapefile 
#
    
#Today's date
script_date=$(date +'%Y-%m-%d')

unzip wdpa.zip


mkdir 0
mkdir 1
mkdir 2

mv WDPA_Jul2020-shapefile0.zip 0/
mv WDPA_Jul2020-shapefile1.zip 1/
mv WDPA_Jul2020-shapefile2.zip 2/

cd 0
unzip WDPA_Jul2020-shapefile0.zip
cd ../1
unzip WDPA_Jul2020-shapefile1.zip
cd ../2
unzip WDPA_Jul2020-shapefile2.zip
cd ..



#Turn datasource offline
psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 'f' WHERE datasource_id = 'wdpa_polygons';"
psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 'f' WHERE datasource_id = 'wdpa_points';"


#Store old tables
echo "Backing up wdpa_points..."
echo ""
pg_dump -h localhost -U gisuser -t wdpa_points gis > wdpa_points_$script_date.dump.sql
gzip wdpa_points_$script_date.dump.sql

echo "Backing up wdpa_polygons..."
echo ""
pg_dump -h localhost -U gisuser -t wdpa_polygons gis > wdpa_polygons_$script_date.dump.sql
gzip wdpa_polygons_$script_date.dump.sql &

psql -U gisuser -h localhost gis -c "DROP TABLE wdpa_points CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE wdpa_polygons CASCADE;"
# psql -U gisuser -h localhost gis -c "DELETE FROM wdpa_points;"
# psql -U gisuser -h localhost gis -c "DELETE FROM wdpa_polygons;"


#Convert shapefiles to PostGIS format
pointshp=`ls 0/WDPA*shapefile-points.shp`
shp2pgsql -g the_geom -D $pointshp wdpa_points > wdpa_points.sql
polyshp=`ls 0/WDPA*shapefile-polygons.shp`
shp2pgsql -g the_geom -D $polyshp wdpa_polygons > wdpa_polygons.sql
#Load PostGIS files to database
psql -U gisuser -h localhost gis < wdpa_points.sql
psql -U gisuser -h localhost gis < wdpa_polygons.sql
rm wdpa_points.sql
rm wdpa_polygons.sql

#4195

pointshp=`ls 1/WDPA*shapefile-points.shp`
shp2pgsql -g the_geom -D -a $pointshp wdpa_points > wdpa_points.sql
polyshp=`ls 1/WDPA*shapefile-polygons.shp`
shp2pgsql -g the_geom -D -a $polyshp wdpa_polygons > wdpa_polygons.sql
#Load PostGIS files to database
psql -U gisuser -h localhost gis < wdpa_points.sql
psql -U gisuser -h localhost gis < wdpa_polygons.sql
rm wdpa_points.sql
rm wdpa_polygons.sql

pointshp=`ls 2/WDPA*shapefile-points.shp`
shp2pgsql -g the_geom -D -a $pointshp wdpa_points > wdpa_points.sql
polyshp=`ls 2/WDPA*shapefile-polygons.shp`
shp2pgsql -g the_geom -D -a $polyshp wdpa_polygons > wdpa_polygons.sql
#Load PostGIS files to database
psql -U gisuser -h localhost gis < wdpa_points.sql
psql -U gisuser -h localhost gis < wdpa_polygons.sql
rm wdpa_points.sql
rm wdpa_polygons.sql



#indices and new columns
psql -U gisuser -h localhost gis < wdpa_post.sql

psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 't', source_date = '$script_date', no_features = w.no_feats FROM (select count(*) as no_feats from wdpa_polygons) w WHERE datasource_id = 'wdpa_polygons';"
psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 't', source_date = '$script_date', no_features = w.no_feats FROM (select count(*) as no_feats from wdpa_points) w WHERE datasource_id = 'wdpa_points';"



#del files
rm wdpa.zip
rm -r Res*
rm -r Recursos*
rm -r 0
rm -r 1
rm -r 2
