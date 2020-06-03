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
    st_intersects(w.the_geom, u.the_geom)
