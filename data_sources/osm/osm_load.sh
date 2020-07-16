#!/bin/bash
#
#Get the OSM extracts from geofabrik.de and refresh the PostGIS database
# using osm2pgsql (https://wiki.openstreetmap.org/wiki/Osm2pgsql)
# 
# This version uses the country-level files to reduce the resources
#  needed for oms2pgsql.
#



#Columns to get the type
cols=(amenity barrier bridge building embankment harbour highway historic landuse leisure lock man_made military motorcar natural office place public_transport railway religion service shop sport surface toll tourism tunnel water waterway wetland wood)


mkdir done -p

#Download each file and load it to psql using osm2pgsql
for j in *.pbf; do
    echo ""
    echo "Working on file $j..."
    echo ""
    #Import pbf to postgres
    osm2pgsql --latlong --username gisuser --host localhost --database osm -C 16000 --create --slim --number-processes 8 --multi-geometry --verbose --flat-nodes /mnt/fastdisk/tmp/mycache.bin $j


    #Execute for each column
    for i in ${!cols[@]}; do
        echo "Working on column ${cols[$i]}..."
        psql -U gisuser -h localhost osm -c "CREATE INDEX osmplanet_${cols[$i]}_idx ON planet_osm_polygon USING BTREE(\"${cols[$i]}\") WHERE \"${cols[$i]}\" IS NOT NULL;"
        psql -U gisuser -h localhost osm -c "with data as ( 
                                                select 
                                                    osm_id as osm_id, 
                                                    name,
                                                    \"${cols[$i]}\",
                                                    way
                                                from 
                                                    planet_osm_polygon 
                                                where 
                                                    \"${cols[$i]}\" IS NOT NULL AND
                                                    name IS NOT NULL
                                            )
                                        INSERT INTO osm 
                                            (source_id, name, type, attributes, centroid, the_geom, the_geom_webmercator, gadm2, country, data_source) 
                                            select 
                                                d.osm_id::text, 
                                                d.name, 
                                                coalesce(replace(\"${cols[$i]}\", 'yes', NULL), \"${cols[$i]}\"),
                                                tags::hstore,
                                                st_centroid(st_multi(way)),
                                                st_makevalid(st_multi(way)) as the_geom,
                                                st_transform(st_makevalid(st_multi(way)), 3857) as the_geom_webmercator,
                                                g.name_2 || ', ' || g.name_1 || ', ' || g.name_0 as loc,
                                                g.name_0 as name_0,
                                                '$j'
                                            from 
                                                data d LEFT JOIN 
                                                    planet_osm_ways r ON 
                                                    (d.osm_id = r.id)
                                                LEFT JOIN 
                                                    gadm2 g ON 
                                                    ST_INTERSECTS(st_makevalid(st_multi(way)), g.the_geom_simp);"
        psql -U gisuser -h localhost osm -c "DROP INDEX osmplanet_${cols[$i]}_idx;"
        done
    mv $j done/
    done



