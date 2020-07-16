
CREATE INDEX wdpa_points_name_idx ON wdpa_points USING btree(name);
CREATE INDEX wdpa_points_wdpaid_idx ON wdpa_points USING btree(wdpaid);
CREATE INDEX wdpa_points_iso3_idx ON wdpa_points USING btree(iso3);

CREATE INDEX wdpa_polygons_name_idx ON wdpa_polygons USING btree(name);
CREATE INDEX wdpa_polygons_wdpaid_idx ON wdpa_polygons USING btree(wdpaid);
CREATE INDEX wdpa_polygons_iso3_idx ON wdpa_polygons USING btree(iso3);
CREATE INDEX wdpa_polygons_the_geom_idx ON wdpa_polygons USING gist (the_geom);


--Set WDPAID as int
ALTER TABLE wdpa_points
	ALTER COLUMN wdpaid TYPE integer USING round(wdpaid, 0)::int;
ALTER TABLE wdpa_polygons
	ALTER COLUMN wdpaid TYPE integer USING round(wdpaid, 0)::int;

--Add UUID
ALTER TABLE wdpa_points add column uid uuid DEFAULT uuid_generate_v4();
CREATE INDEX wdpa_points_uid_idx ON wdpa_points USING btree(uid);
ALTER TABLE wdpa_polygons add column uid uuid DEFAULT uuid_generate_v4();
CREATE INDEX wdpa_polygons_uid_idx ON wdpa_polygons USING btree(uid);

--Add SRID
UPDATE wdpa_points SET the_geom = ST_SETSRID(the_geom, 4326);
UPDATE wdpa_polygons SET the_geom = ST_MAKEVALID(the_geom) WHERE ST_ISVALID(the_geom) = 'F';
UPDATE wdpa_polygons SET the_geom = ST_MULTI(ST_SETSRID(the_geom, 4326));

--For ILIKE queries
--CREATE EXTENSION pg_trgm;
CREATE INDEX wdpa_points_name_trgm_idx ON wdpa_points USING gin (name gin_trgm_ops);
CREATE INDEX wdpa_polygons_name_trgm_idx ON wdpa_polygons USING gin (name gin_trgm_ops);

ALTER TABLE wdpa_polygons ADD COLUMN centroid geometry;
UPDATE wdpa_polygons SET centroid = ST_Centroid(the_geom);
/*
ALTER TABLE wdpa_polygons ADD COLUMN the_geom_simp geometry;
UPDATE wdpa_polygons SET the_geom_simp = ST_Simplify(the_geom, 0.05);
CREATE INDEX wdpa_polygons_the_geom_simp_idx ON wdpa_polygons USING gist (the_geom_simp);

ALTER TABLE wdpa_polygons ADD COLUMN the_geom_webmercator geometry;
UPDATE wdpa_polygons SET the_geom_webmercator = ST_transform(the_geom, 3857);
CREATE INDEX wdpa_polygons_the_geomw_idx ON wdpa_polygons USING gist (the_geom_webmercator);*/


/*ALTER TABLE wdpa_polygons ADD COLUMN bbox geometry;
UPDATE wdpa_polygons SET bbox = ST_Envelope(the_geom);
CREATE INDEX wdpa_polygons_bbox_idx ON wdpa_polygons USING gist (bbox);
*/

--Set each point as single point
ALTER TABLE wdpa_points ADD COLUMN the_geom_p geometry('Point', 4326);
WITH data AS (
        SELECT 
            wdpaid, 
            (ST_Dump(the_geom)).geom as the_geom 
        FROM 
            wdpa_points
        )
    UPDATE 
        wdpa_points w 
    SET 
        the_geom_p = d.the_geom 
    FROM 
        data d 
    WHERE 
        d.wdpaid = w.wdpaid;

ALTER TABLE wdpa_points DROP COLUMN the_geom CASCADE;
ALTER TABLE wdpa_points RENAME COLUMN the_geom_p TO the_geom;
CREATE INDEX wdpa_points_the_geom_idx ON wdpa_points USING gist (the_geom);

/*ALTER TABLE wdpa_points ADD COLUMN the_geom_webmercator geometry;
UPDATE wdpa_points SET the_geom_webmercator = ST_transform(the_geom, 3857);
CREATE INDEX wdpa_points_the_geomw_idx ON wdpa_points USING gist (the_geom_webmercator);
*/


ALTER TABLE wdpa_points ADD COLUMN gadm2 text;
WITH data AS (
    SELECT 
        w.uid,
        string_agg(g.name_2 || ', ' || g.name_1 || ', ' || g.name_0, '; ') as loc
    FROM 
        wdpa_points w,
        gadm2 g
    WHERE 
        ST_INTERSECTS(w.the_geom, g.the_geom)
    GROUP BY 
        w.uid
)
UPDATE wdpa_points g SET gadm2 = d.loc FROM data d WHERE g.uid = d.uid;

ALTER TABLE wdpa_polygons ADD COLUMN gadm2 text;
/*WITH data AS (
    SELECT 
        w.uid,
        string_agg(g.name_2 || ', ' || g.name_1 || ', ' || g.name_0, '; ') as loc
    FROM 
        wdpa_polygons w,
        gadm2 g
    WHERE 
        ST_INTERSECTS(w.the_geom, g.the_geom)
    GROUP BY 
        w.uid
)
UPDATE wdpa_polygons g SET gadm2 = d.loc FROM data d WHERE g.uid = d.uid;*/

CREATE INDEX wdpa_polygons_gadm2_idx ON wdpa_polygons USING gin (gadm2 gin_trgm_ops);
CREATE INDEX wdpa_points_gadm2_idx ON wdpa_points USING gin (gadm2 gin_trgm_ops);
