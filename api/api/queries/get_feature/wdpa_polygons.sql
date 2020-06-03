
SELECT 
    uid::uuid,
    wdpaid::text as source_id,
    name::text as name, 
    desig_eng::text as type,
    parent_iso::text as parent,
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
                        orig_name::text,
                        iucn_cat::text, 
                        int_crit::text, 
                        marine::int,
                        rep_m_area::numeric,
                        gis_m_area::numeric,
                        rep_area::numeric,
                        gis_area::numeric,
                        no_take::text,
                        no_tk_area::numeric,
                        status::text,
                        status_yr::int,
                        gov_type::text,
                        own_type::text,
                        mang_auth::text,
                        mang_plan::text,
                        verif::text,
                        sub_loc::text
                    ) d)
            ) AS attributes,
    'polygon' as geom_type,
    'wdpa_polygons' as layer
FROM 
    wdpa_polygons w,
    utm_zones u
WHERE 
    uid = '{uid}' AND
    st_intersects(w.the_geom, u.the_geom)
