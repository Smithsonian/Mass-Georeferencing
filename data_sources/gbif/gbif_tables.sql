--Table to store the original contents of occurrence
DROP TABLE IF EXISTS gbif_occ CASCADE;
-- Dont log these tables to speed up inserts
CREATE UNLOGGED TABLE gbif_occ(
    gbifID text,
    abstract text,
    accessRights text,
    accrualMethod text,
    accrualPeriodicity text,
    accrualPolicy text,
    alternative text,
    audience text,
    available text,
    bibliographicCitation text,
    conformsTo text,
    contributor text,
    coverage text,
    created text,
    creator text,
    date text,
    dateAccepted text,
    dateCopyrighted text,
    dateSubmitted text,
    description text,
    educationLevel text,
    extent text,
    format text,
    hasFormat text,
    hasPart text,
    hasVersion text,
    identifier text,
    instructionalMethod text,
    isFormatOf text,
    isPartOf text,
    isReferencedBy text,
    isReplacedBy text,
    isRequiredBy text,
    isVersionOf text,
    issued text,
    language text,
    license text,
    mediator text,
    medium text,
    modified text,
    provenance text,
    publisher text,
    _references text,
    relation text,
    replaces text,
    requires text,
    rights text,
    rightsHolder text,
    source text,
    spatial text,
    subject text,
    tableOfContents text,
    temporal text,
    title text,
    type text,
    valid text,
    institutionID text,
    collectionID text,
    datasetID text,
    institutionCode text,
    collectionCode text,
    datasetName text,
    ownerInstitutionCode text,
    basisOfRecord text,
    informationWithheld text,
    dataGeneralizations text,
    dynamicProperties text,
    occurrenceID text,
    catalogNumber text,
    recordNumber text,
    recordedBy text,
    individualCount text,
    organismQuantity text,
    organismQuantityType text,
    sex text,
    lifeStage text,
    reproductiveCondition text,
    behavior text,
    establishmentMeans text,
    occurrenceStatus text,
    preparations text,
    disposition text,
    associatedReferences text,
    associatedSequences text,
    associatedTaxa text,
    otherCatalogNumbers text,
    occurrenceRemarks text,
    organismID text,
    organismName text,
    organismScope text,
    associatedOccurrences text,
    associatedOrganisms text,
    previousIdentifications text,
    organismRemarks text,
    materialSampleID text,
    eventID text,
    parentEventID text,
    fieldNumber text,
    eventDate text,
    eventTime text,
    startDayOfYear text,
    endDayOfYear text,
    year text,
    month text,
    day text,
    verbatimEventDate text,
    habitat text,
    samplingProtocol text,
    samplingEffort text,
    sampleSizeValue text,
    sampleSizeUnit text,
    fieldNotes text,
    eventRemarks text,
    locationID text,
    higherGeographyID text,
    higherGeography text,
    continent text,
    waterBody text,
    islandGroup text,
    island text,
    countryCode text,
    stateProvince text,
    county text,
    municipality text,
    locality text,
    verbatimLocality text,
    verbatimElevation text,
    verbatimDepth text,
    minimumDistanceAboveSurfaceInMeters text,
    maximumDistanceAboveSurfaceInMeters text,
    locationAccordingTo text,
    locationRemarks text,
    decimalLatitude float,
    decimalLongitude float,
    coordinateUncertaintyInMeters text,
    coordinatePrecision text,
    pointRadiusSpatialFit text,
    verbatimCoordinateSystem text,
    verbatimSRS text,
    footprintWKT text,
    footprintSRS text,
    footprintSpatialFit text,
    georeferencedBy text,
    georeferencedDate text,
    georeferenceProtocol text,
    georeferenceSources text,
    georeferenceVerificationStatus text,
    georeferenceRemarks text,
    geologicalContextID text,
    earliestEonOrLowestEonothem text,
    latestEonOrHighestEonothem text,
    earliestEraOrLowestErathem text,
    latestEraOrHighestErathem text,
    earliestPeriodOrLowestSystem text,
    latestPeriodOrHighestSystem text,
    earliestEpochOrLowestSeries text,
    latestEpochOrHighestSeries text,
    earliestAgeOrLowestStage text,
    latestAgeOrHighestStage text,
    lowestBiostratigraphicZone text,
    highestBiostratigraphicZone text,
    lithostratigraphicTerms text,
    _group text,
    formation text,
    member text,
    bed text,
    identificationID text,
    identificationQualifier text,
    typeStatus text,
    identifiedBy text,
    dateIdentified text,
    identificationReferences text,
    identificationVerificationStatus text,
    identificationRemarks text,
    taxonID text,
    scientificNameID text,
    acceptedNameUsageID text,
    parentNameUsageID text,
    originalNameUsageID text,
    nameAccordingToID text,
    namePublishedInID text,
    taxonConceptID text,
    scientificName text,
    acceptedNameUsage text,
    parentNameUsage text,
    originalNameUsage text,
    nameAccordingTo text,
    namePublishedIn text,
    namePublishedInYear text,
    higherClassification text,
    kingdom text,
    phylum text,
    class text,
    _order text,
    family text,
    genus text,
    subgenus text,
    specificEpithet text,
    infraspecificEpithet text,
    taxonRank text,
    verbatimTaxonRank text,
    vernacularName text,
    nomenclaturalCode text,
    taxonomicStatus text,
    nomenclaturalStatus text,
    taxonRemarks text,
    datasetKey text,
    publishingCountry text,
    lastInterpreted text,
    elevation text,
    elevationAccuracy text,
    depth text,
    depthAccuracy text,
    distanceAboveSurface text,
    distanceAboveSurfaceAccuracy text,
    issue text,
    mediaType text,
    hasCoordinate text,
    hasGeospatialIssues text,
    taxonKey text,
    acceptedTaxonKey text,
    kingdomKey text,
    phylumKey text,
    classKey text,
    orderKey text,
    familyKey text,
    genusKey text,
    subgenusKey text,
    speciesKey text,
    species text,
    genericName text,
    acceptedScientificName text,
    verbatimScientificName text,
    typifiedName text,
    protocol text,
    lastParsed text,
    lastCrawled text,
    repatriated text,
    relativeOrganismQuantity text,
    recordedByID text);




