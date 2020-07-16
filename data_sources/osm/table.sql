CREATE EXTENSION IF NOT EXISTS hstore;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


DROP TABLE IF EXISTS osm;

CREATE TABLE osm (
    uid uuid DEFAULT uuid_generate_v4(),
    source_id text,
    name text,
    type text,
    centroid geometry('Point', 4326),
    attributes hstore,
    data_source text,
    gadm2 text,
    country text,
    the_geom geometry('Multipolygon', 4326),
    the_geom_webmercator geometry('Multipolygon', 3857)
);
