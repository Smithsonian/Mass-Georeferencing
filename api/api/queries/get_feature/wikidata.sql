SELECT 
    uid::uuid,
    source_id,
    name, 
    null as type,
    gadm2 as parent,
    round(st_x(m.the_geom)::numeric, 5) as longitude,
    round(st_y(m.the_geom)::numeric, 5) as latitude,
    'f' AS coords_from_centroid,
    null::json AS attributes,
    'point' as geom_type,
    'wikidata' as layer
FROM 
    wikidata
WHERE 
    uid = '{uid}'
    