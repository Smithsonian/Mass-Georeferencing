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



--Users
DROP TABLE IF EXISTS mg_users CASCADE;
CREATE TABLE mg_users
(
    user_id uuid NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_name text NOT NULL,
    user_pass text NOT NULL,
    updated_at timestamp with time zone DEFAULT NOW()
);
CREATE INDEX mg_collex_uid_idx ON mg_users USING BTREE(user_id);
CREATE TRIGGER trigger_updated_at_mg_users
  BEFORE UPDATE ON mg_users
  FOR EACH ROW
  EXECUTE PROCEDURE updated_at_files();



--Projects for users
DROP TABLE IF EXISTS mg_users_collex CASCADE;
CREATE TABLE mg_users_collex
(
    table_id serial PRIMARY KEY,
    user_id uuid REFERENCES mg_users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    collex_id uuid REFERENCES mg_collex(collex_id) ON DELETE CASCADE ON UPDATE CASCADE,
    updated_at timestamp with time zone DEFAULT NOW()
);
CREATE INDEX mg_users_collex_tid_idx ON mg_users_collex USING BTREE(table_id);
CREATE INDEX mg_users_collex_uid_idx ON mg_users_collex USING BTREE(user_id);
CREATE INDEX mg_users_collex_cid_idx ON mg_users_collex USING BTREE(collex_id);
CREATE TRIGGER trigger_updated_at_mg_users_collex
  BEFORE UPDATE ON mg_users_collex
  FOR EACH ROW
  EXECUTE PROCEDURE updated_at_files();




--Cookies for users
DROP TABLE IF EXISTS mg_users_cookies CASCADE;
CREATE TABLE mg_users_cookies
(
    table_id serial PRIMARY KEY,
    user_id uuid REFERENCES mg_users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    cookie text NOT NULL,
    updated_at timestamp with time zone DEFAULT NOW()
);
CREATE INDEX mg_users_cookies_tid_idx ON mg_users_cookies USING BTREE(table_id);
CREATE INDEX mg_users_cookies_uid_idx ON mg_users_cookies USING BTREE(user_id);
CREATE INDEX mg_users_cookies_cid_idx ON mg_users_cookies USING BTREE(cookie);
CREATE TRIGGER trigger_updated_at_mg_users_cookies
  BEFORE UPDATE ON mg_users_cookies
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
    no_candidates int NOT NULL DEFAULT 0,
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
    collex_id uuid NOT NULL,
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
    countryverbatim text,
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
CREATE INDEX mg_occurrences_collex_idx ON mg_occurrences USING BTREE(collex_id);
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
CREATE INDEX mg_occurrences_countverb_idx ON mg_occurrences USING BTREE(countryverbatim);
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
    updated_at timestamp with time zone DEFAULT NOW()
);
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





--Function to test if a value is a valid date
--Adapted from https://stackoverflow.com/a/25374982
CREATE OR REPLACE FUNCTION is_date(s varchar) RETURNS boolean as $$
BEGIN
  perform s::date;
  return true;
EXCEPTION WHEN OTHERS THEN
  return false;
END;
$$ language plpgsql;




--Selected candidate
--mg_selected_candidates
DROP TABLE IF EXISTS mg_selected_candidates CASCADE;
CREATE TABLE mg_selected_candidates
(
    mg_selected_candidates_id uuid NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
    collex_id uuid REFERENCES mg_collex(collex_id) ON DELETE CASCADE ON UPDATE CASCADE,
    candidate_id uuid,
    recgroup_id uuid REFERENCES mg_recordgroups(recgroup_id) ON DELETE CASCADE ON UPDATE CASCADE,
    data_source text,
    point_or_polygon text DEFAULT 'point',
    uncertainty_m float DEFAULT NULL,
    notes text,
    updated_at timestamp with time zone DEFAULT NOW()
);
CREATE INDEX mg_selcandidates_rgid_idx ON mg_selected_candidates USING BTREE(candidate_id);
CREATE INDEX mg_selcandidates_collexid_idx ON mg_selected_candidates USING BTREE(collex_id);
CREATE INDEX mg_selcandidates_rid_idx ON mg_selected_candidates USING BTREE(recgroup_id);
CREATE INDEX mg_selcandidates_id_idx ON mg_selected_candidates USING BTREE(mg_selected_candidates_id);

