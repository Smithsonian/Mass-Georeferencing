WITH data AS
    (SELECT st_setsrid(st_point(
                %(lng)s, %(lat)s
                ), 4326) as the_geom),

localities AS (
    SELECT
        g.name_0 as name,
        'gadm0' as layer,
        'country' as type,
        uid,
        null AS located_at
    FROM
        gadm0 g,
        data
    WHERE
        %(layer)s = 'gadm' AND
        st_intersects(data.the_geom, g.the_geom)

    UNION

    SELECT
        g.name_1 as name,
        'gadm1' as layer,
        engtype_1 as type,
        uid,
        name_0 AS located_at
    FROM
        gadm1 g,
        data
    WHERE
        %(layer)s = 'gadm' AND
        st_intersects(data.the_geom, g.the_geom)

    UNION

    SELECT
        g.name_2 as name,
        'gadm2' as layer,
        engtype_2 as type,
        uid,
        name_1 || ', ' || name_0 AS located_at
    FROM
        gadm2 g,
        data
    WHERE
        %(layer)s = 'gadm' AND
        st_intersects(data.the_geom, g.the_geom)

    UNION

    SELECT
        g.name_3 as name,
        'gadm3' as layer,
        engtype_3 as type,
        uid,
        name_2 || ', ' || name_1 || ', ' || name_0 AS located_at
    FROM
        gadm3 g,
        data
    WHERE
        %(layer)s = 'gadm' AND
        st_intersects(data.the_geom, g.the_geom)

    UNION

    SELECT
        g.name_4 as name,
        'gadm4' as layer,
        engtype_4 as type,
        uid,
        name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0 AS located_at
    FROM
        gadm4 g,
        data
    WHERE
        %(layer)s = 'gadm' AND
        st_intersects(data.the_geom, g.the_geom)

    UNION

    SELECT
        g.name_5 as name,
        'gadm5' as layer,
        engtype_5 as type,
        uid,
        name_4 || ', ' || name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0 AS located_at
    FROM
        gadm5 g,
        data
    WHERE
        %(layer)s = 'gadm' AND
        st_intersects(data.the_geom, g.the_geom)

    UNION

    SELECT
        name,
        'wdpa_polygons' as layer,
        desig_eng as type,
        uid,
        gadm2 AS located_at
    FROM
        wdpa_polygons g,
        data
    WHERE
        %(layer)s = 'wdpa_polygons' AND
        st_intersects(data.the_geom, g.the_geom)

    UNION

    SELECT
        name,
        'wdpa_points' as layer,
        desig_eng as type,
        uid,
        gadm2 AS located_at
    FROM
        wdpa_points g,
        data
    WHERE
        %(layer)s = 'wdpa_points' AND
        st_intersects(data.the_geom, g.the_geom)

    UNION

    SELECT
        name,
        'geonames' as layer,
        null as type,
        uid,
        gadm2 AS located_at
    FROM
        geonames g,
        data
    WHERE
        %(layer)s = 'geonames' AND
        st_intersects(data.the_geom, g.the_geom)

    UNION

    SELECT
        feature_name AS name,
        'gnis' as layer,
        feature_class as type,
        uid,
        gadm2 AS located_at
    FROM
        gnis g,
        data
    WHERE
        %(layer)s = 'gnis' AND
        st_intersects(data.the_geom, g.the_geom)
)

SELECT 
    name,
    layer,
    type,
    uid,
    located_at
FROM 
    localities
GROUP BY
    name,
    layer,
    type,
    uid,
    located_at
