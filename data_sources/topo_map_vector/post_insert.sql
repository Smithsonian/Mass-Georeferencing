
--topo_map_vector_derivednames
CREATE INDEX topo_map_vector_derivednames_geom_idx ON topo_map_vector_derivednames USING GIST(the_geom);
CREATE INDEX topo_map_vector_derivednames_name_idx ON topo_map_vector_derivednames USING BTREE(gaz_name);
CREATE INDEX topo_map_vector_derivednames_feat_idx ON topo_map_vector_derivednames USING BTREE(gaz_featur);
ALTER TABLE topo_map_vector_derivednames add column uid uuid DEFAULT uuid_generate_v4();
CREATE INDEX topo_map_vector_derivednames_uid_idx ON topo_map_vector_derivednames USING BTREE(uid);
UPDATE topo_map_vector_derivednames SET the_geom = ST_MakeValid(the_geom) WHERE ST_ISVALID(the_geom) = 'f';
--Add gadm2 intersection
ALTER TABLE topo_map_vector_derivednames ADD COLUMN gadm2 text;
UPDATE topo_map_vector_derivednames geo SET gadm2 = g.name_2 || ', ' || g.name_1 || ', ' || g.name_0 FROM gadm2 g WHERE ST_INTERSECTS(geo.the_geom, g.the_geom);
CREATE INDEX topo_map_vector_derivednames_gadm2_idx ON topo_map_vector_derivednames USING BTREE(gadm2);



--topo_map_vector_county
CREATE INDEX topo_map_vector_county_geom_idx ON topo_map_vector_county USING GIST(the_geom);
CREATE INDEX topo_map_vector_county_name_idx ON topo_map_vector_county USING BTREE(county_nam);
CREATE INDEX topo_map_vector_state_name_idx ON topo_map_vector_county USING BTREE(state_name);
ALTER TABLE topo_map_vector_county add column uid uuid DEFAULT uuid_generate_v4();
CREATE INDEX topo_map_vector_county_uid_idx ON topo_map_vector_county USING BTREE(uid);
UPDATE topo_map_vector_county SET the_geom = ST_MakeValid(the_geom) WHERE ST_ISVALID(the_geom) = 'f';
--Add gadm2 intersection
ALTER TABLE topo_map_vector_county ADD COLUMN gadm2 text;
UPDATE topo_map_vector_county geo SET gadm2 = g.name_2 || ', ' || g.name_1 || ', ' || g.name_0 FROM gadm2 g WHERE ST_INTERSECTS(geo.the_geom, g.the_geom);
CREATE INDEX topo_map_vector_county_gadm2_idx ON topo_map_vector_county USING BTREE(gadm2);


--topo_map_vector_firstdiv
/*CREATE INDEX topo_map_vector_firstdiv_geom_idx ON topo_map_vector_firstdiv USING GIST(the_geom);
ALTER TABLE topo_map_vector_firstdiv add column uid uuid DEFAULT uuid_generate_v4();
CREATE INDEX topo_map_vector_firstdiv_uid_idx ON topo_map_vector_firstdiv USING BTREE(uid);
UPDATE topo_map_vector_firstdiv SET the_geom = ST_MakeValid(the_geom) WHERE ST_ISVALID(the_geom) = 'f';
--Add gadm2 intersection
ALTER TABLE topo_map_vector_firstdiv ADD COLUMN gadm2 text;
UPDATE topo_map_vector_firstdiv geo SET gadm2 = g.name_2 || ', ' || g.name_1 || ', ' || g.name_0 FROM gadm2 g WHERE ST_INTERSECTS(geo.the_geom, g.the_geom);
CREATE INDEX geonames_gadm2_idx ON topo_map_vector_firstdiv USING BTREE(gadm2);*/



