SELECT
    ST_AsGeoJSON(w.the_geom_simp) as the_geom,
    round((ST_MinimumBoundingRadius(st_transform(w.the_geom, '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs'))).radius) as min_bound_radius_m,
    ST_AsGeoJSON(st_envelope(w.the_geom)) as the_geom_extent,
    uid,
    name_0 as name,
    'Country' as type,
    'World' as parent,
    round(
        st_x(
            st_transform(
                (ST_MinimumBoundingRadius(
                    st_transform(w.the_geom, '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs')
                )).center,
                '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs', 4326)
            )::numeric
        , 5) as longitude,
    round(
        st_y(
            st_transform(
                (ST_MinimumBoundingRadius(
                    st_transform(w.the_geom, '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs')
                )).center,
                '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs', 4326)
            )::numeric
        , 5) as latitude,
    st_xmin(w.the_geom_simp) as xmin,
    st_xmax(w.the_geom_simp) as xmax,
    st_ymin(w.the_geom_simp) as ymin,
    st_ymax(w.the_geom_simp) as ymax,
    'polygon' as geom_type,
    name_0 as located_at,
    'gadm0' as layer
FROM
    gadm0 w,
    utm_zones u
WHERE
    uid = '{uid}' AND
    '{layer}' = 'gadm0' AND
    st_intersects(w.the_geom, u.the_geom)

UNION

SELECT
    ST_AsGeoJSON(w.the_geom_simp) as the_geom,
    round((ST_MinimumBoundingRadius(st_transform(w.the_geom, '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs'))).radius) as min_bound_radius_m,
    ST_AsGeoJSON(st_envelope(w.the_geom)) as the_geom_extent,
    uid,
    name_1 as name,
    engtype_1 as type,
    name_0 as parent,
    round(
        st_x(
            st_transform(
                (ST_MinimumBoundingRadius(
                    st_transform(w.the_geom, '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs')
                )).center,
                '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs', 4326)
            )::numeric
        , 5) as longitude,
    round(
        st_y(
            st_transform(
                (ST_MinimumBoundingRadius(
                    st_transform(w.the_geom, '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs')
                )).center,
                '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs', 4326)
            )::numeric
        , 5) as latitude,
    st_xmin(w.the_geom_simp) as xmin,
    st_xmax(w.the_geom_simp) as xmax,
    st_ymin(w.the_geom_simp) as ymin,
    st_ymax(w.the_geom_simp) as ymax,
    'polygon' as geom_type,
    name_0 as located_at,
    'gadm1' as layer
FROM
    gadm1 w,
    utm_zones u
WHERE
    uid = '{uid}' AND
    '{layer}' = 'gadm1' AND
    st_intersects(w.the_geom, u.the_geom)

UNION

SELECT
    ST_AsGeoJSON(w.the_geom) as the_geom,
    round((ST_MinimumBoundingRadius(st_transform(w.the_geom, '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs'))).radius) as min_bound_radius_m,
    ST_AsGeoJSON(st_envelope(w.the_geom)) as the_geom_extent,
    uid,
    name_2 as name,
    engtype_2 as type,
    concat(name_1 || ', ' || name_0) as parent,
    round(
        st_x(
            st_transform(
                (ST_MinimumBoundingRadius(
                    st_transform(w.the_geom, '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs')
                )).center,
                '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs', 4326)
            )::numeric
        , 5) as longitude,
    round(
        st_y(
            st_transform(
                (ST_MinimumBoundingRadius(
                    st_transform(w.the_geom, '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs')
                )).center,
                '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs', 4326)
            )::numeric
        , 5) as latitude,
    st_xmin(w.the_geom_simp) as xmin,
    st_xmax(w.the_geom_simp) as xmax,
    st_ymin(w.the_geom_simp) as ymin,
    st_ymax(w.the_geom_simp) as ymax,
    'polygon' as geom_type,
    name_1 || ', ' || name_0 as located_at,
    'gadm2' as layer
FROM
    gadm2 w,
    utm_zones u
