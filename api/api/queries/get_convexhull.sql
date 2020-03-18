WITH data AS (
    SELECT 
        species,
        count(*) AS no_records,
        ST_AsGeoJSON(ST_ConvexHull(ST_Collect(the_geom))) as the_geom,
        ST_Collect(the_geom) as geom
    FROM 
        gbif
    WHERE
        species = %(species)s
    GROUP BY 
        species
)
SELECT 
    species,
    no_records,
    the_geom,
    st_xmin(geom) as xmin,
    st_xmax(geom) as xmax,
    st_ymin(geom) as ymin,
    st_ymax(geom) as ymax,
    'Convex Hull' as type
FROM 
    data
