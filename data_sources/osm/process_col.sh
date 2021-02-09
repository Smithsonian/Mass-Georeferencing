#!/bin/bash
#

echo "Working on column $1..."
psql -U gisuser -h localhost osm -c "CREATE INDEX osmplanet_$1_idx ON planet_osm_polygon USING BTREE(\"$1\") WHERE \"$1\" IS NOT NULL;"
psql -U gisuser -h localhost osm -c "with data as ( 
                                        select 
                                            osm_id as osm_id, 
                                            name,
                                            \"$1\",
                                            way
                                        from 
                                            planet_osm_polygon 
                                        where 
                                            \"$1\" IS NOT NULL AND
                                            name IS NOT NULL
                                    )
                                INSERT INTO osm 
                                    (source_id, name, type, attributes, centroid, the_geom, the_geom_webmercator, gadm2, country, data_source) 
                                    select 
                                        d.osm_id::text, 
                                        d.name, 
                                        coalesce(replace(\"$1\", 'yes', NULL), \"$1\"),
                                        tags::hstore,
                                        st_centroid(st_multi(way)),
                                        st_makevalid(st_multi(way)) as the_geom,
                                        st_transform(st_makevalid(st_multi(way)), 3857) as the_geom_webmercator,
                                        g.name_2 || ', ' || g.name_1 || ', ' || g.name_0 as loc,
                                        g.name_0 as name_0,
                                        '$2'
                                    from 
                                        data d LEFT JOIN 
                                            planet_osm_ways r ON 
                                            (d.osm_id = r.id)
                                        LEFT JOIN 
                                            gadm2 g ON 
                                            ST_INTERSECTS(st_makevalid(st_multi(way)), g.the_geom_simp);"
psql -U gisuser -h localhost osm -c "DROP INDEX osmplanet_$1_idx;"

