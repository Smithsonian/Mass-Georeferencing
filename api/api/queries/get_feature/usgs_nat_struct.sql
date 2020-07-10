SELECT
    uid::uuid,
    null as source_id,
    name as name,
    null as type,
    gadm2 as parent,
    st_x(w.the_geom)::numeric as longitude,
    st_y(w.the_geom)::numeric as latitude,
    'f' AS coords_from_centroid,
    NULL::json AS attributes,
    'point' as geom_type,
    'usgs_nat_struct' as layer
FROM
    usgs_nat_struct
WHERE 
    uid = '{uid}'
