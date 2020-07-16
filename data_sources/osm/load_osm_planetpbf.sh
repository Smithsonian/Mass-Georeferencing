#!/bin/bash
#
#Get the OSM extracts from geofabrik.de and refresh the PostGIS database
# using osm2pgsql (https://wiki.openstreetmap.org/wiki/Osm2pgsql)
#

#Today's date
date +'%m/%d/%Y'
script_date=$(date +'%Y-%m-%d')

#Turn datasource offline
psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 'f' WHERE datasource_id = 'osm';"

#Delete tables in database
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS planet_osm_line CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS planet_osm_nodes CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS planet_osm_point CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS planet_osm_polygon CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS planet_osm_rels CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS planet_osm_roads CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS planet_osm_ways CASCADE;"


#Download planet pbf
echo ""
echo "Downloading .pbf file..."
echo ""

wget -a osm_$script_date.log https://ftp.osuosl.org/pub/openstreetmap/pbf/planet-latest.osm.pbf

echo ""
echo "Loading planet..."
echo ""
osm2pgsql --latlong --slim --username gisuser --host localhost --database osm --multi-geometry --verbose planet-latest.osm.pbf >> osm_$script_date.log


#Set back online and update date
psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 't', source_date = '$script_date' WHERE source_id = 'osm';"
