--Postgres 10+ schema for the 
-- Mass Georeferencing Tool

--Postgres function to update the column last_update on files when the row is updated
CREATE FUNCTION updated_at_files() RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

--pg_trgm extension
CREATE EXTENSION pg_trgm;



--collections
DROP TABLE IF EXISTS mg_collex CASCADE;
CREATE TABLE mg_collex
(
    collex_id uuid NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
    collex_name text NOT NULL,
    collex_definition text NOT NULL,
    collex_notes text,
    updated_at timestamp with time zone DEFAULT NOW()
);
CREATE INDEX mg_collex_cid_idx ON mg_collex USING BTREE(collex_id);
CREATE TRIGGER trigger_updated_at_mg_collex
  BEFORE UPDATE ON mg_collex
  FOR EACH ROW
  EXECUTE PROCEDURE updated_at_files();



--groups of records
--mg_recordgroups
DROP TABLE IF EXISTS mg_recordgroups CASCADE;
CREATE TABLE mg_recordgroups
(
    recgroup_id uuid NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
    collex_id uuid REFERENCES mg_collex(collex_id) ON DELETE CASCADE ON UPDATE CASCADE,
    locality text NOT NULL,
    stateprovince text,
    countrycode text,
    recordedby text,
    kingdom text,
    phylum text,
    class text,
    _order text, 
    family text, 
    genus text, 
    species text NOT NULL,     
    no_records int NOT NULL DEFAULT 1,
    updated_at timestamp with time zone DEFAULT NOW());
CREATE INDEX mg_recordgroups_rgid_idx ON mg_recordgroups USING BTREE(recgroup_id);
CREATE INDEX mg_recordgroups_cid_idx ON mg_recordgroups USING BTREE(collex_id);
CREATE INDEX mg_recordgroups_rid_idx ON mg_recordgroups USING BTREE(record_id);
CREATE INDEX mg_recordgroups_ccode_idx ON mg_recordgroups USING BTREE(countrycode);
CREATE INDEX mg_recordgroups_species_idx ON mg_recordgroups USING gin (species gin_trgm_ops);

CREATE TRIGGER trigger_updated_at_mg_recordgroups
  BEFORE UPDATE ON mg_recordgroups
  FOR EACH ROW
  EXECUTE PROCEDURE updated_at_files();






--table with records
--mg_occurrences
DROP TABLE IF EXISTS mg_occurrences CASCADE;
CREATE TABLE mg_occurrences
(
    mg_occurrenceid uuid NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
    occurrence_source text NOT NULL,
    occurrenceid text,
    gbifid bigint,
    datasetid text,
    datasetName text,
    basisofrecord text,
    informationwithheld text,
    datageneralizations text,
    eventdate date,
    eventtime time without time zone,
    verbatimeventdate text,
    highergeography text,
    continent text,
    waterbody text,
    islandgroup text,
    island text,
    countrycode text,
    stateprovince text,
    county text,
    municipality text,
    locality text,
    verbatimlocality text,
    verbatimelevation text,
    locationremarks text,
    decimallatitude float,
    decimallongitude float,
    coordinateuncertaintyinmeters text,
    coordinateprecision text,
    pointradiusspatialfit text,
    verbatimcoordinatesystem text,
    verbatimsrs text,
    georeferencedby text,
    georeferenceddate text,
    georeferenceprotocol text,
    georeferencesources text,
    georeferenceverificationstatus text,
    georeferenceremarks text,
    geologicalcontextid text,
    earliesteonorlowesteonothem text,
    latesteonorhighesteonothem text,
    earliesteraorlowesterathem text,
    latesteraorhighesterathem text,
    earliestperiodorlowestsystem text,
    latestperiodorhighestsystem text,
    earliestepochorlowestseries text,
    latestepochorhighestseries text,
    earliestageorloweststage text,
    latestageorhigheststage text,
    lowestbiostratigraphiczone text,
    highestbiostratigraphiczone text,
    lithostratigraphicterms text,
    typestatus text,
    taxonid text,
    scientificname text,
    acceptednameusage text,
    higherclassification text,
    kingdom text,
    phylum text,
    class text,
    _order text,
    family text,
    genus text,
    subgenus text,
    specificepithet text,
    infraspecificepithet text,
    taxonrank text,
    taxonremarks text,
    datasetkey text,
    elevation text,
    elevationaccuracy text,
    issue text,
    hascoordinate text,
    hasgeospatialissues text,
    taxonkey text,
    acceptedtaxonkey text,
    kingdomkey text,
    phylumkey text,
    classkey text,
    orderkey text,
    familykey text,
    genuskey text,
    subgenuskey text,
    specieskey text,
    species text,
    genericname text,
    acceptedscientificname text,
    lastparsed text,
    recordedby text);
