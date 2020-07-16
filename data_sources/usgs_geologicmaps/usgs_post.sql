
CREATE INDEX usgs_geology_unitname_idx ON usgs_geology USING btree(unit_name);
CREATE INDEX usgs_geology_age_min_idx ON usgs_geology USING btree(age_min);
CREATE INDEX usgs_geology_age_max_idx ON usgs_geology USING btree(age_max);

CREATE INDEX usgs_geology_major1_idx ON usgs_geology USING btree(major1);
CREATE INDEX usgs_geology_major2_idx ON usgs_geology USING btree(major2);
CREATE INDEX usgs_geology_major3_idx ON usgs_geology USING btree(major3);

CREATE INDEX usgs_geology_minor1_idx ON usgs_geology USING btree(minor1);
CREATE INDEX usgs_geology_minor2_idx ON usgs_geology USING btree(minor2);
CREATE INDEX usgs_geology_minor3_idx ON usgs_geology USING btree(minor3);
CREATE INDEX usgs_geology_minor4_idx ON usgs_geology USING btree(minor4);
CREATE INDEX usgs_geology_minor5_idx ON usgs_geology USING btree(minor5);

CREATE INDEX usgs_geology_generalize_idx ON usgs_geology USING btree(generalize);

CREATE INDEX usgs_geology_state_idx ON usgs_geology USING btree(state);

CREATE INDEX usgs_geology_the_geom_idx ON usgs_geology USING gist (the_geom);


--Add UUID
ALTER TABLE usgs_geology add column uid uuid DEFAULT uuid_generate_v4();
CREATE INDEX usgs_geology_uid_idx ON usgs_geology USING btree(uid);

--Add SRID
UPDATE usgs_geology SET the_geom = ST_MAKEVALID(the_geom) WHERE ST_ISVALID(the_geom) = 'F';
UPDATE usgs_geology SET the_geom = ST_MULTI(ST_SETSRID(the_geom, 4326));


ALTER TABLE usgs_geology ADD COLUMN centroid geometry;
UPDATE usgs_geology SET centroid = ST_Centroid(the_geom);
CREATE INDEX usgs_geology_cent_idx ON usgs_geology USING gist (centroid);

ALTER TABLE usgs_geology ADD COLUMN the_geom_webmercator geometry;
UPDATE usgs_geology SET the_geom_webmercator = ST_transform(the_geom, 3857);
CREATE INDEX usgs_geology_the_geomw_idx ON usgs_geology USING gist (the_geom_webmercator);


ALTER TABLE usgs_geology ADD COLUMN gadm2 text;
WITH data AS (
    SELECT 
        w.uid,
        string_agg(g.name_2 || ', ' || g.name_1 || ', ' || g.name_0, '; ') as loc
    FROM 
        usgs_geology w,
        gadm2 g
    WHERE 
        ST_INTERSECTS(w.the_geom, g.the_geom)
    GROUP BY 
        w.uid
)
UPDATE usgs_geology g SET gadm2 = d.loc FROM data d WHERE g.uid = d.uid;

CREATE INDEX usgs_geology_gadm2_idx ON usgs_geology USING btree(gadm2);
