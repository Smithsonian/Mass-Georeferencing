WITH data AS
    (SELECT st_transform(st_setsrid(st_point(
                %(lng)s, %(lat)s
                ), 4326), 3857) as the_geom_webmercator)

SELECT 
    g.name_0 as name,
    'gadm0' as layer,
    'Country' as adminarea_type,
    (st_distance(data.the_geom_webmercator, g.the_geom_webmercator) / 1000) as distance_km
FROM
    gadm0 g,
    data
WHERE
    ST_DWithin(g.the_geom_webmercator, data.the_geom_webmercator, 100000)
ORDER BY
    distance_km ASC
LIMIT 
    %(rows)s 