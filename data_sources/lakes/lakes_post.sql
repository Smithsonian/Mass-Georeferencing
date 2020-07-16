
CREATE INDEX global_lakes_name_idx ON global_lakes USING btree(lake_name);
CREATE INDEX global_lakes_type_idx ON global_lakes USING btree(type);
CREATE INDEX global_lakes_country_idx ON global_lakes USING btree(country);
CREATE INDEX global_lakes_nearcity_idx ON global_lakes USING btree(near_city);
CREATE INDEX global_lakes_the_geom_idx ON global_lakes USING gist (the_geom);


--Add UUID
ALTER TABLE global_lakes add column uid uuid DEFAULT uuid_generate_v4();
CREATE INDEX global_lakes_uid_idx ON global_lakes USING btree(uid);

--Add SRID
UPDATE global_lakes SET the_geom = ST_MAKEVALID(the_geom) WHERE ST_ISVALID(the_geom) = 'F';
UPDATE global_lakes SET the_geom = ST_MULTI(ST_SETSRID(the_geom, 4326));

--For ILIKE queries
--CREATE EXTENSION pg_trgm;
CREATE INDEX global_lakes_name_trgm_idx ON global_lakes USING gin (lake_name gin_trgm_ops);

ALTER TABLE global_lakes ADD COLUMN centroid geometry;
UPDATE global_lakes SET centroid = ST_Centroid(the_geom);

ALTER TABLE global_lakes ADD COLUMN the_geom_webmercator geometry;
UPDATE global_lakes SET the_geom_webmercator = ST_transform(the_geom, 3857);
CREATE INDEX global_lakes_the_geomw_idx ON global_lakes USING gist (the_geom_webmercator);

ALTER TABLE global_lakes ADD COLUMN gadm2 text;
WITH data AS (
    SELECT 
        w.uid,
        string_agg(g.name_2 || ', ' || g.name_1 || ', ' || g.name_0, '; ') as loc
    FROM 
        global_lakes w,
        gadm2 g
    WHERE 
        ST_INTERSECTS(w.the_geom, g.the_geom)
    GROUP BY 
        w.uid
)
UPDATE global_lakes g SET gadm2 = d.loc FROM data d WHERE g.uid = d.uid;
