create table gns (
    rc text,
    ufi text,
    uni text,
    lat text,
    long text,
    dms_lat text,
    dms_long text,
    mgrs text,
    jog text,
    fc text,
    dsg text,
    pc text,
    cc1 text,
    adm1 text,
    pop text,
    elev text,
    cc2 text,
    nt text,
    lc text,
    short_form text,
    generic text,
    sort_name_ro text,
    full_name_ro text,
    full_name_nd_ro text,
    sort_name_rg text,
    full_name_rg text,
    full_name_nd_rg text,
    note text,
    modify_date text,
    display text,
    name_rank text,
    name_link text,
    transl_cd text,
    nm_modify_date text,
    f_efctv_dt text,
    f_term_dt text
);


\copy gns FROM 'Countries.txt';

ALTER TABLE gns ADD COLUMN the_geom geometry(POINT, 4326);

UPDATE gns SET the_geom = ST_SETSRID(ST_POINT(long::numeric, lat::numeric), 4326);

--For ILIKE queries
CREATE INDEX gns_name_trgm_idx ON gns USING gin (full_name_nd_ro gin_trgm_ops);
CREATE INDEX gns_thegeom_idx ON gns USING GIST(the_geom);
CREATE INDEX gns_country_idx ON gns USING BTREE(cc1);

alter table gns add column uid uuid DEFAULT uuid_generate_v4();
CREATE INDEX gns_uid_idx ON gns USING BTREE(uid);


--Add webmercator
/*ALTER TABLE gns ADD COLUMN the_geom_webmercator geometry(POINT, 3857);
UPDATE gns SET the_geom_webmercator = ST_Transform(the_geom, 3857);
CREATE INDEX gns_thegeomw_idx ON gns USING GIST(the_geom_webmercator);*/

--Add gadm2 intersection
ALTER TABLE gns ADD COLUMN gadm2 text;

UPDATE gns geo SET gadm2 = g.name_2 || ', ' || g.name_1 || ', ' || g.name_0 FROM gadm2 g WHERE ST_INTERSECTS(geo.the_geom, g.the_geom);

CREATE INDEX gns_gin_gadm2_idx ON gns USING gin(gadm2 gin_trgm_ops);
