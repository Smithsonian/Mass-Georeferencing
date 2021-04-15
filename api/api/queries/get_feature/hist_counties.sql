SELECT
    w.uid::uuid,
    w.gid::text as source_id,
    w.name,
    'county' as type,
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
    't' AS coords_from_centroid,
    row_to_json(
            (
                SELECT d FROM (
                    SELECT
                        id::text,
                        state_terr::text,
                        fips::text,
                        start_date::text,
                        end_date::text,
                        change::text,
                        citation::text
                    ) d)
            ) AS attributes,
    'polygon' as geom_type,
    'hist_counties' as layer
FROM
    hist_counties w,
    utm_zones u
WHERE
    uid = '{uid}' AND
    st_intersects(w.the_geom, u.the_geom)
