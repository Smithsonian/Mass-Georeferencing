WITH data1 AS
    (   
        SELECT 
            st_transform(st_setsrid(
                st_point(
                    %(lng)s, %(lat)s
                    ), 
                4326), 
                '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs') as the_geom,
            u.zone as utm_zone
        FROM
            utm_zones u
        WHERE
            st_intersects(st_setsrid(st_point(%(lng)s, %(lat)s), 4326), u.the_geom)
    ),

data AS
    (
        SELECT 
            st_buffer(the_geom, %(radius)s) as the_geom_buffer,
            utm_zone,
            %(year)s || '-01-01' as min_date,
            %(year)s || '-12-31' as max_date
        FROM
            data1
    ),

results AS (
        SELECT
            h.uid,
            h.full_name, 
            h.state_terr as stateprovince,
            h.start_date::date,
            h.end_date::date,
            h.change,
            h.citation,
            st_distance (d1.the_geom, st_transform(h.the_geom, '+proj=utm +zone=' || d.utm_zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs')) AS distance_m
        FROM
            data d,
            data1 d1,
            hist_counties h
        WHERE 
            %(layer)s = 'hist_counties' AND
            st_intersects(st_transform(h.the_geom, '+proj=utm +zone=' || d.utm_zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs'), d.the_geom_buffer) AND
            h.start_date <= d.min_date::date AND
            h.end_date >= d.max_date::date
    )

SELECT 
    * 
FROM
    results
ORDER BY distance_m DESC
LIMIT 1
