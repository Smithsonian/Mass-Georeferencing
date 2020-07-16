

DELETE FROM usgs_nhd_waterbody WHERE gnis_name IS NULL;
VACUUM usgs_nhd_waterbody;

CREATE INDEX usgs_nhd_waterbody_name_idx ON usgs_nhd_waterbody USING gin (gnis_name gin_trgm_ops);
CREATE INDEX usgs_nhd_waterbody_the_geom_idx ON usgs_nhd_waterbody USING gist (the_geom);


--Add UUID
ALTER TABLE usgs_nhd_waterbody add column uid uuid DEFAULT uuid_generate_v4();
CREATE INDEX usgs_nhd_waterbody_uid_idx ON usgs_nhd_waterbody USING btree(uid);


--Add SRID
UPDATE usgs_nhd_waterbody SET the_geom = ST_MAKEVALID(the_geom) WHERE ST_ISVALID(the_geom) = 'F';
UPDATE usgs_nhd_waterbody SET the_geom = ST_SETSRID(the_geom, 4326);


ALTER TABLE usgs_nhd_waterbody ADD COLUMN gadm2 text;
WITH data AS (
    SELECT 
        w.uid,
        string_agg(g.name_2 || ', ' || g.name_1 || ', ' || g.name_0, '; ') as loc
    FROM 
        usgs_nhd_waterbody w,
        gadm2 g
    WHERE 
        ST_INTERSECTS(w.the_geom, g.the_geom)
    GROUP BY 
        w.uid
)
UPDATE usgs_nhd_waterbody g SET gadm2 = d.loc FROM data d WHERE g.uid = d.uid;
CREATE INDEX usgs_nhd_waterbody_gadm2_idx ON usgs_nhd_waterbody USING gin (gadm2 gin_trgm_ops);
