WITH data AS (
    SELECT 
        species,
        count(*) AS no_records,
        ST_ConvexHull(ST_Collect(the_geom)) as the_geom,
        ST_Collect(the_geom) as geom
    FROM 
        gbif
    WHERE
        species = %(species)s
    GROUP BY 
        species
)
SELECT 
    ST_Distance(
        the_geom::geography,
        ST_SetSRID(ST_POINT(%(lng)s, %(lat)s), 4326)::geography) as distance,
    'm' as units,
    'Convex Hull' as type
FROM 
    data
