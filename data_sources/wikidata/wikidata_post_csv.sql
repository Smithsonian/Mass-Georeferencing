
UPDATE data_sources SET is_online = 'f' WHERE datasource_id = 'wikidata';
--Delete indices for bulk loading
DROP INDEX IF EXISTS wikidata_records_id_idx;
DROP INDEX IF EXISTS wikidata_records_name_idx;
DROP INDEX IF EXISTS wikidata_records_name_trgm_idx;
DROP INDEX IF EXISTS wikidata_records_the_geom_idx;
DROP INDEX IF EXISTS wikidata_records_uid_idx;
DROP INDEX IF EXISTS wikidata_records_gadm2_idx;
DROP INDEX IF EXISTS wikidata_names_name_idx;
DROP INDEX IF EXISTS wikidata_names_name_trgm_idx;
DROP INDEX IF EXISTS wikidata_names_id_idx;
DROP INDEX IF EXISTS wikidata_names_lang_idx;
DROP INDEX IF EXISTS wikidata_descrip_descr_idx;
DROP INDEX IF EXISTS wikidata_descrip_descr_trgm_idx;
DROP INDEX IF EXISTS wikidata_descrip_id_idx;
DROP INDEX IF EXISTS wikidata_descrip_lang_idx;

--Empty tables
DELETE FROM wikidata_names;
VACUUM wikidata_names;
DELETE FROM wikidata_descrip;
VACUUM wikidata_descrip;
DELETE FROM wikidata_records;
VACUUM wikidata_records;



\copy wikidata_records(source_id, type, name, latitude, longitude) from 'wikidata_records.csv' CSV;
\copy wikidata_names(source_id, language, name) from 'wikidata_names.csv' CSV;
\copy wikidata_descrip(source_id, language, description) from 'wikidata_descrip.csv' CSV;

UPDATE wikidata_records SET the_geom = ST_SETSRID(ST_POINT(longitude, latitude), 4326), gadm2 = g.name_2 || ', ' || g.name_1 || ', ' || g.name_0 FROM gadm2 g WHERE ST_INTERSECTS(g.the_geom, ST_SETSRID(ST_POINT(longitude, latitude), 4326));

CREATE INDEX wikidata_records_id_idx ON wikidata_records USING BTREE(source_id);
CREATE INDEX wikidata_records_uid_idx ON wikidata_records USING BTREE(uid);
CREATE INDEX wikidata_records_name_idx ON wikidata_records USING btree (name);
CREATE INDEX wikidata_records_name_trgm_idx ON wikidata_records USING gin (name gin_trgm_ops);
CREATE INDEX wikidata_records_gadm2_idx ON wikidata_records USING gin (gadm2 gin_trgm_ops);
CREATE INDEX wikidata_records_the_geom_idx ON wikidata_records USING gist(the_geom);
CREATE INDEX wikidata_names_name_trgm_idx ON wikidata_names USING gin (name gin_trgm_ops);
CREATE INDEX wikidata_names_id_idx ON wikidata_names USING btree (source_id);
CREATE INDEX wikidata_names_lang_idx ON wikidata_names USING btree (language);
CREATE INDEX wikidata_descrip_descr_trgm_idx ON wikidata_descrip USING gin (description gin_trgm_ops);
CREATE INDEX wikidata_descrip_id_idx ON wikidata_descrip USING btree (source_id);
CREATE INDEX wikidata_descrip_lang_idx ON wikidata_descrip USING btree (language);
UPDATE data_sources SET is_online = 'T', source_date = CURRENT_DATE WHERE datasource_id = 'wikidata';
UPDATE data_sources SET no_features = w.no_feats FROM (select count(*) as no_feats from wikidata_names) w WHERE datasource_id = 'wikidata';


--View
DROP MATERIALIZED VIEW wikidata;
CREATE MATERIALIZED VIEW wikidata AS
    WITH data AS (
        SELECT 
            uid, source_id, latitude, longitude, name, type, gadm2, 'wikidata' AS data_source, the_geom
        FROM 
            wikidata_records
        UNION
        SELECT 
            r.uid, r.source_id, r.latitude, r.longitude, n.name, r.type, r.gadm2, 'wikidata' AS data_source, r.the_geom
        FROM 
            wikidata_records r, wikidata_names n 
        WHERE 
            r.source_id = n.source_id AND
            n.language = 'en'
        )
    SELECT uid, source_id, latitude, longitude, name, type, gadm2, data_source, the_geom FROM data WHERE name IS NOT NULL GROUP BY uid, source_id, latitude, longitude, name, type, gadm2, data_source, the_geom;
CREATE INDEX wikidata_v_uid_idx ON wikidata USING BTREE(uid);
CREATE INDEX wikidata_v_name_idx ON wikidata USING gin (name gin_trgm_ops);
CREATE INDEX wikidata_v_gadm2_idx ON wikidata USING gin (gadm2 gin_trgm_ops);
CREATE INDEX wikidata_v_geom_idx ON wikidata USING GIST(the_geom);
