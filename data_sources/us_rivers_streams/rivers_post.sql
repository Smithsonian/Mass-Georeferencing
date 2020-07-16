
CREATE INDEX usa_rivers_name_idx ON usa_rivers USING gin (name gin_trgm_ops);
DELETE FROM usa_rivers WHERE name IS NULL;
CREATE INDEX usa_rivers_the_geom_idx ON usa_rivers USING gist (the_geom);


--Add UUID
ALTER TABLE usa_rivers add column uid uuid DEFAULT uuid_generate_v4();
CREATE INDEX usa_rivers_uid_idx ON usa_rivers USING btree(uid);

--Add SRID
UPDATE usa_rivers SET the_geom = ST_MAKEVALID(the_geom) WHERE ST_ISVALID(the_geom) = 'F';
UPDATE usa_rivers SET the_geom = ST_SETSRID(the_geom, 4326);


ALTER TABLE usa_rivers ADD COLUMN centroid geometry;
UPDATE usa_rivers SET centroid = ST_Centroid(the_geom);


ALTER TABLE usa_rivers ADD COLUMN gadm2 text;
WITH data AS (
    SELECT 
        w.uid,
        string_agg(g.name_2 || ', ' || g.name_1 || ', ' || g.name_0, '; ') as loc
    FROM 
        usa_rivers w,
        gadm2 g
    WHERE 
        ST_INTERSECTS(w.the_geom, g.the_geom)
    GROUP BY 
        w.uid
)
UPDATE usa_rivers g SET gadm2 = d.loc FROM data d WHERE g.uid = d.uid;
CREATE INDEX usa_rivers_gadm2_idx ON usa_rivers USING btree(gadm2);
CREATE INDEX usa_rivers_v_gadm2_idx ON usa_rivers USING gin (gadm2 gin_trgm_ops);

