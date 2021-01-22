
SELECT
    ST_AsGeoJSON(w.the_geom) as the_geom,
    null as min_bound_radius_m,
    null as the_geom_extent,
    w.uid,
    w.name,
    null as type,
    null as parent,
    st_x((ST_Dump(w.the_geom)).geom) as longitude,
    st_y((ST_Dump(w.the_geom)).geom) as latitude,
    st_x((ST_Dump(w.the_geom)).geom) as xmin,
    st_x((ST_Dump(w.the_geom)).geom) as xmax,
    st_y((ST_Dump(w.the_geom)).geom) as ymin,
    st_y((ST_Dump(w.the_geom)).geom) as ymax,
    'point' as geom_type,
    gadm2 as located_at,
    ST_SRID(w.the_geom) as srid,
    'usgs_nat_struct' as layer
FROM
    usgs_nat_struct w
WHERE
    w.uid = '{uid}'
    