SELECT
    uid,
    name_0 as name,
    'gadm0' as layer,
    'NA' as parent,
    'Country' as type,
    0 as sortby,
    round(st_x(centroid)::numeric, 5) as longitude,
    round(st_y(centroid)::numeric, 5) as latitude
FROM
    gadm0
WHERE
    name_0 ILIKE %(string)s
UNION
SELECT
    uid,
    name_1 as name,
    'gadm1' as layer,
    name_0 as parent,
    engtype_1 as type,
    1 as sortby,
    round(st_x(centroid)::numeric, 5) as longitude,
    round(st_y(centroid)::numeric, 5) as latitude
FROM
    gadm1
WHERE
    name_1 ILIKE %(string)s
UNION
SELECT
    uid,
    name_2 as name,
    'gadm2' as layer,
    concat(name_1 || ', ' || name_0) as parent,
    engtype_2 as type,
    2 as sortby,
    round(st_x(centroid)::numeric, 5) as longitude,
    round(st_y(centroid)::numeric, 5) as latitude
FROM
    gadm2
WHERE
    name_2 ILIKE %(string)s
UNION
SELECT
    uid,
    name_3 as name,
    'gadm3' as layer,
    concat(name_2 || ', ' || name_1 || ', ' || name_0) as parent,
    engtype_3 as type,
    3 as sortby,
    round(st_x(centroid)::numeric, 5) as longitude,
    round(st_y(centroid)::numeric, 5) as latitude
FROM
    gadm3
WHERE
    name_3 ILIKE %(string)s
UNION
SELECT
    uid,
    name_4 as name,
    'gadm4' as layer,
    concat(name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0) as parent,
    engtype_4 as type,
    4 as sortby,
    round(st_x(centroid)::numeric, 5) as longitude,
    round(st_y(centroid)::numeric, 5) as latitude
FROM
    gadm4
WHERE
    name_4 ILIKE %(string)s
UNION
SELECT
    uid,
    name_5 as name,
    'gadm5' as layer,
    concat(name_4 || ', ' || name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0) as parent,
    engtype_5 as type,
    5 as sortby,
    round(st_x(centroid)::numeric, 5) as longitude,
    round(st_y(centroid)::numeric, 5) as latitude
FROM
    gadm5
WHERE
    name_5 ILIKE %(string)s
UNION
SELECT
    w.uid,
    w.name,
    'wdpa_polygons' as layer,
    c.country as parent,
    w.desig_eng as type,
    10 as sortby,
    round(st_x(centroid)::numeric, 5) as longitude,
    round(st_y(centroid)::numeric, 5) as latitude
FROM
    wdpa_polygons w LEFT JOIN countries_iso c ON (w.iso3 = c.iso3)
WHERE
    w.name ILIKE %(string)s
UNION
SELECT
    w.uid,
    w.name,
    'wdpa_points' as layer,
    c.country as parent,
    w.desig_eng as type,
    10 as sortby,
    round(st_x(the_geom)::numeric, 5) as longitude,
    round(st_y(the_geom)::numeric, 5) as latitude
FROM
    wdpa_points w LEFT JOIN countries_iso c ON (w.iso3 = c.iso3)
WHERE
    w.name ILIKE %(string)s

UNION

SELECT
    g.uid,
    g.name,
    'geonames' as layer,
    c.country as parent,
    gc.name as type,
    20 as sortby,
    longitude,
    latitude
FROM
    geonames g
        LEFT JOIN geonames_fc gc
            ON (g.feature_code = gc.code)
        LEFT JOIN countries_iso c
            ON (g.country_code = c.iso2)
WHERE
    g.name ILIKE %(string)s

UNION

SELECT
    g.uid,
    g.name,
    'geonames' as layer,
    c.country as parent,
    gc.name as type,
    20 as sortby,
    longitude,
    latitude