----------------------------
--Simplified table
----------------------------
DROP TABLE IF EXISTS gbif CASCADE;
CREATE TABLE gbif (
    gbifID text,
    eventDate text,
    basisOfRecord text,
    recordedBy text,
    occurrenceID text,
    locationID text,
    continent text,
    waterBody text,
    islandGroup text,
    island text,
    countryCode text,
    stateProvince text,
    county text,
    municipality text,
    locality text,
    verbatimLocality text,
    locationAccordingTo text,
    locationRemarks text,
    decimalLatitude float,
    decimalLongitude float,
    coordinateUncertaintyInMeters text,
    coordinatePrecision text,
    pointRadiusSpatialFit text,
    georeferencedBy text,
    georeferencedDate text,
    georeferenceProtocol text,
    georeferenceSources text,
    georeferenceVerificationStatus text,
    georeferenceRemarks text,
    taxonConceptID text,
    scientificName text,
    higherClassification text,
    kingdom text,
    phylum text,
    class text,
    _order text,
    family text,
    genus text,
    subgenus text,
    specificEpithet text,
    infraspecificEpithet text,
    taxonRank text,
    vernacularName text,
    nomenclaturalCode text,
    taxonomicStatus text,
    nomenclaturalStatus text,
    taxonRemarks text,
    datasetKey text,
    issue text,
    hasGeospatialIssues text,
    taxonKey text,
    acceptedTaxonKey text,
    species text,
    genericName text,
    acceptedScientificName text,
    the_geom geometry,
    the_geom_webmercator geometry
);


--GBIF partitioned by species
CREATE TABLE gbif_00 (
    CHECK (species < 'Ancita crocogaster'::text)
) INHERITS (gbif);

CREATE TABLE gbif_01 (
    CHECK (species >= 'Ancita crocogaster'::text
                    AND species < 'Austrolimnophila microsticta'::text)
) INHERITS (gbif);

