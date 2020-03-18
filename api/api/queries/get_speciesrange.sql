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
