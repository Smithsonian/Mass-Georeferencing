CREATE TABLE wikidata_records (
		uid uuid DEFAULT uuid_generate_v4(),
		source_id text, 
		type text, 
		name text, 
		latitude float, 
		longitude float, 
		the_geom geometry(Geometry, 4326),
		the_geom_webmercator geometry(Geometry, 3857)
		);


CREATE TABLE wikidata_names (
	source_id text, 
	language text, 
	name text
	);


CREATE TABLE wikidata_descrip (
	source_id text, 
	language text, 
	description text);


