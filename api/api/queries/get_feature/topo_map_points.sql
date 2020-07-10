SELECT 
    uid,
    source_id,
    name, 
    type,
    gadm2 as parent,
    round(st_x(m.the_geom)::numeric, 5) as longitude,
    round(st_y(m.the_geom)::numeric, 5) as latitude,
    'f' AS coords_from_centroid,
    null:json AS attributes,
    'point' as geom_type,
    'topo_map_points' as layer
FROM 
    topo_map_points
WHERE 
    uid = '{uid}'
    