SELECT
    uid::uuid,
    null as source_id,
    name as name,
    type,
    gadm2 as parent,
    st_x(w.the_geom)::numeric as longitude,
    st_y(w.the_geom)::numeric as latitude,
    'f' AS coords_from_centroid,
    NULL::json AS attributes,
    'point' as geom_type,
    'usa_histplaces_points' as layer
FROM
    usa_histplaces_points w,
    utm_zones u
WHERE 
    uid = '{uid}' AND
    st_intersects(w.the_geom, u.the_geom)

