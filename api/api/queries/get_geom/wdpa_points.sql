
SELECT
    ST_AsGeoJSON(w.the_geom) as the_geom,
    null as min_bound_radius_m,
    null as the_geom_extent,
    w.uid,
    w.name,
    w.desig_eng as type,
    c.country as parent,
    st_x((ST_Dump(w.the_geom)).geom) as longitude,
    st_y((ST_Dump(w.the_geom)).geom) as latitude,
    st_x((ST_Dump(w.the_geom)).geom) as xmin,
    st_x((ST_Dump(w.the_geom)).geom) as xmax,
    st_y((ST_Dump(w.the_geom)).geom) as ymin,
    st_y((ST_Dump(w.the_geom)).geom) as ymax,
    'point' as geom_type,
    gadm2 as located_at,
    'wdpa_points' as layer
FROM
    wdpa_points w LEFT JOIN countries_iso c ON (w.iso3 = c.iso3)
WHERE
    w.uid = '{uid}'
    