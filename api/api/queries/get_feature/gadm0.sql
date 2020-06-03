SELECT
    uid::uuid,
    gid::text as source_id,
    name_0 as name,
    engtype_0 as type,
    null as parent,
    null as longitude,
    null as latitude,
    null AS coords_from_centroid,
    NULL::json AS attributes,
    'polygon' as geom_type,
    'gadm0' as layer
FROM
    gadm0 w,
    utm_zones u
WHERE 
    uid = '{uid}' AND
    st_intersects(w.the_geom, u.the_geom)

