CREATE EXTENSION IF NOT EXISTS hstore;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE osm_antarctica (
    uid uuid DEFAULT uuid_generate_v4(),
    source_id text,
    name text,
    type text,
    centroid geometry('Point', 4326),
    attributes hstore,
    the_geom geometry('Multipolygon', 4326),
    the_geom_webmercator geometry('Multipolygon', 3857)
);

CREATE TABLE osm_northamerica (
    uid uuid DEFAULT uuid_generate_v4(),
    source_id text,
    name text,
    type text,
    centroid geometry('Point', 4326),
    attributes hstore,
    the_geom geometry('Multipolygon', 4326),
    the_geom_webmercator geometry('Multipolygon', 3857)
);

CREATE TABLE osm_centralamerica (
    uid uuid DEFAULT uuid_generate_v4(),
    source_id text,
    name text,
    type text,
    centroid geometry('Point', 4326),
    attributes hstore,
    the_geom geometry('Multipolygon', 4326),
    the_geom_webmercator geometry('Multipolygon', 3857)
);

CREATE TABLE osm_southamerica (
    uid uuid DEFAULT uuid_generate_v4(),
    source_id text,
    name text,
    type text,
    centroid geometry('Point', 4326),
    attributes hstore,
    the_geom geometry('Multipolygon', 4326),
    the_geom_webmercator geometry('Multipolygon', 3857)
);

CREATE TABLE osm_africa (
    uid uuid DEFAULT uuid_generate_v4(),
    source_id text,
    name text,
    type text,
    centroid geometry('Point', 4326),
    attributes hstore,
    the_geom geometry('Multipolygon', 4326),
    the_geom_webmercator geometry('Multipolygon', 3857)
);

CREATE TABLE osm_asia (
    uid uuid DEFAULT uuid_generate_v4(),
    source_id text,
    name text,
    type text,
    centroid geometry('Point', 4326),
    attributes hstore,
    the_geom geometry('Multipolygon', 4326),
    the_geom_webmercator geometry('Multipolygon', 3857)
);

CREATE TABLE osm_australia (
    uid uuid DEFAULT uuid_generate_v4(),
    source_id text,
    name text,
    type text,
    centroid geometry('Point', 4326),
    attributes hstore,
    the_geom geometry('Multipolygon', 4326),
    the_geom_webmercator geometry('Multipolygon', 3857)
);

CREATE TABLE osm_europe (
    uid uuid DEFAULT uuid_generate_v4(),
    source_id text,
    name text,
    type text,
    centroid geometry('Point', 4326),
    attributes hstore,
    the_geom geometry('Multipolygon', 4326),
    the_geom_webmercator geometry('Multipolygon', 3857)
);

