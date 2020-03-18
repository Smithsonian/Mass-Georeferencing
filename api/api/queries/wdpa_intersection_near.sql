WITH data AS
    (SELECT st_transform(st_setsrid(st_point(
                %(lng)s, %(lat)s
                ), 4326), 3857) as the_geom_webmercator)

SELECT 
    g.name,
    g.wdpaid,
    'wdpa_polygons' as layer,
    round((st_distance(data.the_geom_webmercator, g.the_geom_webmercator) / 1000)::numeric, 3) as distance_km
FROM
    wdpa_polygons g,
    data
WHERE
    ST_INTERSECTS(g.the_geom_webmercator, ST_BUFFER(data.the_geom_webmercator, 100000))

UNION

SELECT 
    g.name,
    g.wdpaid,
    'wdpa_points' as layer,
    round((st_distance(data.the_geom_webmercator, g.the_geom_webmercator) / 1000)::numeric, 3) as distance_km
FROM
    wdpa_points g,
    data
WHERE
    ST_INTERSECTS(g.the_geom_webmercator, ST_BUFFER(data.the_geom_webmercator, 100000))


ORDER BY
    distance_km ASC
LIMIT 
    %(rows)s 