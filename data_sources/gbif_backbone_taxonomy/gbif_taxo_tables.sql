--gbif_taxonomy_description
DROP TABLE IF EXISTS gbif_taxonomy_description CASCADE;
CREATE TABLE gbif_taxonomy_description 
(
    taxonID bigint,
    type text,
    language text,
    description text,
    source text,
    creator text,
    contributor text,
    license text
);
CREATE INDEX gbif_taxonomy_description_tid_idx ON gbif_taxonomy_description USING BTREE(taxonID);


--gbif_taxonomy_distribution
DROP TABLE IF EXISTS gbif_taxonomy_distribution CASCADE;
CREATE TABLE gbif_taxonomy_distribution
(
    taxonID bigint,
    locationID  text,
    locality    text,
    country text,
    countryCode text,
    locationRemarks text,
    establishmentMeans  text,
    lifeStage   text,
    occurrenceStatus    text,
    threatStatus    text,
    source  text
);
CREATE INDEX gbif_taxonomy_distribution_tid_idx ON gbif_taxonomy_distribution USING BTREE(taxonID);


--gbif_taxonomy_multimedia
DROP TABLE IF EXISTS gbif_taxonomy_multimedia CASCADE;
CREATE TABLE gbif_taxonomy_multimedia
(
    taxonID bigint,
    identifier  text,
    _references  text,
    title   text,
    description text,
    license text,
    creator text,
    created text,
    contributor text,
    publisher   text,
    rightsHolder    text,
    source  text
);
CREATE INDEX gbif_taxonomy_multimedia_tid_idx ON gbif_taxonomy_multimedia USING BTREE(taxonID);


--gbif_taxonomy_reference
DROP TABLE IF EXISTS gbif_taxonomy_reference CASCADE;
CREATE TABLE gbif_taxonomy_reference
(
    taxonID bigint,
    bibliographicCitation text,
    identifier text,
    _references text,
    source text
);
CREATE INDEX gbif_taxonomy_reference_tid_idx ON gbif_taxonomy_reference USING BTREE(taxonID);


--gbif_taxonomy_taxon
DROP TABLE IF EXISTS gbif_taxonomy_taxon CASCADE;
CREATE TABLE gbif_taxonomy_taxon
(
    taxonID bigint,
    datasetID1   text,
    parentNameUsageID   text,
    acceptedNameUsageID text,
    originalNameUsageID text,
    scientificName  text,
    scientificNameAuthorship    text,
    canonicalName   text,
    genericName text,
    specificEpithet text,
    infraspecificEpithet    text,
    taxonRank   text,
    nameAccordingTo text,
    namePublishedIn text,
    taxonomicStatus text,
    nomenclaturalStatus text,
    taxonRemarks    text,
    kingdom text,
    phylum  text,
    class   text,
    _order   text,
    family  text,
    genus   text
);
CREATE INDEX gbif_taxonomy_taxon_tid_idx ON gbif_taxonomy_taxon USING BTREE(taxonID);



--gbif_taxonomy_typesspecimens
DROP TABLE IF EXISTS gbif_taxonomy_typesspecimens CASCADE;
CREATE TABLE gbif_taxonomy_typesspecimens
(
    taxonID bigint,
    typeDesignationType text,
    typeDesignatedBy    text,
    scientificName  text,
    taxonRank   text,
    source  text
);
CREATE INDEX gbif_taxonomy_typesspecimens_tid_idx ON gbif_taxonomy_typesspecimens USING BTREE(taxonID);



--gbif_taxonomy_vernacularname
DROP TABLE IF EXISTS gbif_taxonomy_vernacularname CASCADE;
CREATE TABLE gbif_taxonomy_vernacularname
(
    taxonID bigint,
    vernacularName  text,
    language    text,
    country text,
    countryCode text,
    sex text,
    lifeStage   text,
    source  text
);
CREATE INDEX gbif_taxonomy_vernacularname_tid_idx ON gbif_taxonomy_vernacularname USING BTREE(taxonID);
CREATE INDEX gbif_taxonomy_vernacularname_vname_idx ON gbif_taxonomy_vernacularname USING gin (vernacularName gin_trgm_ops);



--Datasets table
--gbif_taxonomy_datasets
DROP TABLE IF EXISTS gbif_taxonomy_datasets CASCADE;
CREATE TABLE gbif_taxonomy_datasets (
    datasetKey uuid,
    title text,
    organizationName text,
    rights text,
    doi text,
    date text,
    citation text, 
    license text,
    pubDate text
    );

CREATE INDEX gbif_taxonomy_datasets_idx on gbif_taxonomy_datasets USING BTREE(datasetKey);
