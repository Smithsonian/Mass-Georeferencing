SELECT
    ST_AsGeoJSON(the_geom) as the_geom,
    null as min_bound_radius_m,
    null as the_geom_extent,
    uid,
    full_name_nd_ro as name,
    null as type,
    gadm2 as parent,
    st_x(the_geom) as longitude,
    st_y(the_geom) as latitude,
    st_x(the_geom) as xmin,
    st_x(the_geom) as xmax,
    st_y(the_geom) as ymin,
    st_y(the_geom) as ymax,
    'point' as geom_type,
    gadm2 as located_at,
    'gns' as layer
FROM
    gns
WHERE
    uid = '{uid}'
