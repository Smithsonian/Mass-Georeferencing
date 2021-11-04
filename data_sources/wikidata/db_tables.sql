CREATE TABLE wikidata_records (
		uid uuid DEFAULT uuid_generate_v4(),
		source_id text, 
		type text, 
		name text, 
		latitude float, 
		longitude float,
		gadm1 text,
		the_geom geometry(Geometry, 4326)
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