--topo_map_vector_waterbody
CREATE INDEX topo_map_vector_waterbody_geom_idx ON topo_map_vector_waterbody USING GIST(the_geom);
CREATE INDEX topo_map_vector_waterbody_name_idx ON topo_map_vector_waterbody USING BTREE(gnis_name);
ALTER TABLE topo_map_vector_waterbody add column uid uuid DEFAULT uuid_generate_v4();
CREATE INDEX topo_map_vector_waterbody_uid_idx ON topo_map_vector_waterbody USING BTREE(uid);
UPDATE topo_map_vector_waterbody SET the_geom = ST_MakeValid(the_geom) WHERE ST_ISVALID(the_geom) = 'f';
--Add gadm2 intersection
ALTER TABLE topo_map_vector_waterbody ADD COLUMN gadm2 text;
UPDATE topo_map_vector_waterbody geo SET gadm2 = g.name_2 || ', ' || g.name_1 || ', ' || g.name_0 FROM gadm2 g WHERE ST_INTERSECTS(geo.the_geom, g.the_geom);
CREATE INDEX topo_map_vector_waterbody_gadm2_idx ON topo_map_vector_waterbody USING BTREE(gadm2);





--topo_map_vector_elev
DELETE FROM topo_map_vector_elev WHERE RIGHT(contourele::int::text, 2) != '50' AND RIGHT(contourele::int::text, 2) != '00';
--
CREATE INDEX topo_map_vector_elev_geom_idx ON topo_map_vector_elev USING GIST(the_geom);
CREATE INDEX topo_map_vector_elev_elev_idx ON topo_map_vector_elev USING BTREE(contourele);
ALTER TABLE topo_map_vector_elev add column uid uuid DEFAULT uuid_generate_v4();
CREATE INDEX topo_map_vector_elev_uid_idx ON topo_map_vector_elev USING BTREE(uid);
UPDATE topo_map_vector_elev SET the_geom = ST_MakeValid(the_geom) WHERE ST_ISVALID(the_geom) = 'f';
--Add gadm2 intersection
ALTER TABLE topo_map_vector_elev ADD COLUMN gadm2 text;
UPDATE topo_map_vector_elev geo SET gadm2 = g.name_2 || ', ' || g.name_1 || ', ' || g.name_0 FROM gadm2 g WHERE ST_INTERSECTS(geo.the_geom, g.the_geom);
CREATE INDEX geonames_gadm2_idx ON topo_map_vector_elev USING BTREE(gadm2);




--VIEW
DROP MATERIALIZED VIEW topo_map_polygons;
CREATE MATERIALIZED VIEW topo_map_polygons AS 
    SELECT 
        gid as source_id, uid, county_nam AS name, gadm2 AS stateprovince, 'county' AS type, 'topo_map_polygons' AS data_source, the_geom
    FROM 
        topo_map_vector_county 
    UNION 
    SELECT 
        gid as source_id, uid, gnis_name AS name, gadm2 AS stateprovince, NULL AS type, 'topo_map_polygons' AS data_source, the_geom 
    FROM 
        topo_map_vector_waterbody;

CREATE INDEX topo_map_vector_v_geom_idx ON topo_map_polygons USING GIST(the_geom);
CREATE INDEX topo_map_vector_v_name_idx ON topo_map_polygons USING BTREE(name);
CREATE INDEX topo_map_vector_v_uid_idx ON topo_map_polygons USING BTREE(uid);
CREATE INDEX topo_map_vector_v_source_id_idx ON topo_map_polygons USING BTREE(source_id);


DROP MATERIALIZED VIEW topo_map_points;
CREATE MATERIALIZED VIEW topo_map_points AS 
    SELECT 
        gid as source_id, uid, gaz_name AS name, gadm2 AS stateprovince, gaz_featur AS type, 'topo_map_points' AS data_source, (ST_Dump(the_geom)).geom as the_geom 
    FROM 
        topo_map_vector_derivednames;

CREATE INDEX topo_map_pts_v_geom_idx ON topo_map_points USING GIST(the_geom);
CREATE INDEX topo_map_pts_v_name_idx ON topo_map_points USING BTREE(name);
CREATE INDEX topo_map_pts_v_uid_idx ON topo_map_points USING BTREE(uid);
CREATE INDEX topo_map_pts_v_source_id_idx ON topo_map_points USING BTREE(source_id);
