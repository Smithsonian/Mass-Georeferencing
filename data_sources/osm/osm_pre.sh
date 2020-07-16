#!/bin/bash
#
#Get the OSM extracts from geofabrik.de and refresh the PostGIS database
# using osm2pgsql (https://wiki.openstreetmap.org/wiki/Osm2pgsql)
# 


#Delete unused tables
psql -U gisuser -h localhost osm -c "DROP TABLE IF EXISTS planet_osm_line CASCADE;"
psql -U gisuser -h localhost osm -c "DROP TABLE IF EXISTS planet_osm_nodes CASCADE;"
psql -U gisuser -h localhost osm -c "DROP TABLE IF EXISTS planet_osm_point CASCADE;"
psql -U gisuser -h localhost osm -c "DROP TABLE IF EXISTS planet_osm_rels CASCADE;"
psql -U gisuser -h localhost osm -c "DROP TABLE IF EXISTS planet_osm_roads CASCADE;"
psql -U gisuser -h localhost osm -c "DROP TABLE IF EXISTS planet_osm_polygon CASCADE;"
psql -U gisuser -h localhost osm -c "DROP TABLE IF EXISTS planet_osm_ways CASCADE;"


#Turn datasource offline
psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 'f' WHERE datasource_id = 'osm';"

#Drop indices before bulk loading
psql -U gisuser -h localhost osm -c "DROP INDEX IF EXISTS osm_name_idx;"
psql -U gisuser -h localhost osm -c "DROP INDEX IF EXISTS osm_thegeom_idx;"
psql -U gisuser -h localhost osm -c "DROP INDEX IF EXISTS osm_thegeomw_idx;"
psql -U gisuser -h localhost osm -c "DROP INDEX IF EXISTS osm_centroid_idx;"

#Empty table
psql -U gisuser -h localhost osm -c "TRUNCATE osm;"
psql -U gisuser -h localhost osm -c "VACUUM osm;"


