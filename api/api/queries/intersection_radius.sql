WITH data1 AS
    (SELECT st_transform(st_setsrid(st_point(
                %(lng)s, %(lat)s
                ), 4326), 3857) as the_geom_webmercator)

data AS
    (SELECT st_buffer(the_geom_webmercator, %(radius)s) as the_geom_webmercator 
    FROM
        data1)

SELECT
    g.name_0 as name,
    'gadm0' as layer,
    'country' as type,
    uid::uuid
FROM
    gadm0 g,
    data
WHERE
    st_intersects(data.the_geom_webmercator, g.the_geom_webmercator)

UNION

SELECT
    g.name_1 as name,
    'gadm1' as layer,
    engtype_1 as type,
    uid::uuid
FROM
    gadm1 g,
    data
WHERE
    st_intersects(data.the_geom_webmercator, g.the_geom_webmercator)

UNION

SELECT
    g.name_2 as name,
    'gadm2' as layer,
    engtype_2 as type,
    uid::uuid
FROM
    gadm2 g,
    data
WHERE
    st_intersects(data.the_geom_webmercator, g.the_geom_webmercator)

UNION

SELECT
    g.name_3 as name,
    'gadm3' as layer,
    engtype_3 as type,
    uid::uuid
FROM
    gadm3 g,
    data
WHERE
    st_intersects(data.the_geom_webmercator, g.the_geom_webmercator)

UNION

SELECT
    g.name_4 as name,
    'gadm4' as layer,
    engtype_4 as type,
    uid::uuid
FROM
    gadm4 g,
    data
WHERE
    st_intersects(data.the_geom_webmercator, g.the_geom_webmercator)

UNION

SELECT
    g.name_5 as name,
    'gadm5' as layer,
    engtype_5 as type,
    uid::uuid
FROM
    gadm5 g,
    data
WHERE
    st_intersects(data.the_geom_webmercator, g.the_geom_webmercator)

UNION

SELECT
    name,
    'wdpa_polygons' as layer,
    desig_eng as type,
    uid::uuid
FROM
    wdpa_polygons g,
    data
WHERE
    st_intersects(data.the_geom_webmercator, g.the_geom_webmercator)

UNION

SELECT
    name,
    'wdpa_points' as layer,
    desig_eng as type,
    uid::uuid
FROM
    wdpa_points g,
    data
WHERE
    st_intersects(data.the_geom_webmercator, g.the_geom_webmercator)

UNION

SELECT
    name,
    'geonames' as layer,
    null as type,
    uid::uuid
FROM
    geonames g,
    data
WHERE
    st_intersects(data.the_geom_webmercator, g.the_geom_webmercator)

UNION

SELECT
    feature_name AS name,
    'gnis' as layer,
    feature_class as type,
    uid::uuid
FROM
    gnis g,
    data
WHERE
    st_intersects(data.the_geom_webmercator, g.the_geom_webmercator)
