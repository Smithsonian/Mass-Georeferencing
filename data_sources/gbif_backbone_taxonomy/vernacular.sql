--gbif_vernacularnames
DROP MATERIALIZED VIEW gbif_vernacularnames;
CREATE MATERIALIZED VIEW gbif_vernacularnames
AS
    SELECT
        t.taxonID,
        t.scientificName,
        t.scientificNameAuthorship,
        t.canonicalName,
        t.genericName,
        t.specificEpithet,
        t.infraspecificEpithet,
        t.taxonRank,
        t.nameAccordingTo,
        t.kingdom,
        t.phylum,
        t.class,
        t._order,
        t.family,
        t.genus,
        v.vernacularName,
        v.language,
        v.countryCode,
        v.source
    FROM
        gbif_taxonomy_vernacularname v,
        gbif_taxonomy_taxon t
    WHERE
        v.taxonID = t.taxonID;
