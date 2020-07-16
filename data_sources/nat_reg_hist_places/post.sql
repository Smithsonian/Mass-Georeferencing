
--usa_histplaces_building_point
CREATE INDEX usa_histplaces_building_point_name_idx ON usa_histplaces_building_point USING gin (resname gin_trgm_ops);
DELETE FROM usa_histplaces_building_point WHERE resname IS NULL;
CREATE INDEX usa_histplaces_building_point_the_geom_idx ON usa_histplaces_building_point USING gist (the_geom);
--
ALTER TABLE usa_histplaces_building_point add column uid uuid DEFAULT uuid_generate_v4();
CREATE INDEX usa_histplaces_building_point_uid_idx ON usa_histplaces_building_point USING btree(uid);
--
UPDATE usa_histplaces_building_point SET the_geom = ST_MAKEVALID(the_geom) WHERE ST_ISVALID(the_geom) = 'F';
UPDATE usa_histplaces_building_point SET the_geom = ST_SETSRID(the_geom, 4326);
--
ALTER TABLE usa_histplaces_building_point ADD COLUMN gadm2 text;
WITH data AS (
    SELECT 
        w.uid,
        string_agg(g.name_2 || ', ' || g.name_1 || ', ' || g.name_0, '; ') as loc
    FROM 
        usa_histplaces_building_point w,
        gadm2 g
    WHERE 
        ST_INTERSECTS(w.the_geom, g.the_geom)
    GROUP BY 
        w.uid
)
UPDATE usa_histplaces_building_point g SET gadm2 = d.loc FROM data d WHERE g.uid = d.uid;
CREATE INDEX usa_histplaces_building_point_gadm2_idx ON usa_histplaces_building_point USING btree(gadm2);






--usa_histplaces_district_poly
CREATE INDEX usa_histplaces_district_poly_name_idx ON usa_histplaces_district_poly USING gin (resname gin_trgm_ops);
DELETE FROM usa_histplaces_district_poly WHERE resname IS NULL;
CREATE INDEX usa_histplaces_district_poly_the_geom_idx ON usa_histplaces_district_poly USING gist (the_geom);
--
ALTER TABLE usa_histplaces_district_poly add column uid uuid DEFAULT uuid_generate_v4();
CREATE INDEX usa_histplaces_district_poly_uid_idx ON usa_histplaces_district_poly USING btree(uid);
--
UPDATE usa_histplaces_district_poly SET the_geom = ST_MAKEVALID(the_geom) WHERE ST_ISVALID(the_geom) = 'F';
UPDATE usa_histplaces_district_poly SET the_geom = ST_SETSRID(the_geom, 4326);
--
ALTER TABLE usa_histplaces_district_poly ADD COLUMN gadm2 text;
WITH data AS (
    SELECT 
        w.uid,
        string_agg(g.name_2 || ', ' || g.name_1 || ', ' || g.name_0, '; ') as loc
    FROM 
        usa_histplaces_district_poly w,
        gadm2 g
    WHERE 
        ST_INTERSECTS(w.the_geom, g.the_geom)
    GROUP BY 
        w.uid
)
UPDATE usa_histplaces_district_poly g SET gadm2 = d.loc FROM data d WHERE g.uid = d.uid;
CREATE INDEX usa_histplaces_district_poly_gadm2_idx ON usa_histplaces_district_poly USING btree(gadm2);





