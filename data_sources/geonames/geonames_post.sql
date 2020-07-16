create table geonames (
    geonameid integer,
    name text,
    asciiname text,
    alternatenames text,
    latitude float,
    longitude float,
    feature_class text,
    feature_code text,
    country_code text,
    cc2 text,
    admin1_code text,
    admin2_code text,
    admin3_code text,
    admin4_code text,
    population text,
    elevation text,
    dem integer,
    timezone text,
    modification date
);


\copy geonames FROM 'allCountries.txt';


ALTER TABLE geonames ADD COLUMN the_geom geometry;

UPDATE geonames SET the_geom = ST_SETSRID(ST_POINT(longitude, latitude), 4326);

CREATE INDEX geonames_name_idx ON geonames USING BTREE(name);
--For ILIKE queries
CREATE INDEX geonames_name_trgm_idx ON geonames USING gin (name gin_trgm_ops);
CREATE INDEX geonames_geonameid_idx ON geonames USING BTREE(geonameid);
CREATE INDEX geonames_thegeom_idx ON geonames USING GIST(the_geom);
CREATE INDEX geonames_country_idx ON geonames USING BTREE(country_code);

alter table geonames add column uid uuid DEFAULT uuid_generate_v4();
CREATE INDEX geonames_uid_idx ON geonames USING BTREE(uid);


--Alt names in separate table
CREATE TABLE geonames_alt AS (SELECT geonameid, unnest(string_to_array(alternatenames, ',')) as name FROM geonames);


CREATE INDEX geonames_alt_name_idx ON geonames_alt USING BTREE(name);
--For ILIKE queries
CREATE INDEX geonames_alt_name_trgm_idx ON geonames_alt USING gin (name gin_trgm_ops);
CREATE INDEX geonames_alt_geonameid_idx ON geonames_alt USING BTREE(geonameid);

CREATE INDEX geonames_fc_idx ON geonames USING BTREE(feature_code);

--geom_w
/*ALTER TABLE geonames ADD COLUMN the_geom_webmercator geometry;

update geonames set the_geom_webmercator = st_transform(ST_SETSRID(ST_POINT(0.000001, -89.999999), 4326), 3857) where latitude = -90 and longitude = 0;
update geonames set the_geom_webmercator = st_transform(ST_SETSRID(ST_POINT(0.000001, 89.999999), 4326), 3857) where latitude = 90 and longitude = 0;
update geonames set the_geom_webmercator = st_transform(ST_SETSRID(ST_POINT(179.999999, 89.999999), 4326), 3857) where latitude = 90 and longitude = 180;
update geonames set the_geom_webmercator = st_transform(ST_SETSRID(ST_POINT(179.999999, -89.999999), 4326), 3857) where latitude = -90 and longitude = 180;
UPDATE geonames SET the_geom_webmercator = st_transform(the_geom, 3857) WHERE the_geom_webmercator IS NULL;
CREATE INDEX geonames_tgeomw_idx ON geonames USING GIST(the_geom_webmercator);
*/


--Add gadm2 intersection
ALTER TABLE geonames ADD COLUMN gadm2 text;

UPDATE geonames geo SET gadm2 = g.name_2 || ', ' || g.name_1 || ', ' || g.name_0 FROM gadm2 g WHERE ST_INTERSECTS(geo.the_geom, g.the_geom);

CREATE INDEX geonames_gadm2_idx ON geonames USING gin (gadm2 gin_trgm_ops);