FROM
    geonames g
        LEFT JOIN geonames_fc gc
            ON (g.feature_code = gc.code)
        LEFT JOIN geonames_alt ga
            ON (g.geonameid = ga.geonameid)
        LEFT JOIN countries_iso c
            ON (g.country_code = c.iso2)
WHERE
    ga.name ILIKE %(string)s

UNION

SELECT
    uid,
    feature_name as name,
    'gnis' as layer,
    concat(county_name, ', ', state_alpha) as parent,
    feature_class as type,
    20 as sortby,
    prim_long_dec as longitude,
    prim_lat_dec as latitude
FROM
    gnis
WHERE
    feature_name ILIKE %(string)s

UNION

SELECT
    uid,
    full_name_nd_ro as name,
    'gns' as layer,
    gadm2 as parent,
    null as type,
    20 as sortby,
    "long" as longitude,
    lat as latitude
FROM
    gns
WHERE
    full_name_nd_ro ILIKE %(string)s

UNION

SELECT
    r.uid,
    r.name as name,
    'wikidata' as layer,
    NULL as parent,
    d.description as type,
    30 as sortby,
    r.longitude,
    r.latitude
FROM
    wikidata_records r 
        LEFT JOIN wikidata_descrip d ON (r.id = d.id),
    wikidata_names n
WHERE
    r.id = n.id AND
    n.name ILIKE %(string)s

UNION

SELECT
    uid,
    name as name,
    'osm' as layer,
    NULL as parent,
    type,
    30 as sortby,
    round(st_x(centroid)::numeric, 5) as longitude,
    round(st_y(centroid)::numeric, 5) as latitude
FROM
    osm
WHERE
    name ILIKE %(string)s


UNION

SELECT
    uid,
    name as name,
    'usa_rivers' as layer,
    gadm2 as parent,
    feature AS type,
    30 as sortby,
    round(st_x(centroid)::numeric, 5) as longitude,
    round(st_y(centroid)::numeric, 5) as latitude
FROM
    usa_rivers
WHERE
    name ILIKE %(string)s



UNION

SELECT
    uid,
    name as name,
    'usa_histplaces_points' as layer,
    stateprovince as parent,
    null AS type,
    30 as sortby,
    round(st_x(the_geom)::numeric, 5) as longitude,
    round(st_y(the_geom)::numeric, 5) as latitude
FROM
    usa_histplaces_points
WHERE
    name ILIKE %(string)s



UNION

SELECT
    uid,
    name as name,
    'usa_histplaces_poly' as layer,
    stateprovince as parent,
    null AS type,
    30 as sortby,
    round(st_x(st_centroid(the_geom))::numeric, 5) as longitude,
    round(st_y(st_centroid(the_geom))::numeric, 5) as latitude
FROM
    usa_histplaces_poly
WHERE
    name ILIKE %(string)s


UNION


SELECT
    uid,
    name as name,
    'usgs_nat_struct' as layer,
    gadm2 as parent,
    null AS type,
    30 as sortby,
    round(st_x(the_geom)::numeric, 5) as longitude,
    round(st_y(the_geom)::numeric, 5) as latitude
FROM
    usgs_nat_struct
WHERE
    name ILIKE %(string)s



  UNION 

  SELECT
    uid,
    name as name,
    'topo_map_points' as layer,
    gadm2 as parent,
    type,
    30 as sortby,
    round(st_x(the_geom)::numeric, 5) as longitude,
    round(st_y(the_geom)::numeric, 5) as latitude
  FROM 
    topo_map_points
  WHERE 
    name ILIKE %(string)s

   UNION 

  SELECT
    uid,
    name as name,
    'topo_map_polygons' as layer,
    gadm2 as parent,
    type,
    30 as sortby,
    round(st_x(st_centroid(m.the_geom))::numeric, 5) as longitude,
    round(st_y(st_centroid(m.the_geom))::numeric, 5) as latitude,
  FROM 
    topo_map_polygons
  WHERE 
    name ILIKE %(string)s

