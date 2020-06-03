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
    g.uid = '{uid}'
    