CREATE INDEX mg_occurrences_occid_idx ON mg_occurrences USING BTREE(occurrenceID);
CREATE INDEX mg_occurrences_gbifid_idx ON mg_occurrences USING BTREE(gbifID);
CREATE INDEX mg_occurrences_date_idx ON mg_occurrences USING BTREE(eventdate);
CREATE INDEX mg_occurrences_mgocid_idx ON mg_occurrences USING BTREE(mg_occurrenceid);
CREATE INDEX mg_occurrences_species_idx ON mg_occurrences USING gin (species gin_trgm_ops);
CREATE INDEX mg_occurrences_sp_idx ON mg_occurrences USING BTREE(species);
CREATE INDEX mg_occurrences_locality_idx ON mg_occurrences USING gin (locality gin_trgm_ops);
CREATE INDEX mg_occurrences_lw_locality_idx ON mg_occurrences USING BTREE (lower(locality));
CREATE INDEX mg_occurrences_recordedby_idx ON mg_occurrences USING gin (recordedby gin_trgm_ops);
CREATE INDEX mg_occurrences_source_idx ON mg_occurrences USING BTREE(occurrence_source);
CREATE INDEX mg_occurrences_decimallatitude_idx ON mg_occurrences(decimallatitude) WHERE decimallatitude IS NULL;
CREATE INDEX mg_occurrences_decimallon_idx ON mg_occurrences(decimallongitude) WHERE decimallongitude IS NULL;
CREATE INDEX mg_occurrences_ccode_idx ON mg_occurrences USING BTREE(countrycode);
CREATE INDEX mg_occurrences_state_idx ON mg_occurrences USING BTREE(stateprovince);
CLUSTER mg_occurrences USING mg_occurrences_sp_idx;





--table with records
--mg_occurrences
DROP TABLE IF EXISTS mg_occurrences_media CASCADE;
CREATE TABLE mg_occurrences_media
(
    mg_mediaid uuid NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
    mg_occurrenceid uuid REFERENCES mg_occurrences(mg_occurrenceid) ON DELETE CASCADE ON UPDATE CASCADE,
    gbifid bigint,
    type text,
    format text,
    identifier text,
    _references text,
    title text,
    description text,
    created text,
    creator text,
    contributor text,
    publisher text,
    audience text,
    source text,
    license text,
    rightsHolder text
    );
CREATE INDEX mg_occurrences_media_mid_idx ON mg_occurrences_media USING BTREE(mg_mediaid);
CREATE INDEX mg_occurrences_media_oid_idx ON mg_occurrences_media USING BTREE(mg_occurrenceid);
CREATE INDEX mg_occurrences_media_gid_idx ON mg_occurrences_media USING BTREE(gbifid);



--records to match
--mg_records
DROP TABLE IF EXISTS mg_records CASCADE;
CREATE TABLE mg_records
(
    record_id uuid NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
    recgroup_id uuid REFERENCES mg_recordgroups(recgroup_id) ON DELETE CASCADE ON UPDATE CASCADE,
    mg_occurrenceid uuid REFERENCES mg_occurrences(mg_occurrenceid) ON DELETE CASCADE ON UPDATE CASCADE,
    updated_at timestamp with time zone DEFAULT NOW()
    );
CREATE INDEX mg_records_rgid_idx ON mg_records USING BTREE(recgroup_id);
CREATE INDEX mg_records_rid_idx ON mg_records USING BTREE(record_id);
CREATE INDEX mg_records_oid_idx ON mg_records USING BTREE(mg_occurrenceid);

CREATE TRIGGER trigger_updated_at_mg_records
  BEFORE UPDATE ON mg_records
  FOR EACH ROW
  EXECUTE PROCEDURE updated_at_files();





--candidate matches
--mg_candidates
DROP TABLE IF EXISTS mg_candidates CASCADE;
CREATE TABLE mg_candidates
(
    candidate_id uuid NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
    recgroup_id uuid REFERENCES mg_recordgroups(recgroup_id) ON DELETE CASCADE ON UPDATE CASCADE,
    data_source text NOT NULL,
    feature_id text NOT NULL,
    no_features int NOT NULL DEFAULT 1,
    updated_at timestamp with time zone DEFAULT NOW());
CREATE INDEX mg_candidates_rgid_idx ON mg_candidates USING BTREE(candidate_id);
CREATE INDEX mg_candidates_rid_idx ON mg_candidates USING BTREE(recgroup_id);
CREATE INDEX mg_candidates_data_source_idx ON mg_candidates USING BTREE(data_source);
CREATE INDEX mg_candidates_fid_idx ON mg_candidates USING BTREE(feature_id);

CREATE TRIGGER trigger_updated_at_mg_candidates
  BEFORE UPDATE ON mg_candidates
  FOR EACH ROW
  EXECUTE PROCEDURE updated_at_files();





--candidate matches scores
--mg_candidates_scores
DROP TABLE IF EXISTS mg_candidates_scores CASCADE;
CREATE TABLE mg_candidates_scores
(
    candidate_id uuid REFERENCES mg_candidates(candidate_id) ON DELETE CASCADE ON UPDATE CASCADE,
    score_type text NOT NULL,
    score int NOT NULL,
    updated_at timestamp with time zone DEFAULT NOW());
CREATE INDEX mg_candidates_s_cid_idx ON mg_candidates_scores USING BTREE(candidate_id);
CREATE INDEX mg_candidates_s_type_idx ON mg_candidates_scores USING BTREE(score_type);

CREATE TRIGGER trigger_updated_at_mg_candidates_scr
  BEFORE UPDATE ON mg_candidates_scores
  FOR EACH ROW
  EXECUTE PROCEDURE updated_at_files();



