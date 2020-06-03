SELECT
    uid::uuid,
    gid::text as source_id,
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
    't' AS coords_from_centroid,
    NULL::json AS attributes,
    'polygon' as geom_type,
    'gadm1' as layer
FROM
    gadm1 w,
    utm_zones u
WHERE 
    uid = '{uid}' AND
    st_intersects(w.the_geom, u.the_geom)

