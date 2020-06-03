WITH data AS (
    SELECT
        uid,
        namelsad AS name,
        type,
        gadm2,
        the_geom
    FROM
        tiger_counties
    WHERE
        uid = '{uid}'


    UNION


    SELECT
        uid,
        fullname AS name,
        type,
        gadm2,
        the_geom
    FROM
        tiger_arealm
    WHERE
        uid = '{uid}'


    UNION


    SELECT
        uid,
        fullname AS name,
        type,
        gadm2,
        the_geom
    FROM
        tiger_areawater
    WHERE
        uid = '{uid}'


    UNION


    SELECT
        uid,
        fullname AS name,
        type,
        gadm2,
        the_geom
    FROM
        tiger_roads
    WHERE
        uid = '{uid}'
)

SELECT 
    ST_AsGeoJSON(d.the_geom) as the_geom,
    round((ST_MinimumBoundingRadius(st_transform(d.the_geom, '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs'))).radius) as min_bound_radius_m,
    ST_AsGeoJSON(st_envelope(d.the_geom)) as the_geom_extent,
    uid,
    name,
    type,
    null as parent,
    round(
        st_x(
            st_transform(
                (ST_MinimumBoundingRadius(
                    st_transform(d.the_geom, '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs')
                )).center,
                '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs', 4326)
            )::numeric
        , 5) as longitude,
    round(
        st_y(
            st_transform(
                (ST_MinimumBoundingRadius(
                    st_transform(d.the_geom, '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs')
                )).center,
                '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs', 4326)
            )::numeric
        , 5) as latitude,
    st_xmin(d.the_geom) as xmin,
    st_xmax(d.the_geom) as xmax,
    st_ymin(d.the_geom) as ymin,
    st_ymax(d.the_geom) as ymax,
    'polygon' as geom_type,
    gadm2 as located_at,
    'tiger' as layer
FROM
    data d,
    utm_zones u
WHERE
    st_intersects(d.the_geom, u.the_geom)
