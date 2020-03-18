SELECT 
    wdpaid::int, 
    name::text, 
    desig_eng::text as desig, 
    desig_type::text, 
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
    sub_loc::text,
    parent_iso::text,
    iso3::text
FROM
    wdpa_polygons
WHERE
    st_intersects(the_geom,
            st_setsrid(st_point(
                %(lng)s, %(lat)s
                ), 4326))