WHERE
    uid = '{uid}' AND
    '{layer}' = 'gadm2' AND
    st_intersects(w.the_geom, u.the_geom)

UNION

SELECT
    ST_AsGeoJSON(w.the_geom) as the_geom,
    round((ST_MinimumBoundingRadius(st_transform(w.the_geom, '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs'))).radius) as min_bound_radius_m,
    ST_AsGeoJSON(st_envelope(w.the_geom)) as the_geom_extent,
    uid,
    name_3 as name,
    engtype_3 as type,
    concat(name_2 || ', ' || name_1 || ', ' || name_0) as parent,
    round(
        st_x(
            st_transform(
                (ST_MinimumBoundingRadius(
                    st_transform(w.the_geom, '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs')
                )).center,
                '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs', 4326)
            )::numeric
        , 5) as longitude,
    round(
        st_y(
            st_transform(
                (ST_MinimumBoundingRadius(
                    st_transform(w.the_geom, '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs')
                )).center,
                '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs', 4326)
            )::numeric
        , 5) as latitude,
    st_xmin(w.the_geom_simp) as xmin,
    st_xmax(w.the_geom_simp) as xmax,
    st_ymin(w.the_geom_simp) as ymin,
    st_ymax(w.the_geom_simp) as ymax,
    'polygon' as geom_type,
    name_2 || ', ' || name_1 || ', ' || name_0 as located_at,
    'gadm3' as layer
FROM
    gadm3 w,
    utm_zones u
WHERE
    uid = '{uid}' AND
    '{layer}' = 'gadm3' AND
    st_intersects(w.the_geom, u.the_geom)

UNION

SELECT
    ST_AsGeoJSON(w.the_geom) as the_geom,
    round((ST_MinimumBoundingRadius(st_transform(w.the_geom, '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs'))).radius) as min_bound_radius_m,
    ST_AsGeoJSON(st_envelope(w.the_geom)) as the_geom_extent,
    uid,
    name_4 as name,
    engtype_4 as type,
    concat(name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0) as parent,
    round(
        st_x(
            st_transform(
                (ST_MinimumBoundingRadius(
                    st_transform(w.the_geom, '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs')
                )).center,
                '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs', 4326)
            )::numeric
        , 5) as longitude,
    round(
        st_y(
            st_transform(
                (ST_MinimumBoundingRadius(
                    st_transform(w.the_geom, '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs')
                )).center,
                '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs', 4326)
            )::numeric
        , 5) as latitude,
    st_xmin(w.the_geom_simp) as xmin,
    st_xmax(w.the_geom_simp) as xmax,
    st_ymin(w.the_geom_simp) as ymin,
    st_ymax(w.the_geom_simp) as ymax,
    'polygon' as geom_type,
    name_2 || ', ' || name_1 || ', ' || name_0 as located_at,
    'gadm4' as layer
FROM
    gadm4 w,
    utm_zones u
WHERE
    uid = '{uid}' AND
    '{layer}' = 'gadm4' AND
    st_intersects(w.the_geom, u.the_geom)

UNION

SELECT
    ST_AsGeoJSON(w.the_geom) as the_geom,
    round((ST_MinimumBoundingRadius(st_transform(w.the_geom, '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs'))).radius) as min_bound_radius_m,
    ST_AsGeoJSON(st_envelope(w.the_geom)) as the_geom_extent,
    uid,
    name_5 as name,
    engtype_5 as type,
    concat(name_4 || ', ' || name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0) as parent,
    round(
        st_x(
            st_transform(
                (ST_MinimumBoundingRadius(
                    st_transform(w.the_geom, '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs')
                )).center,
                '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs', 4326)
            )::numeric
        , 5) as longitude,
    round(
        st_y(
            st_transform(
                (ST_MinimumBoundingRadius(
                    st_transform(w.the_geom, '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs')
                )).center,
                '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs', 4326)
            )::numeric
        , 5) as latitude,
    st_xmin(w.the_geom_simp) as xmin,
    st_xmax(w.the_geom_simp) as xmax,
    st_ymin(w.the_geom_simp) as ymin,
    st_ymax(w.the_geom_simp) as ymax,
    'polygon' as geom_type,
    name_2 || ', ' || name_1 || ', ' || name_0 as located_at,
    'gadm5' as layer