CREATE TRIGGER trigger_updated_at_mg_selected_candidates
  BEFORE UPDATE ON mg_selected_candidates
  FOR EACH ROW
  EXECUTE PROCEDURE updated_at_files();




--Selected candidate
--mg_recgrp_candidate_selected
/*
DROP TABLE IF EXISTS mg_recgrp_candidate_selected CASCADE;
CREATE TABLE mg_recgrp_candidate_selected
(
    table_id uuid NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
    collex_id uuid REFERENCES mg_collex(collex_id) ON DELETE CASCADE ON UPDATE CASCADE,
    recgroup_id uuid REFERENCES mg_recordgroups(recgroup_id) ON DELETE CASCADE ON UPDATE CASCADE,
    candidate_id uuid REFERENCES mg_candidates(candidate_id) ON DELETE CASCADE ON UPDATE CASCADE,
    updated_at timestamp with time zone DEFAULT NOW()
);

CREATE INDEX mg_rgcand_id_idx ON mg_recgrp_candidate_selected USING BTREE(table_id);
CREATE INDEX mg_rgcand_cid_idx ON mg_recgrp_candidate_selected USING BTREE(collex_id);
CREATE INDEX mg_rgcand_rid_idx ON mg_recgrp_candidate_selected USING BTREE(recgroup_id);
CREATE INDEX mg_rgcand_candid_idx ON mg_recgrp_candidate_selected USING BTREE(candidate_id);


CREATE TRIGGER trigger_updated_at_mg_recgrp
  BEFORE UPDATE ON mg_recgrp_candidate_selected
  FOR EACH ROW
  EXECUTE PROCEDURE updated_at_files();
*/



--Types of scores
--mg_scoretypes
DROP TABLE IF EXISTS mg_scoretypes CASCADE;
CREATE TABLE mg_scoretypes
(
    scoretype text NOT NULL PRIMARY KEY,
    score_info text NOT NULL,
    updated_at timestamp with time zone DEFAULT NOW()
);

CREATE INDEX mg_scrtype_st_idx ON mg_scoretypes USING BTREE(scoretype);

CREATE TRIGGER trigger_updated_at_mg_scoretypes
  BEFORE UPDATE ON mg_scoretypes
  FOR EACH ROW
  EXECUTE PROCEDURE updated_at_files();






--Areas to include
DROP TABLE IF EXISTS mg_polygons CASCADE;
CREATE TABLE mg_polygons
(
    table_id uuid NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
    collex_id uuid REFERENCES mg_collex(collex_id) ON DELETE CASCADE ON UPDATE CASCADE,
    the_geom geometry(MultiPolygon, 4326),
    updated_at timestamp with time zone DEFAULT NOW()
);
CREATE INDEX mg_polygons_cid_idx ON mg_polygons USING BTREE(collex_id);
CREATE INDEX mg_polygons_geom_idx ON mg_polygons USING GIST(the_geom);
CREATE TRIGGER trigger_updated_at_mg_polygons
  BEFORE UPDATE ON mg_polygons
  FOR EACH ROW
  EXECUTE PROCEDURE updated_at_files();






--collection downloads
DROP TABLE IF EXISTS mg_collex_dl CASCADE;
CREATE TABLE mg_collex_dl
(
    table_id serial,
    collex_id uuid REFERENCES mg_collex(collex_id) ON DELETE CASCADE ON UPDATE CASCADE,
    dl_file_path uuid NOT NULL,
    dl_recipe text NOT NULL,
    dl_norecords int NOT NULL,
    ready bool default 'f',
    updated_at timestamp with time zone DEFAULT NOW()
);
CREATE INDEX mg_collex_dl_cid_idx ON mg_collex_dl USING BTREE(collex_id);
CREATE TRIGGER trigger_updated_at_mg_collex_dl
  BEFORE UPDATE ON mg_collex_dl
  FOR EACH ROW
  EXECUTE PROCEDURE updated_at_files();