--usa_histplaces_site_poly
CREATE INDEX usa_histplaces_site_poly_name_idx ON usa_histplaces_site_poly USING gin (resname gin_trgm_ops);
DELETE FROM usa_histplaces_site_poly WHERE resname IS NULL;
CREATE INDEX usa_histplaces_site_poly_the_geom_idx ON usa_histplaces_site_poly USING gist (the_geom);
--
ALTER TABLE usa_histplaces_site_poly add column uid uuid DEFAULT uuid_generate_v4();
CREATE INDEX usa_histplaces_site_poly_uid_idx ON usa_histplaces_site_poly USING btree(uid);
--
UPDATE usa_histplaces_site_poly SET the_geom = ST_MAKEVALID(the_geom) WHERE ST_ISVALID(the_geom) = 'F';
UPDATE usa_histplaces_site_poly SET the_geom = ST_SETSRID(the_geom, 4326);
--
ALTER TABLE usa_histplaces_site_poly ADD COLUMN gadm2 text;
WITH data AS (
    SELECT 
        w.uid,
        string_agg(g.name_2 || ', ' || g.name_1 || ', ' || g.name_0, '; ') as loc
    FROM 
        usa_histplaces_site_poly w,
        gadm2 g
    WHERE 
        ST_INTERSECTS(w.the_geom, g.the_geom)
    GROUP BY 
        w.uid
)
UPDATE usa_histplaces_site_poly g SET gadm2 = d.loc FROM data d WHERE g.uid = d.uid;
CREATE INDEX usa_histplaces_site_poly_gadm2_idx ON usa_histplaces_site_poly USING btree(gadm2);






--usa_histplaces_site_point
CREATE INDEX usa_histplaces_site_point_name_idx ON usa_histplaces_site_point USING gin (resname gin_trgm_ops);
DELETE FROM usa_histplaces_site_point WHERE resname IS NULL;
CREATE INDEX usa_histplaces_site_point_the_geom_idx ON usa_histplaces_site_point USING gist (the_geom);
--
ALTER TABLE usa_histplaces_site_point add column uid uuid DEFAULT uuid_generate_v4();
CREATE INDEX usa_histplaces_site_point_uid_idx ON usa_histplaces_site_point USING btree(uid);
--
UPDATE usa_histplaces_site_point SET the_geom = ST_MAKEVALID(the_geom) WHERE ST_ISVALID(the_geom) = 'F';
UPDATE usa_histplaces_site_point SET the_geom = ST_SETSRID(the_geom, 4326);
--
ALTER TABLE usa_histplaces_site_point ADD COLUMN gadm2 text;
WITH data AS (
    SELECT 
        w.uid,
        string_agg(g.name_2 || ', ' || g.name_1 || ', ' || g.name_0, '; ') as loc
    FROM 
        usa_histplaces_site_point w,
        gadm2 g
    WHERE 
        ST_INTERSECTS(w.the_geom, g.the_geom)
    GROUP BY 
        w.uid
)
UPDATE usa_histplaces_site_point g SET gadm2 = d.loc FROM data d WHERE g.uid = d.uid;
CREATE INDEX usa_histplaces_site_point_gadm2_idx ON usa_histplaces_site_point USING btree(gadm2);





--usa_histplaces_structure_point
CREATE INDEX usa_histplaces_structure_point_name_idx ON usa_histplaces_structure_point USING gin (resname gin_trgm_ops);
DELETE FROM usa_histplaces_structure_point WHERE resname IS NULL;
CREATE INDEX usa_histplaces_structure_point_the_geom_idx ON usa_histplaces_structure_point USING gist (the_geom);
--
ALTER TABLE usa_histplaces_structure_point add column uid uuid DEFAULT uuid_generate_v4();
CREATE INDEX usa_histplaces_structure_point_uid_idx ON usa_histplaces_structure_point USING btree(uid);
--
UPDATE usa_histplaces_structure_point SET the_geom = ST_MAKEVALID(the_geom) WHERE ST_ISVALID(the_geom) = 'F';
UPDATE usa_histplaces_structure_point SET the_geom = ST_SETSRID(the_geom, 4326);
--
ALTER TABLE usa_histplaces_structure_point ADD COLUMN gadm2 text;
WITH data AS (
    SELECT 
        w.uid,
        string_agg(g.name_2 || ', ' || g.name_1 || ', ' || g.name_0, '; ') as loc
    FROM 
        usa_histplaces_structure_point w,
        gadm2 g
    WHERE 
        ST_INTERSECTS(w.the_geom, g.the_geom)
    GROUP BY 
        w.uid
)
UPDATE usa_histplaces_structure_point g SET gadm2 = d.loc FROM data d WHERE g.uid = d.uid;
CREATE INDEX usa_histplaces_structure_point_gadm2_idx ON usa_histplaces_structure_point USING btree(gadm2);