CREATE TABLE gbif_02 (
    CHECK (species >= 'Austrolimnophila microsticta'::text
                    AND species < 'Calothamnus arcuatus'::text)
) INHERITS (gbif);

CREATE TABLE gbif_03 (
    CHECK (species >= 'Calothamnus arcuatus'::text
                    AND species < 'Circulus pseudopraecedens'::text)
) INHERITS (gbif);

CREATE TABLE gbif_04 (
    CHECK (species >= 'Circulus pseudopraecedens'::text
                    AND species < 'Cucumis membranifolius'::text)
) INHERITS (gbif);

CREATE TABLE gbif_05 (
    CHECK (species >= 'Cucumis membranifolius'::text
                    AND species < 'Dodecatheon vulgare'::text)
) INHERITS (gbif);

CREATE TABLE gbif_06 (
    CHECK (species >= 'Dodecatheon vulgare'::text
                    AND species < 'Eugenia meridensis'::text)
) INHERITS (gbif);

CREATE TABLE gbif_07 (
    CHECK (species >= 'Eugenia meridensis'::text
                    AND species < 'Gordionus conglomeratus'::text)
) INHERITS (gbif);

CREATE TABLE gbif_08 (
    CHECK (species >= 'Gordionus conglomeratus'::text
                    AND species < 'Hydrophorus signifer'::text)
) INHERITS (gbif);

CREATE TABLE gbif_09 (
    CHECK (species >= 'Hydrophorus signifer'::text
                    AND species < 'Lepanthes brachypogon'::text)
) INHERITS (gbif);

CREATE TABLE gbif_10 (
    CHECK (species >= 'Lepanthes brachypogon'::text
                    AND species < 'Marrubium creticum'::text)
) INHERITS (gbif);

CREATE TABLE gbif_11 (
    CHECK (species >= 'Marrubium creticum'::text
                    AND species < 'Myriactis longipedunculata'::text)
) INHERITS (gbif);

CREATE TABLE gbif_12 (
    CHECK (species >= 'Myriactis longipedunculata'::text
                    AND species < 'Oriolus mellianus'::text)
) INHERITS (gbif);

CREATE TABLE gbif_13 (
    CHECK (species >= 'Oriolus mellianus'::text
                    AND species < 'Peziza serratulae'::text)
) INHERITS (gbif);

CREATE TABLE gbif_14 (
    CHECK (species >= 'Peziza serratulae'::text
                    AND species < 'Polyporus recurvus'::text)
) INHERITS (gbif);

CREATE TABLE gbif_15 (
    CHECK (species >= 'Polyporus recurvus'::text
                    AND species < 'Reithrodontomys chrysopsis'::text)
) INHERITS (gbif);

CREATE TABLE gbif_16 (
    CHECK (species >= 'Reithrodontomys chrysopsis'::text
                    AND species < 'Selenosporella falcata'::text)
) INHERITS (gbif);

CREATE TABLE gbif_17 (
    CHECK (species >= 'Selenosporella falcata'::text
                    AND species < 'Suberea praetensa'::text)
) INHERITS (gbif);

CREATE TABLE gbif_18 (
    CHECK (species >= 'Suberea praetensa'::text
                    AND species < 'Trichosalpinx lenticularis'::text)
) INHERITS (gbif);

CREATE TABLE gbif_19 (
    CHECK (species >= 'Trichosalpinx lenticularis'::text)
) INHERITS (gbif);



----------------------
--Function to insert into the specific subtable
----------------------