FROM
    gadm5 w,
    utm_zones u
WHERE
    uid = '{uid}' AND
    '{layer}' = 'gadm5' AND
    st_intersects(w.the_geom, u.the_geom)

UNION

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
    w.uid = '{uid}' AND
    '{layer}' = 'wdpa_points'

UNION

SELECT
    ST_AsGeoJSON(w.the_geom) as the_geom,
    round((ST_MinimumBoundingRadius(st_transform(w.the_geom, '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs'))).radius) as min_bound_radius_m,
    ST_AsGeoJSON(st_envelope(w.the_geom)) as the_geom_extent,
    w.uid,
    w.name,
    w.desig_eng as type,
    c.country as parent,
    round(
        st_x(
            st_transform(
                (ST_MinimumBoundingRadius(
                    st_transform(w.the_geom, '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs')
                )).center,
                '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs', 4326)
            )::numeric
        , 5) as longitude,
    round(
        st_y(
            st_transform(
                (ST_MinimumBoundingRadius(
                    st_transform(w.the_geom, '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs')
                )).center,
                '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs', 4326)
            )::numeric
        , 5) as latitude,
    st_xmin(w.the_geom) as xmin,
    st_xmax(w.the_geom) as xmax,
    st_ymin(w.the_geom) as ymin,
    st_ymax(w.the_geom) as ymax,
    'polygon' as geom_type,
    gadm2 as located_at,
    'wdpa_polygons' as layer
FROM
    wdpa_polygons w LEFT JOIN countries_iso c ON (w.iso3 = c.iso3),
    utm_zones u
WHERE
    w.uid = '{uid}' AND
    '{layer}' = 'wdpa_polygons' AND
    st_intersects(w.the_geom, u.the_geom)

UNION

SELECT
    ST_AsGeoJSON(w.the_geom) as the_geom,
    round((ST_MinimumBoundingRadius(st_transform(w.the_geom, '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs'))).radius) as min_bound_radius_m,
    ST_AsGeoJSON(st_envelope(w.the_geom)) as the_geom_extent,
    uid,
    lake_name as name,
    type,
    country as parent,
    round(
        st_x(
            st_transform(
                (ST_MinimumBoundingRadius(
                    st_transform(w.the_geom, '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs')
                )).center,
                '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs', 4326)
            )::numeric
        , 5) as longitude,
    round(
        st_y(
            st_transform(
                (ST_MinimumBoundingRadius(
                    st_transform(w.the_geom, '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs')
                )).center,
                '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs', 4326)
            )::numeric
        , 5) as latitude,
    st_xmin(w.the_geom) as xmin,
    st_xmax(w.the_geom) as xmax,
    st_ymin(w.the_geom) as ymin,
    st_ymax(w.the_geom) as ymax,
    'polygon' as geom_type,
    gadm2 as located_at,
    'global_lakes' as layer
FROM
    global_lakes w,
    utm_zones u
WHERE
    uid = '{uid}' AND
    '{layer}' = 'global_lakes' AND
    st_intersects(w.the_geom, u.the_geom)

UNION

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
    uid = '{uid}' AND
    '{layer}' = 'geonames'

UNION

SELECT
    ST_AsGeoJSON(the_geom) as the_geom,
    null as min_bound_radius_m,
    null as the_geom_extent,
    uid,
    feature_name as name,
    feature_class as type,
    concat(county_name, ', ', state_alpha) as parent,
    st_x(the_geom) as longitude,
    st_y(the_geom) as latitude,
    st_x(the_geom) as xmin,
    st_x(the_geom) as xmax,
    st_y(the_geom) as ymin,
    st_y(the_geom) as ymax,
    'point' as geom_type,
    gadm2 as located_at,
    'gnis' as layer
FROM
    gnis
WHERE
    uid = '{uid}' AND
    '{layer}' = 'gnis'


UNION

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
    uid = '{uid}' AND
    '{layer}' = 'gns'
