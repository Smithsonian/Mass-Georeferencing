WITH wiki AS (
    SELECT
        w.the_geom,
        w.uid,
        w.name,
        ST_SRID(w.the_geom) as srid
    FROM
        usa_rivers w
    WHERE
        w.uid = '{uid}' 
),
data AS (
    SELECT
        w.the_geom,
        w.uid,
        w.name,
        w.srid,
        d.description AS type
    FROM
        wiki w LEFT JOIN wikidata_descrip d ON (w.source_id = d.source_id AND d.language = 'en')
)

SELECT 
        ST_AsGeoJSON(w.the_geom) as the_geom,
        null as min_bound_radius_m,
        null as the_geom_extent,
        w.uid,
        w.name,
        w.type,
        null as parent,
        round(st_x(w.the_geom)::numeric, 5) as longitude,
        round(st_y(w.the_geom)::numeric, 5) as latitude,
        round(st_x(w.the_geom)::numeric, 5) as xmin,
        round(st_x(w.the_geom)::numeric, 5) as xmax,
        round(st_y(w.the_geom)::numeric, 5) as ymin,
        round(st_y(w.the_geom)::numeric, 5) as ymax,
        'polygon' as geom_type,
        g.name_2 || ', ' || g.name_1 || ', ' || g.name_0 AS located_at,
        w.srid,
        'usa_rivers' as layer
FROM 
    data w LEFT JOIN gadm2 g ON st_intersects(w.the_geom, g.the_geom)
