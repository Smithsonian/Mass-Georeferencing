
--View
DROP MATERIALIZED VIEW wikidata;
CREATE MATERIALIZED VIEW wikidata AS
    WITH data AS (
        SELECT 
            uid, source_id, latitude, longitude, name, gadm2, 'wikidata' AS data_source, the_geom
        FROM 
            wikidata_records
        UNION
        SELECT 
            r.uid, r.source_id, r.latitude, r.longitude, n.name, r.gadm2, 'wikidata' AS data_source, r.the_geom
        FROM 
            wikidata_records r, wikidata_names n 
        WHERE 
            r.source_id = n.source_id AND
            n.language = 'en'
        )
    SELECT uid, source_id, latitude, longitude, name, gadm2, data_source, the_geom FROM data WHERE name IS NOT NULL GROUP BY uid, source_id, name, gadm2, data_source, the_geom;
CREATE INDEX wikidata_v_uid_idx ON wikidata USING BTREE(uid);
CREATE INDEX wikidata_v_name_idx ON wikidata USING gin (name gin_trgm_ops);
CREATE INDEX wikidata_v_gadm2_idx ON wikidata USING gin (gadm2 gin_trgm_ops);
CREATE INDEX wikidata_v_geom_idx ON wikidata USING GIST(the_geom);
