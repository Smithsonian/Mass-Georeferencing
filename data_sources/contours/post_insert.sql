
--usa_contours
ALTER TABLE usa_contours add column uid uuid DEFAULT uuid_generate_v4();
CREATE INDEX usa_contours_uid_idx ON usa_contours USING BTREE(uid);

UPDATE usa_contours SET the_geom = ST_MakeValid(the_geom) WHERE ST_ISVALID(the_geom) = 'f';
UPDATE usa_contours SET the_geom = ST_SETSRID(the_geom, 4326);

CREATE INDEX usa_contours_contour_idx ON usa_contours USING BTREE(contour);
CREATE INDEX usa_contours_geom_idx ON usa_contours USING GIST(the_geom);
