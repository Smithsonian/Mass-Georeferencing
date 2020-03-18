with a as (
    SELECT 
        uid,
        name_0 as name,
        'gadm0' as layer,
        'NA' as parent,
        'Country' as type, 
        name_0 <-> %(string)s as sortby
    FROM 
        gadm0
    WHERE name_0 <-> %(string)s < 0.5
    ORDER BY sortby
    LIMIT 50
),

b as (
    SELECT 
        uid,
        name_1 as name,
        'gadm1' as layer,
        name_0 as parent,
        engtype_1 as type, 
        name_1 <-> %(string)s as sortby
    FROM 
        gadm1
    WHERE name_1 <-> %(string)s < 0.5
        ORDER BY sortby
        LIMIT 50
), 

c as (
    SELECT 
        uid,
        name_2 as name,
        'gadm2' as layer,
        concat(name_1 || ', ' || name_0) as parent,
        engtype_2 as type, 
        name_2 <-> %(string)s as sortby 
    FROM 
        gadm2
    WHERE name_2 <-> %(string)s < 0.5
        ORDER BY sortby
        LIMIT 50
), 

d as (
    SELECT 
        uid,
        name_3 as name,
        'gadm3' as layer,
        concat(name_2 || ', ' || name_1 || ', ' || name_0) as parent,
        engtype_3 as type, 
        name_3 <-> %(string)s as sortby 
    FROM 
        gadm3
    WHERE name_3 <-> %(string)s < 0.5
        ORDER BY sortby
        LIMIT 50
), 

e as (
    SELECT 
        uid,
        name_4 as name,
        'gadm4' as layer,
        concat(name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0) as parent,
        engtype_4 as type, 
        name_4 <-> %(string)s as sortby 
    FROM 
        gadm4
    WHERE name_4 <-> %(string)s < 0.5
        ORDER BY sortby
        LIMIT 50
), 

f as (
    SELECT 
        uid,
        name_5 as name,
        'gadm5' as layer,
        concat(name_4 || ', ' || name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0) as parent,
        engtype_5 as type, 
        name_5 <-> %(string)s as sortby 
    FROM 
        gadm5
    WHERE name_5 <-> %(string)s < 0.5
        ORDER BY sortby
        LIMIT 50
), 

g as (
    SELECT
        uid,
        name,
        'wdpa_polygons' as layer,
        iso3 as parent,
        desig_eng as type, 
        name <-> %(string)s as sortby 
    FROM
        wdpa_polygons
    WHERE name <-> %(string)s < 0.5
        ORDER BY sortby
        LIMIT 50
), 

h as (
    SELECT
        uid,
        name,
        'wdpa_points' as layer,
        iso3 as parent,
        desig_eng as type,
        name <-> %(string)s as sortby 
    FROM
        wdpa_points
    WHERE name <-> %(string)s < 0.5
        ORDER BY sortby
        LIMIT 50
), 

i as (
    SELECT
        g.uid,
        g.name,
        'geonames' as layer,
        c.country as parent,
        gc.name as type, 
        ga.name <-> %(string)s as sortby 
    FROM
        geonames g 
            LEFT JOIN geonames_fc gc 
                ON (g.feature_code = gc.code)
            LEFT JOIN geonames_alt ga 
                ON (g.geonameid = ga.geonameid)
            LEFT JOIN countries_iso c 
                ON (g.country_code = c.iso2)
    WHERE ga.name <-> %(string)s < 0.5
    ORDER BY sortby
    LIMIT 100
), 

j as (
    SELECT
        g.uid,
        g.name,
        'geonames' as layer,
        c.country as parent,
        gc.name as type, 
        g.name <-> %(string)s as sortby 
    FROM
        geonames g 
            LEFT JOIN geonames_fc gc 
                ON (g.feature_code = gc.code)
            LEFT JOIN countries_iso c 
                ON (g.country_code = c.iso2)
    ORDER BY g.name <-> %(string)s
    LIMIT 100
),

k as (
    SELECT
        uid,
        feature_name,
        'gnis' as layer,
        concat(county_name, ', ', state_alpha) as parent,
        feature_class as type, 
        feature_name <-> %(string)s as sortby 
    FROM
        gnis
    ORDER BY feature_name <-> %(string)s
    LIMIT 100
)


SELECT * FROM a UNION
SELECT * FROM b UNION
SELECT * FROM c UNION
SELECT * FROM d UNION
SELECT * FROM e UNION
SELECT * FROM f UNION
SELECT * FROM g UNION
SELECT * FROM h UNION
SELECT * FROM i UNION
SELECT * FROM j UNION
SELECT * FROM k
order by sortby