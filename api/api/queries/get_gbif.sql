WITH record AS (
	SELECT
		gbifid,
		ST_AsGeoJSON(the_geom) as the_geom_json,
		the_geom,
		locality as name,
		'point' as geom_type,
		datasetkey,
		eventdate, 
		decimallatitude AS latitude,
		decimallongitude AS longitude,
		CASE WHEN coordinateuncertaintyinmeters = '' THEN NULL ELSE coordinateuncertaintyinmeters END as coordinateuncertaintyinmeters,
		issue
	FROM
		gbif
	WHERE
		species = '{species}' AND
		gbifid = '{uid}'

	UNION

	SELECT
		gbifid,
		ST_AsGeoJSON(the_geom) as the_geom_json,
		the_geom,
		locality as name,
		'point' as geom_type,
		datasetkey,
		eventdate, 
		decimallatitude AS latitude,
		decimallongitude AS longitude,
		CASE WHEN coordinateuncertaintyinmeters = '' THEN NULL ELSE coordinateuncertaintyinmeters END as coordinateuncertaintyinmeters,
		issue
	FROM
		gbif
	WHERE
		species LIKE '{genus} %' AND
		gbifid = '{uid}'
	)

SELECT
	r.gbifid,
	r.the_geom_json AS the_geom,
	r.name,
	r.geom_type,
	r.coordinateuncertaintyinmeters,
	r.datasetkey, 
	r.eventdate,
	r.latitude,
	r.longitude,
	r.issue,
	d.title as dataset,
	d.organizationname,
	g.name_2 || ', ' || g.name_1 || ', ' || g.name_0 as located_at
FROM
	record r,
	gadm2 g,
	gbif_datasets d
WHERE
	r.datasetkey::uuid = d.datasetkey AND 
	ST_INTERSECTS(r.the_geom, g.the_geom)
