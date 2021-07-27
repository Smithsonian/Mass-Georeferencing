
gadm0 = "SELECT 'https://dpogis.si.edu/details?datasource_id=gadm&id=' || uid as id, name_0 as name, 'country: ' || name_0 as description, (1 - (name_0 <-> %(q)s)) AS score FROM gadm0 WHERE (1 - (name_0 <-> %(q)s) > 0.8) ORDER BY score DESC LIMIT %(limit)s"

gadm1 = "SELECT 'https://dpogis.si.edu/details?datasource_id=gadm&id=' || uid as id, name_1 as name, 'state, country: ' || name_1 || ', ' || name_0 as description, (1 - (name_1 <-> %(q)s)) AS score FROM gadm1 WHERE (1 - (name_1 <-> %(q)s) > 0.8) ORDER BY score DESC LIMIT %(limit)s"

gadm_other = "SELECT 'https://dpogis.si.edu/details?datasource_id=gadm&id=' || uid as id, name_1 as name, 'state, country: ' || name_1 || ', ' || name_0 as description, (1 - (name_1 <-> %(q)s)) AS score FROM gadm1 WHERE (1 - (name_1 <-> %(q)s) > 0.8) AND name_0 ilike %(name_0)s ORDER BY score DESC LIMIT %(limit)s"

gadm_state_country = "SELECT 'https://dpogis.si.edu/details?datasource_id=gadm&id=' || uid as id, name, type || ' - ' || located_at as description, (1 - (name <-> %(q)s)) AS score FROM gadm WHERE (1 - (name <-> %(q)s) > 0.8) AND layer != 'gadm0' AND layer != 'gadm1' {stateprovince} {country} ORDER BY score DESC LIMIT %(limit)s"

gadm_country_subq = " AND name_0 ilike '{country_q}' "

gadm_stateprov_subq = " AND name_1 ilike '{stateprovince_q}' "

gbif_canonical = "SELECT 'https://dpogis.si.edu/details?speciessource=gbiftaxonomy&id=' || taxonID as id, canonicalname as name, scientificname as description, (1 - (canonicalname <-> %(q)s)) as score FROM gbif_vernacularnames WHERE (1 - (canonicalname <-> %(q)s) > 0.8) {kingdom_q} {phylum_q} {class_q} {order_q} {family_q} {genus_q} {vernacular_q} {language_q} {taxonrank_q} GROUP BY id, name, description, score ORDER BY score DESC LIMIT %(limit)s"

gbif_sciname = "SELECT *, (1 - (scientificname <-> %(q)s) > 0.8) as score FROM gbif_vernacularnames WHERE (1 - (scientificname <-> %(q)s) > 0.8) {kingdom_q} {phylum_q} {class_q} {order_q} {family_q} {genus_q} {vernacular_q} {language_q} ORDER BY score DESC LIMIT %(limit)s"

hist_counties = "SELECT 'https://dpogis.si.edu/details?datasource_id=hist_counties&id=' || uid as id, name, change as description, start_date, end_date, citation, (1 - (name <-> %(q)s)) AS score FROM hist_counties WHERE (1 - (name <-> %(q)s) > 0.8) {year_q} ORDER BY score DESC LIMIT %(limit)s"

hist_counties_coords = "SELECT 'https://dpogis.si.edu/details?datasource_id=hist_counties&id=' || uid as id, name, change as description, start_date, end_date, citation, 1 AS score FROM hist_counties WHERE ST_INTERSECTS(the_geom, ST_SETSRID(ST_POINT(%(longitude)s, %(latitude)s), 4326)) {year_q} LIMIT %(limit)s"

countries_iso2 = "SELECT iso2 as id, country as name, (1 - (country <-> %(q)s)) AS score FROM countries_iso WHERE (1 - (country <-> %(q)s) > 0.8) ORDER BY score DESC LIMIT %(limit)s"

countries_iso3 = "SELECT iso3 as id, country as name, (1 - (country <-> %(q)s)) AS score FROM countries_iso WHERE (1 - (country <-> %(q)s) > 0.8) ORDER BY score DESC LIMIT %(limit)s"

check_cookie = "SELECT u.user_id, u.user_name FROM mg_users u, mg_users_cookies c WHERE  c.user_id = u.user_id AND c.cookie = '{cookie}'"

create_cookie = "INSERT INTO mg_users_cookies (user_id, cookie) VALUES ('{user_id}', '{cookie}')"

get_userid = "SELECT user_id FROM mg_users WHERE user_name = '{user_name}' AND user_pass = MD5('{password}')"

scoretypes = "SELECT * FROM mg_scoretypes"

get_candidate = "SELECT * FROM mg_candidates WHERE candidate_id = '{candidate_id}'::uuid"

get_cand_scores = "SELECT s.score_type, s.score, t.score_info FROM mg_candidates_scores s LEFT JOIN mg_scoretypes t ON (s.score_type = t.scoretype) WHERE s.candidate_id = '{candidate_id}'::uuid GROUP BY s.score_type, s.score, t.score_info ORDER BY score_type"

get_recgroups = "SELECT mg_occurrenceid, occurrenceid, eventdate, locality, countrycode, higherclassification, recordedby FROM mg_occurrences WHERE mg_occurrenceid IN (SELECT mg_occurrenceid FROM mg_records WHERE recgroup_id = '{recgroup_id}'::uuid)"

get_spp_group = "SELECT * FROM mg_recordgroups WHERE species = '{species}' AND collex_id = '{collex_id}'::uuid AND no_candidates > 0 AND recgroup_id NOT IN (SELECT recgroup_id FROM mg_selected_candidates WHERE collex_id = '{collex_id}'::uuid) ORDER BY locality ASC, no_records DESC"

get_collex_spp = "SELECT DISTINCT species FROM mg_recordgroups WHERE collex_id = '{collex_id}'::uuid AND no_candidates > 0 AND recgroup_id NOT IN (SELECT recgroup_id FROM mg_selected_candidates WHERE collex_id = '{collex_id}'::uuid)"

get_collex_info = "SELECT m.*, COUNT(DISTINCT r.species) as no_species, count(r.*) as no_recordgroups, sum(r.no_records) as no_records, count(s.*) AS no_selected_matches FROM mg_collex m LEFT JOIN mg_recordgroups r ON (m.collex_id = r.collex_id) LEFT JOIN mg_selected_candidates s ON (r.recgroup_id = s.recgroup_id) WHERE m.collex_id = '{collex_id}'::UUID GROUP BY m.collex_id"

get_collex = "SELECT c.* FROM mg_collex c, mg_users_collex u WHERE c.collex_id = u.collex_id AND u.user_id = '{user_id}'::UUID"

get_folder_id = "SELECT folder_id FROM files WHERE file_id = %(file_id)s"

get_datasources = "SELECT *, TO_CHAR(no_features, '999,999,999,999') as no_feat, TO_CHAR(source_date::date, 'dd Mon yyyy') as date_f FROM data_sources WHERE is_online = 't' ORDER BY datasource_id ASC"

get_onedatasource = "SELECT *, TO_CHAR(no_features, '999,999,999,999') as no_feat, TO_CHAR(source_date::date, 'dd Mon yyyy') as date_f FROM data_sources WHERE is_online = 't' AND datasource_id = %(datasource_id)s"
