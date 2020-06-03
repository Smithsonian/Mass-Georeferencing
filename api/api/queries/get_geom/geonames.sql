SELECT
    ST_AsGeoJSON(the_geom) as the_geom,
    null as min_bound_radius_m,
    null as the_geom_extent,
    g.uid,
    g.name,
    gc.name as type,
    c.country as parent,
    st_x(the_geom) as longitude,
    st_y(the_geom) as latitude,
    st_x(the_geom) as xmin,
    st_x(the_geom) as xmax,
    st_y(the_geom) as ymin,
    st_y(the_geom) as ymax,
    'point' as geom_type,
    gadm2 as located_at,
    'geonames' as layer
FROM
    geonames g
        LEFT JOIN geonames_fc gc
            ON (g.feature_code = gc.code)
        LEFT JOIN countries_iso c
            ON (g.country_code = c.iso2)
WHERE
    uid = '{uid}'
