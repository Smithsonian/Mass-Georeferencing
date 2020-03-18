WITH data AS
    (SELECT st_setsrid(st_point(
                %(lng)s, %(lat)s
                ), 4326) as the_geom)

SELECT
    g.name_0 as name,
    'gadm0' as layer,
    'Country' as adminarea_type
FROM
    gadm0 g,
    data
WHERE
    st_intersects(data.the_geom, g.the_geom)

UNION

SELECT
    g.name_1 as name,
    'gadm1' as layer,
    g.engtype_1 as adminarea_type
FROM
    gadm1 g,
    data
WHERE
    st_intersects(data.the_geom, g.the_geom)

UNION

SELECT
    g.name_2 as name,
    'gadm2' as layer,
    g.engtype_2 as adminarea_type
FROM
    gadm2 g,
    data
WHERE
    st_intersects(data.the_geom, g.the_geom)

UNION

SELECT
    g.name_3 as name,
    'gadm3' as layer,
    g.engtype_3 as adminarea_type
FROM
    gadm3 g,
    data
WHERE
    st_intersects(data.the_geom, g.the_geom)

UNION

SELECT
    g.name_4 as name,
    'gadm4' as layer,
    g.engtype_4 as adminarea_type
FROM
    gadm4 g,
    data
WHERE
    st_intersects(data.the_geom, g.the_geom)

UNION

SELECT
    g.name_5 as name,
    'gadm5' as layer,
    g.engtype_5 as adminarea_type
FROM
    gadm5 g,
    data
WHERE
    st_intersects(data.the_geom, g.the_geom)
