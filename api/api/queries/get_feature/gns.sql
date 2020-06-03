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
    uid = '{uid}'
