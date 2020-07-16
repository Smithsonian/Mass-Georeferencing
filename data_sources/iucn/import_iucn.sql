--
CREATE TABLE iucn 
    (
        sciname text,
        citation text,
        data_sources text,
        compiler text,
        version text,
        the_geom geometry(MULTIPOLYGON, 4326),
        kingdom text DEFAULT 'Animalia',
        phylum text DEFAULT 'Chordata',
        class text,
        order_ text,
        family text,
        genus text,
        redlist_cat text,
        uid uuid DEFAULT uuid_generate_v4()
        );


CREATE TABLE iucn_birds_rl (
    OBJECTID text,
    SISRecID text,
    SpcRecID text,
    Order_ text,
    FamilyName text,
    Family text,
    CommonName text,
    ScientificName text,
    RedListCategory text
);
\copy iucn_birds_rl from 'redlist_2018.csv' CSV HEADER;

--birds
INSERT INTO iucn 
    (
        sciname,
        citation,
        data_sources,
        compiler,
        version,
        class,
        order_,
        family,
        the_geom,
        redlist_cat
        )
    (
        SELECT 
            i.sciname,
            i.citation,
            i.source,
            i.compiler,
            i.version,
            'Aves',
            initcap(lower(r.order_)),
            r.familyname,
            i.the_geom,
            r.redlistcategory
        FROM 
            iucn_birds i,
            iucn_birds_rl r
        WHERE i.sciname = r.scientificname
        );







--amphibians
----shp2pgsql -D -s 4326 -g the_geom AMPHIBIANS.shp iucn_amphibians | psql -h localhost -U gisuser -d gis
UPDATE iucn_amphibians SET the_geom = st_multi(st_makevalid(st_collectionextract(the_geom, 3))) WHERE st_isvalid(the_geom) = 'F';
--UPDATE iucn_amphibians SET the_geom = st_makevalid(the_geom) WHERE st_isvalid(the_geom) = 'F';
INSERT INTO iucn 
    (
        sciname,
        citation,
        data_sources,
        compiler,
        version,
        class,
        order_,
        family,
        genus,
        redlist_cat,
        the_geom
        )
    (
        SELECT 
            binomial,
            citation,
            source,
            compiler,
            yrcompiled,
            class,
            order_,
            family,
            genus,
            category,
            the_geom
        FROM 
            iucn_amphibians
        );
DROP TABLE iucn_amphibians;


--mammals
----shp2pgsql -D -s 4326 -g the_geom MAMMALS.shp iucn_mammals | psql -h localhost -U gisuser -d gis
UPDATE iucn_mammals SET the_geom = st_makevalid(the_geom) WHERE st_isvalid(the_geom) = 'F';
INSERT INTO iucn 
    (
        sciname,
        citation,
        data_sources,
        compiler,
        version,
        class,
        order_,
        family,
        genus,
        redlist_cat,
        the_geom
        )
    (
        SELECT 
            binomial,
            citation,
            source,
            compiler,
            yrcompiled,
            class,
            order_,
            family,
            genus,
            category,
            the_geom
        FROM 
            iucn_mammals
        );

DROP TABLE iucn_mammals CASCADE;


--reptiles
----shp2pgsql -D -s 4326 -g the_geom REPTILES.shp iucn_reptiles | psql -h localhost -U gisuser -d gis
--UPDATE iucn_reptiles SET the_geom = st_makevalid(the_geom) WHERE st_isvalid(the_geom) = 'F';
INSERT INTO iucn 
    (
        sciname,
        citation,
        data_sources,
        compiler,
        version,
        class,
        order_,
        family,
        genus,
        redlist_cat,
        the_geom
        )
    (
        SELECT 
            binomial,
            citation,
            source,
            compiler,
            yrcompiled,
            class,
            order_,
            family,
            genus,
            category,
            the_geom
        FROM 
            iucn_reptiles
        );
DROP TABLE iucn_reptiles CASCADE;




--conus
----shp2pgsql -D -s 4326 -g the_geom CONUS.shp iucn_conus | psql -h localhost -U gisuser -d gis
UPDATE iucn_conus SET the_geom = st_makevalid(the_geom) WHERE st_isvalid(the_geom) = 'F';
INSERT INTO iucn 
    (
        sciname,
        citation,
        data_sources,
        compiler,
        version,
        kingdom,
        phylum,
        class,
        order_,
        family,
        genus,
        redlist_cat,
        the_geom
        )
    (
        SELECT 
            binomial,
            citation,
            source,
            compiler,
            yrcompiled,
            kingdom,
            phylum,
            class,
            order_,
            family,
            genus,
            category,
            the_geom
        FROM 
            iucn_conus
        );
DROP TABLE iucn_conus CASCADE;




--mangroves
----shp2pgsql -D -s 4326 -g the_geom MANGROVES.shp iucn_mangroves | psql -h localhost -U gisuser -d gis
UPDATE iucn_mangroves SET the_geom = st_makevalid(the_geom) WHERE st_isvalid(the_geom) = 'F';
INSERT INTO iucn 
    (
        sciname,
        citation,
        data_sources,
        compiler,
        version,
        kingdom,
        phylum,
        class,
        order_,
        family,
        genus,
        redlist_cat,
        the_geom
        )
    (
        SELECT 
            binomial,
            citation,
            source,
            compiler,
            yrcompiled,
            kingdom,
            phylum,
            class,
            order_,
            family,
            genus,
            category,
            the_geom
        FROM 
            iucn_mangroves
        );
DROP TABLE iucn_mangroves CASCADE;



