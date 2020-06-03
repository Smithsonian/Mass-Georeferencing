SELECT 
    uid::uuid,
    glwd_id::text as source_id,
    lake_name::text as name, 
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
    't' AS coords_from_centroid,
    row_to_json(
            (
                SELECT d FROM (
                    SELECT 
                        dam_name::text,
                        poly_src::text,
                        area_skm::text,
                        perim_km::text,
                        long_deg::text,
                        lat_deg::text,
                        elev_m::text,
                        catch_tskm::text,
                        inflow_cms::text,
                        volume_ckm::text,
                        vol_src::text,       
                        country::text,     
                        sec_cntry::text,         
                        river::text,     
                        near_city::text,     
                        mgld_type::text,
                        mgld_area::text,
                        lrs_area::text,
                        lrs_ar_src::text,
                        lrs_catch::text,
                        dam_height::text,
                        dam_year::text,
                        use_1::text,
                        use_2::text,
                        use_3::text
                    ) d)
            ) AS attributes,
    'polygon' as geom_type,
    'global_lakes' as layer
FROM 
    global_lakes w,
    utm_zones u
WHERE 
    uid = '{uid}' AND
    st_intersects(w.the_geom, u.the_geom)

