SELECT 
        ST_AsGeoJSON(the_geom) as the_geom,
        null as min_bound_radius_m,
        null as the_geom_extent,
        uid,
        name,
        type,
        null as parent,
        round(st_x(the_geom)::numeric, 5) as longitude,
        round(st_y(the_geom)::numeric, 5) as latitude,
        round(st_x(the_geom)::numeric, 5) as xmin,
        round(st_x(the_geom)::numeric, 5) as xmax,
        round(st_y(the_geom)::numeric, 5) as ymin,
        round(st_y(the_geom)::numeric, 5) as ymax,
        'point' as geom_type,
        gadm2 AS located_at,
        'wikidata' as layer
FROM 
    wikidata
WHERE uid = '{uid}'