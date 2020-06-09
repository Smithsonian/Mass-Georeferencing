SELECT 
    uid::uuid,
    glwd_id::text as source_id,
    lake_name::text as name, 
    type,
    country as parent,
    round(st_x(centroid)::numeric, 5) as longitude,
    round(st_y(centroid)::numeric, 5) as latitude,
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
    global_lakes
WHERE 
    '{layer}' = 'global_lakes' AND
    uid = '{uid}'

UNION ALL

SELECT 
    uid::uuid,
    wdpaid::text as source_id,
    name::text as name, 
    desig_eng::text as type,
    parent_iso::text as parent,
    round(st_x(centroid)::numeric, 5) as longitude,
    round(st_y(centroid)::numeric, 5) as latitude,
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
    wdpa_polygons 
WHERE 
    '{layer}' = 'wdpa_polygons' AND
    uid = '{uid}'
    
UNION ALL

SELECT 
    uid::uuid,
    wdpaid::text as source_id,
    name::text as name, 
    desig_eng::text as type,
    parent_iso::text as parent,
    round(st_x(the_geom)::numeric, 5) as longitude,
    round(st_y(the_geom)::numeric, 5) as latitude,
    'f' AS coords_from_centroid,
    row_to_json(
            (
                SELECT d FROM (
                    SELECT 
                        orig_name::text,
                        iucn_cat::text, 
                        int_crit::text, 
                        marine::int,
                        rep_m_area::numeric,
                        rep_area::numeric,
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
    'point' as geom_type,
    'wdpa_points' as layer
    
FROM 
    wdpa_points
WHERE 
    '{layer}' = 'wdpa_points' AND
    uid = '{uid}'
    
UNION ALL

SELECT 
    g.uid::uuid,
    g.geonameid::text as source_id,
    g.name::text as name, 
    gc.name::text as type,
    c.country::text as parent,
    g.longitude::float,
    g.latitude::float,
    'f' AS coords_from_centroid,
    row_to_json(
            (
                SELECT d FROM (
                    SELECT 
                        alternatenames::text,
                        population::text, 
                        dem::text, 
                        timezone::text,
                        modification::text
                    ) d)
            ) AS attributes,
    'point' as geom_type,
    'geonames' as layer
    
FROM 
    geonames g
        LEFT JOIN geonames_fc gc
            ON (g.feature_code = gc.code)
        LEFT JOIN countries_iso c
            ON (g.country_code = c.iso2)
WHERE 
    '{layer}' = 'geonames' AND
    g.uid = '{uid}'
    
UNION ALL

SELECT 
    uid::uuid,
    feature_id::text as source_id,
    feature_name::text as name, 
    feature_class::text as type,
    concat(county_name::text, ', ', state_alpha) as parent,
    prim_long_dec::numeric as longitude,
    prim_lat_dec::numeric as latitude,
    'f' AS coords_from_centroid,
    row_to_json(
            (
                SELECT d FROM (
                    SELECT 
                        primary_lat_dms::text,
                        prim_long_dms::text, 
                        source_lat_dms::text, 
                        source_long_dms::text,
                        source_lat_dec::text,
                        source_long_dec::text,
                        elev_in_m::text,
                        elev_in_ft::text,
                        map_name::text,
                        date_created::text,
                        date_edited::text
                    ) d)
            ) AS attributes,
    'point' as geom_type,
    'gnis' as layer
    
FROM 
    gnis
WHERE 
    '{layer}' = 'gnis' AND
    uid = '{uid}'

UNION ALL

SELECT
    uid::uuid,
    gid::text as source_id,
    name_5 as name,
    engtype_5 as type,
    concat(name_4 || ', ' || name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0) as parent,
    round(st_x(centroid)::numeric, 5) as longitude,
    round(st_y(centroid)::numeric, 5) as latitude,
    't' AS coords_from_centroid,
    NULL::json AS attributes,
    'polygon' as geom_type,
    'gadm5' as layer
    
FROM
    gadm5
WHERE 
    '{layer}' = 'gadm5' AND
    uid = '{uid}'

UNION ALL

SELECT
    uid::uuid,
    gid::text as source_id,
    name_4 as name,
    engtype_4 as type,
    concat(name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0) as parent,
    round(st_x(centroid)::numeric, 5) as longitude,
    round(st_y(centroid)::numeric, 5) as latitude,
    't' AS coords_from_centroid,
    NULL::json AS attributes,
    'polygon' as geom_type,
    'gadm4' as layer
    
FROM
    gadm4
WHERE 
    '{layer}' = 'gadm4' AND
    uid = '{uid}'

UNION ALL

SELECT
    uid::uuid,
    gid::text as source_id,
    name_3 as name,
    engtype_3 as type,
    concat(name_2 || ', ' || name_1 || ', ' || name_0) as parent,
    round(st_x(centroid)::numeric, 5) as longitude,
    round(st_y(centroid)::numeric, 5) as latitude,
    't' AS coords_from_centroid,
    NULL::json AS attributes,
    'polygon' as geom_type,
    'gadm3' as layer
    
FROM
    gadm3
WHERE 
    '{layer}' = 'gadm3' AND
    uid = '{uid}'

UNION ALL

SELECT
    uid::uuid,
    gid::text as source_id,
    name_2 as name,
    engtype_2 as type,
    concat(name_1 || ', ' || name_0) as parent,
    round(st_x(centroid)::numeric, 5) as longitude,
    round(st_y(centroid)::numeric, 5) as latitude,
    't' AS coords_from_centroid,
    NULL::json AS attributes,
    'polygon' as geom_type,
    'gadm2' as layer
    
FROM
    gadm2
WHERE 
    '{layer}' = 'gadm2' AND
    uid = '{uid}'

UNION ALL

SELECT
    uid::uuid,
    gid::text as source_id,
    name_1 as name,
    engtype_1 as type,
    concat(name_0) as parent,
    round(st_x(centroid)::numeric, 5) as longitude,
    round(st_y(centroid)::numeric, 5) as latitude,
    't' AS coords_from_centroid,
    NULL::json AS attributes,
    'polygon' as geom_type,
    'gadm1' as layer
    
FROM
    gadm1
WHERE 
    '{layer}' = 'gadm1' AND
    uid = '{uid}'

UNION ALL

SELECT
    uid::uuid,
    gid::text as source_id,
    name_0 as name,
    'country' as type,
    NULL::text as parent,
    round(st_x(centroid)::numeric, 5) as longitude,
    round(st_y(centroid)::numeric, 5) as latitude,
    't' AS coords_from_centroid,
    NULL::json AS attributes,
    'polygon' as geom_type,
    'gadm0' as layer
    
FROM
    gadm0
WHERE 
    '{layer}' = 'gadm0' AND
    uid = '{uid}'

UNION ALL

SELECT 
    uid::uuid,
    null as source_id,
    full_name_nd_ro::text as name, 
    null as type,
    gadm2 as parent,
    long::numeric as longitude,
    lat::numeric as latitude,
    'f' AS coords_from_centroid,
    row_to_json(
            (
                SELECT d FROM (
                    SELECT 
                        rc::text,
                        ufi::text,
                        uni::text,
                        lat::float,
                        long::float,
                        dms_lat::text,
                        dms_long::text,
                        mgrs::text,
                        jog::text,
                        fc::text,
                        dsg::text,
                        pc::text,
                        cc1::text,
                        adm1::text,
                        pop::text,
                        elev::text,
                        cc2::text,
                        nt::text,
                        lc::text,
                        short_form::text,
                        generic::text,
                        sort_name_ro::text,
                        full_name_ro::text,
                        full_name_nd_ro::text,
                        sort_name_rg::text,
                        full_name_rg::text,
                        full_name_nd_rg::text,
                        note::text,
                        modify_date::text,
                        display::text,
                        name_rank::text,
                        name_link::text,
                        transl_cd::text,
                        nm_modify_date::text,
                        f_efctv_dt::text,
                        f_term_dt::text
                    ) d)
            ) AS attributes,
    'point' as geom_type,
    'gns' as layer
    
FROM 
    gns
WHERE 
    '{layer}' = 'gns' AND
    uid = '{uid}'