--points
ALTER TABLE usa_histplaces_building_point ADD COLUMN uncertainty_m text;
UPDATE usa_histplaces_building_point SET uncertainty_m = '12' WHERE src_accu = '+/- 12 meters';

ALTER TABLE usa_histplaces_site_point ADD COLUMN uncertainty_m text;
UPDATE usa_histplaces_site_point SET uncertainty_m = '12' WHERE src_accu = '+/- 12 meters';

ALTER TABLE usa_histplaces_structure_point ADD COLUMN uncertainty_m text;
UPDATE usa_histplaces_structure_point SET uncertainty_m = '12' WHERE src_accu = '+/- 12 meters';

--polys
ALTER TABLE usa_histplaces_district_poly ADD COLUMN uncertainty_m text;
UPDATE usa_histplaces_district_poly SET uncertainty_m = '12' WHERE src_accu = '+/- 12 meters';
UPDATE usa_histplaces_district_poly SET uncertainty_m = '5' WHERE src_accu = '+/- 5 meters';
UPDATE usa_histplaces_district_poly SET uncertainty_m = '0.44' WHERE src_accu = '+/- 0.44m';

ALTER TABLE usa_histplaces_site_poly ADD COLUMN uncertainty_m text;
UPDATE usa_histplaces_site_poly SET uncertainty_m = '12' WHERE src_accu = '+/- 12 meters';
UPDATE usa_histplaces_site_poly SET uncertainty_m = '5' WHERE src_accu = '+/- 5 meters';
UPDATE usa_histplaces_site_poly SET uncertainty_m = '2' WHERE src_accu = '+/- 2 meters';
 
 




--VIEW
CREATE MATERIALIZED VIEW usa_histplaces_points AS 
    SELECT 
        uid, resname AS name, gadm2 AS stateprovince, NULL AS type, uncertainty_m, 'usa_histplaces_points' AS data_source, the_geom 
    FROM 
        usa_histplaces_building_point 
    UNION 
    SELECT 
        uid, resname AS name, gadm2 AS stateprovince, NULL AS type, uncertainty_m, 'usa_histplaces_points' AS data_source, the_geom 
    FROM 
        usa_histplaces_site_point
    UNION 
    SELECT 
        uid, resname AS name, gadm2 AS stateprovince, NULL AS type, uncertainty_m, 'usa_histplaces_points' AS data_source, the_geom 
    FROM 
        usa_histplaces_structure_point;


CREATE INDEX usa_histplaces_points_v_geom_idx ON usa_histplaces_points USING GIST(the_geom);
CREATE INDEX usa_histplaces_points_v_gname_idx ON usa_histplaces_points USING gin (name gin_trgm_ops);
CREATE INDEX usa_histplaces_points_v_gadm2_idx ON usa_histplaces_points USING gin (stateprovince gin_trgm_ops);
CREATE INDEX usa_histplaces_points_v_uid_idx ON usa_histplaces_points USING BTREE(uid);




CREATE MATERIALIZED VIEW usa_histplaces_poly AS 
    SELECT 
        uid, resname AS name, gadm2 AS stateprovince, NULL AS type, uncertainty_m, 'usa_histplaces_poly' AS data_source, the_geom
    FROM 
        usa_histplaces_district_poly 
    UNION 
    SELECT 
        uid, resname AS name, gadm2 AS stateprovince, NULL AS type, uncertainty_m, 'usa_histplaces_poly' AS data_source, the_geom 
    FROM 
        usa_histplaces_site_poly;


CREATE INDEX usa_histplaces_poly_v_geom_idx ON usa_histplaces_poly USING GIST(the_geom);
CREATE INDEX usa_histplaces_poly_v_gname_idx ON usa_histplaces_poly USING gin (name gin_trgm_ops);
CREATE INDEX usa_histplaces_poly_v_gadm2_idx ON usa_histplaces_poly USING gin (stateprovince gin_trgm_ops);
CREATE INDEX usa_histplaces_poly_v_uid_idx ON usa_histplaces_poly USING BTREE(uid);



