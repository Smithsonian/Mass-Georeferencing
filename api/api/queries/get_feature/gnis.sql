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
    uid = '{uid}'
