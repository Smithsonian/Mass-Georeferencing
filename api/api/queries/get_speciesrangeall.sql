WITH data AS (
    SELECT 
        sciname as species,
        count(*) AS no_records,
        citation,
        data_sources,
        compiler,
        version,
        kingdom,
        phylum,
        class,
        order_,
        family,
        genus,
        redlist_cat,
        ST_AsGeoJSON(st_simplify(ST_Collect(the_geom), 0.01)) as the_geom,
        st_simplify(ST_Collect(the_geom), 0.01) as geom
    FROM 
        iucn
    WHERE
        sciname = %(species)s
    GROUP BY 
        sciname,
        citation,
        data_sources,
        compiler,
        version,
        kingdom,
        phylum,
        class,
        order_,
        family,
        genus,
        redlist_cat
),

data_c AS (
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
    citation,
    data_sources,
    compiler,
    version,
    kingdom,
    phylum,
    class,
    order_,
    family,
    genus,
    redlist_cat,
    the_geom,
    st_xmin(geom) as xmin,
    st_xmax(geom) as xmax,
    st_ymin(geom) as ymin,
    st_ymax(geom) as ymax,
    'IUCN Range' as type
FROM 
    data

UNION

SELECT 
    species,
    no_records,
    null AS citation,
    null AS data_sources,
    null AS compiler,
    null AS version,
    null AS kingdom,
    null AS phylum,
    null AS class,
    null AS order_,
    null AS family,
    null AS genus,
    null AS redlist_cat,
    the_geom,
    st_xmin(geom) as xmin,
    st_xmax(geom) as xmax,
    st_ymin(geom) as ymin,
    st_ymax(geom) as ymax,
    'Convex Hull' as type
FROM 
    data_c
