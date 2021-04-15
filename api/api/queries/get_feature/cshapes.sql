SELECT
    w.uid::uuid,
    w.featureid::text as source_id,
    w.cntry_name as name,
    'country' as type,
    NULL as parent,
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
                        area::text,
                        capname::text,
                        isoname::text,
                        iso1al3::text as iso3,
                        start_date::text,
                        end_date::text
                    ) d)
            ) AS attributes,
    'polygon' as geom_type,
    'hist_counties' as layer
FROM
    cshapes w,
    utm_zones u
WHERE
    uid = '{uid}' AND
    st_intersects(w.the_geom, u.the_geom)
