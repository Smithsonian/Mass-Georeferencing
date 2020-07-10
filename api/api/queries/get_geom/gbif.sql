
WITH data as 
(
	SELECT
		the_geom as point_geom,
		ST_AsGeoJSON(the_geom) as the_geom,
		gbifid,
		locality as name,
		st_x(the_geom) as longitude,
		st_y(the_geom) as latitude,
		st_x(the_geom) as xmin,
		st_x(the_geom) as xmax,
		st_y(the_geom) as ymin,
		st_y(the_geom) as ymax
	FROM
		gbif
	WHERE
		species = '{species}' AND
		gbifid = '{uid}'

	UNION

	SELECT
		the_geom as point_geom,
		ST_AsGeoJSON(the_geom) as the_geom,
		gbifid,
		locality as name,
		st_x(the_geom) as longitude,
		st_y(the_geom) as latitude,
		st_x(the_geom) as xmin,
		st_x(the_geom) as xmax,
		st_y(the_geom) as ymin,
		st_y(the_geom) as ymax
	FROM
		gbif
	WHERE
		species LIKE '{genus} %' AND
		gbifid = '{uid}'

)

SELECT
	d.the_geom,
	null as min_bound_radius_m,
	null as the_geom_extent,
	d.gbifid as uid,
	d.name,
	null as type,
	g.name_2 ||  ', ' || g.name_1 ||  ', ' || g.name_0 as parent,
	d.longitude,
	d.latitude,
	d.xmin,
	d.xmax,
	d.ymin,
	d.ymax,
	'point' as geom_type,
	g.name_2 ||  ', ' || g.name_1 ||  ', ' || g.name_0 as located_at,
	'gbif' as layer
FROM
	data d LEFT JOIN gadm2 g ON 
			st_intersects(d.point_geom, g.the_geom)