CREATE OR REPLACE FUNCTION gbif_insert_sci() RETURNS TRIGGER AS $$
BEGIN
    IF ( NEW.species < 'Ancita crocogaster'::text ) THEN INSERT INTO gbif_00 VALUES (NEW.*);
      ELSIF
      ( NEW.species >= 'Ancita crocogaster'::text AND NEW.species < 'Austrolimnophila microsticta'::text ) THEN INSERT INTO gbif_01 VALUES (NEW.*);
      ELSIF
      ( NEW.species >= 'Austrolimnophila microsticta'::text AND NEW.species < 'Calothamnus arcuatus'::text ) THEN INSERT INTO gbif_02 VALUES (NEW.*);
      ELSIF
      ( NEW.species >= 'Calothamnus arcuatus'::text AND NEW.species < 'Circulus pseudopraecedens'::text ) THEN INSERT INTO gbif_03 VALUES (NEW.*);
      ELSIF
      ( NEW.species >= 'Circulus pseudopraecedens'::text AND NEW.species < 'Cucumis membranifolius'::text ) THEN INSERT INTO gbif_04 VALUES (NEW.*);
      ELSIF
      ( NEW.species >= 'Cucumis membranifolius'::text AND NEW.species < 'Dodecatheon vulgare'::text) THEN INSERT INTO gbif_05 VALUES (NEW.*);
      ELSIF
      ( NEW.species >= 'Dodecatheon vulgare'::text AND NEW.species < 'Eugenia meridensis'::text ) THEN INSERT INTO gbif_06 VALUES (NEW.*);
      ELSIF
      ( NEW.species >= 'Eugenia meridensis'::text AND NEW.species < 'Gordionus conglomeratus'::text ) THEN INSERT INTO gbif_07 VALUES (NEW.*);
      ELSIF
      ( NEW.species >= 'Gordionus conglomeratus'::text AND NEW.species < 'Hydrophorus signifer'::text ) THEN INSERT INTO gbif_08 VALUES (NEW.*);
      ELSIF
      ( NEW.species >= 'Hydrophorus signifer'::text AND NEW.species < 'Lepanthes brachypogon'::text ) THEN INSERT INTO gbif_09 VALUES (NEW.*);
      ELSIF
      ( NEW.species >= 'Lepanthes brachypogon'::text AND NEW.species < 'Marrubium creticum'::text ) THEN INSERT INTO gbif_10 VALUES (NEW.*);
      ELSIF
      ( NEW.species >= 'Marrubium creticum'::text AND NEW.species < 'Myriactis longipedunculata'::text ) THEN INSERT INTO gbif_11 VALUES (NEW.*);
      ELSIF
      ( NEW.species >= 'Myriactis longipedunculata'::text AND NEW.species < 'Oriolus mellianus'::text ) THEN INSERT INTO gbif_12 VALUES (NEW.*);
      ELSIF
      ( NEW.species >= 'Oriolus mellianus'::text AND NEW.species < 'Peziza serratulae'::text ) THEN INSERT INTO gbif_13 VALUES (NEW.*);
      ELSIF
      ( NEW.species >= 'Peziza serratulae'::text AND NEW.species < 'Polyporus recurvus'::text ) THEN INSERT INTO gbif_14 VALUES (NEW.*);
      ELSIF
      ( NEW.species >= 'Polyporus recurvus'::text AND NEW.species < 'Reithrodontomys chrysopsis'::text ) THEN INSERT INTO gbif_15 VALUES (NEW.*);
      ELSIF
      ( NEW.species >= 'Reithrodontomys chrysopsis'::text AND NEW.species < 'Selenosporella falcata'::text ) THEN INSERT INTO gbif_16 VALUES (NEW.*);
      ELSIF
      ( NEW.species >= 'Selenosporella falcata'::text AND NEW.species < 'Suberea praetensa'::text ) THEN INSERT INTO gbif_17 VALUES (NEW.*);
      ELSIF
      ( NEW.species >= 'Suberea praetensa'::text AND NEW.species < 'Trichosalpinx lenticularis'::text ) THEN INSERT INTO gbif_18 VALUES (NEW.*);
      ELSIF
      ( NEW.species >= 'Trichosalpinx lenticularis'::text ) THEN INSERT INTO gbif_19 VALUES (NEW.*);

    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


----------------------
--Trigger for insert
----------------------
CREATE TRIGGER gbif_insert_trigger
BEFORE INSERT ON gbif
FOR EACH ROW EXECUTE PROCEDURE gbif_insert_sci();

