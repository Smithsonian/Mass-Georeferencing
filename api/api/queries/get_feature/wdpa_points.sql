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
    uid = '{uid}'
