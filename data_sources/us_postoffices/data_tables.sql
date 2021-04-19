create table us_postoffices (
    name text,
    altname text,
    origname text,
    state text,
    county1 text,
    county2 text,
    county3 text,
    origcounty text,
    established text,
    discontinued text,
    continuous text,
    stampindex text,
    id text,
    coordinates text,
    duration text,
    gnis_match text,
    gnis_name text,
    gnis_county text,
    gnis_state text,
    gnis_feature_id text,
    gnis_feature_class text,
    gnis_origname text,
    gnis_origcounty text,
    gnis_latitude text,
    gnis_longitude text,
    gnis_elev_in_m text,
    gnis_dist text,
    latitude text,
    longitude text
);

\copy us_postoffices FROM 'us-post-offices.csv' CSV HEADER;

--Drop rows without coords
DELETE FROM us_postoffices where coordinates = 'FALSE';

ALTER TABLE us_postoffices ADD COLUMN the_geom geometry('point', 4326);
ALTER TABLE us_postoffices ADD COLUMN the_geom_webmercator geometry('point', 3857);

UPDATE us_postoffices SET the_geom = ST_SETSRID(ST_POINT(longitude::numeric, latitude::numeric), 4326);
UPDATE us_postoffices SET the_geom_webmercator = st_transform(the_geom, 3857);


CREATE INDEX us_postoffices_name_idx ON us_postoffices USING gin (name gin_trgm_ops);
CREATE INDEX us_postoffices_aname_idx ON us_postoffices USING gin (altname gin_trgm_ops);
CREATE INDEX us_postoffices_oname_idx ON us_postoffices USING gin (origname gin_trgm_ops);
CREATE INDEX us_postoffices_gnisname_idx ON us_postoffices USING gin (gnis_name gin_trgm_ops);


CREATE INDEX us_postoffices_yrfrom_idx ON us_postoffices USING btree (established);
CREATE INDEX us_postoffices_yrto_idx ON us_postoffices USING btree (discontinued);


CREATE INDEX us_postoffices_thegeom_idx ON us_postoffices USING GIST(the_geom);
CREATE INDEX us_postoffices_thegeomw_idx ON us_postoffices USING GIST(the_geom_webmercator);

--Add uuid
alter table us_postoffices add column uid uuid DEFAULT uuid_generate_v4();
CREATE INDEX us_postoffices_uid_idx ON us_postoffices USING BTREE(uid);


--Add gadm2 intersection
ALTER TABLE us_postoffices ADD COLUMN gadm2 text;

UPDATE us_postoffices geo SET gadm2 = g.name_2 || ', ' || g.name_1 || ', ' || g.name_0 FROM gadm2 g WHERE ST_INTERSECTS(geo.the_geom, g.the_geom);

CREATE INDEX us_postoffices_gadm2_idx ON us_postoffices USING gin (gadm2 gin_trgm_ops);
