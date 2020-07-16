#!/bin/bash
#
# Load the polygons from the OSM Planet data dump to the gis database.
#
# First, download the latest planet data dump from:
#    wget https://ftpmirror.your.org/pub/openstreetmap/pbf/planet-latest.osm.pbf
# 
# Load the osm planet dump to postgres using osm2pgsql:
#    osm2pgsql --latlong --slim --create -C 6000 --number-processes 6 --flat-nodes /mnt/fastdisk/data/osm_nodes/planet.nodes --username gisuser --host localhost --database gis --multi-geometry --verbose planet-latest.osm.pbf
#
# This takes a while, probably a couple of days.
# 
# Delete the planet file, its about 50GB:
#    rm planet-latest.osm.pbf
# 


#Today's date
script_date=$(date +'%Y-%m-%d')


#Delete unused tables
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS planet_osm_line CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS planet_osm_nodes CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS planet_osm_point CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS planet_osm_rels CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS planet_osm_roads CASCADE;"

#Clean up table
psql -U gisuser -h localhost gis -c "DELETE FROM planet_osm_polygon WHERE name IS NULL;"
psql -U gisuser -h localhost gis -c "VACUUM planet_osm_polygon;"

#Turn datasource offline
psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 'f' WHERE datasource_id = 'osm';"

#Drop indices before bulk loading
psql -U gisuser -h localhost gis -c "DROP INDEX IF EXISTS osm_name_idx;"
psql -U gisuser -h localhost gis -c "DROP INDEX IF EXISTS osm_thegeom_idx;"
psql -U gisuser -h localhost gis -c "DROP INDEX IF EXISTS osm_thegeomw_idx;"
psql -U gisuser -h localhost gis -c "DROP INDEX IF EXISTS osm_centroid_idx;"

#Empty table
psql -U gisuser -h localhost gis -c "TRUNCATE osm;"
psql -U gisuser -h localhost gis -c "VACUUM osm;"

psql -U gisuser -h localhost gis -c "UPDATE planet_osm_polygon SET osm_id = abs(osm_id) WHERE osm_id < 0;"
psql -U gisuser -h localhost gis -c "CREATE INDEX planet_osm_polygon_osmid_idx ON planet_osm_polygon USING BTREE(osm_id);"
psql -U gisuser -h localhost gis -c "CREATE INDEX planet_osm_ways_id_idx ON planet_osm_ways USING BTREE(id);"


#Columns to get the type
cols=(amenity barrier bridge building embankment harbour highway historic landuse leisure lock man_made military motorcar natural office place public_transport railway religion service shop sport surface toll tourism tunnel water waterway wetland wood)

#Execute for each column
for i in ${!cols[@]}; do
    echo "Working on column ${cols[$i]}..."
    psql -U gisuser -h localhost gis -c "CREATE INDEX osmplanet_${cols[$i]}_idx ON planet_osm_polygon USING BTREE(${cols[$i]}) WHERE ${cols[$i]} IS NOT NULL;"
    #Loop in 100k blocks. Adjust max below as needed.
    for j in {0..10000000..100000}; do
        jj=`expr $j + 100000`
        psql -U gisuser -h localhost gis -c "with data as ( 
                                                select 
                                                    osm_id as osm_id, 
                                                    name,
                                                    ${cols[$i]},
                                                    way
                                                from 
                                                    planet_osm_polygon 
                                                where 
                                                    ${cols[$i]} IS NOT NULL AND
                                                    osm_id >= $j AND
                                                    osm_id < $jj 
                                            )
                                        INSERT INTO osm 
                                            (source_id, name, type, attributes, centroid, the_geom, the_geom_webmercator) 
                                            select 
                                                d.osm_id::text, 
                                                d.name, 
                                                coalesce(replace(${cols[$i]}, 'yes', NULL), ${cols[$i]}),
                                                tags::hstore,
                                                st_centroid(st_multi(way)),
                                                st_multi(way) as the_geom,
                                                st_transform(st_multi(way), 3857) as the_geom_webmercator
                                            from 
                                                data d LEFT JOIN 
                                                    planet_osm_ways r ON 
                                                    (d.osm_id = r.id);"
    done
    psql -U gisuser -h localhost gis -c "DROP INDEX osmplanet_${cols[$i]}_idx;"
done


#Recreate indices
psql -U gisuser -h localhost gis -c "CREATE INDEX osm_name_idx ON osm USING BTREE(name);"
psql -U gisuser -h localhost gis -c "CREATE INDEX osm_thegeom_idx ON osm USING GIST(the_geom);"
psql -U gisuser -h localhost gis -c "CREATE INDEX osm_thegeomw_idx ON osm USING GIST(the_geom_webmercator);"
psql -U gisuser -h localhost gis -c "CREATE INDEX osm_centroid_idx ON osm USING GIST(centroid);"

#Turn datasource online
psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 't', source_date = '$script_date' WHERE datasource_id = 'osm';"

#Delete last tables
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS planet_osm_polygon CASCADE;"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS planet_osm_ways CASCADE;"
