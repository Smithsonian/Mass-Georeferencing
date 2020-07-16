
CREATE INDEX usgs_nat_struct_name_idx ON usgs_nat_struct USING gin (name gin_trgm_ops);
CREATE INDEX usgs_nat_struct_the_geom_idx ON usgs_nat_struct USING gist (the_geom);


--Add UUID
ALTER TABLE usgs_nat_struct add column uid uuid DEFAULT uuid_generate_v4();
CREATE INDEX usgs_nat_struct_uid_idx ON usgs_nat_struct USING btree(uid);

--Add SRID
UPDATE usgs_nat_struct SET the_geom = ST_MAKEVALID(the_geom) WHERE ST_ISVALID(the_geom) = 'F';
UPDATE usgs_nat_struct SET the_geom = ST_SETSRID(the_geom, 4326);



ALTER TABLE usgs_nat_struct ADD COLUMN gadm2 text;
WITH data AS (
    SELECT 
        w.uid,
        string_agg(g.name_2 || ', ' || g.name_1 || ', ' || g.name_0, '; ') as loc
    FROM 
        usgs_nat_struct w,
        gadm2 g
    WHERE 
        ST_INTERSECTS(w.the_geom, g.the_geom)
    GROUP BY 
        w.uid
)
UPDATE usgs_nat_struct g SET gadm2 = d.loc FROM data d WHERE g.uid = d.uid;
CREATE INDEX usgs_nat_struct_v_gadm2_idx ON usgs_nat_struct USING gin (gadm2 gin_trgm_ops);

