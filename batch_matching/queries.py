#Postgres queries for mass_georef
# 2020-02-27

get_collex = "SELECT * FROM mg_collex WHERE collex_id = %s"

delete_spp_records = "DELETE FROM mg_recordgroups WHERE species = %s"

get_spp_countries = "SELECT countrycode FROM mg_occurrences WHERE species = %s AND decimallatitude IS NULL AND countrycode IS NOT NULL AND lower(locality) <> ANY(ARRAY['none', 'unknown', 'no locality data']) GROUP BY countrycode"

get_records_for_country = "SELECT locality, stateprovince, countrycode, recordedby, kingdom, phylum, class, _order, family, genus, species, count(*) AS no_records FROM mg_occurrences WHERE species = %(species)s AND countrycode = %(countrycode)s AND decimallatitude IS NULL AND lower(locality) <> ANY(ARRAY['none', 'unknown', 'no locality data']) GROUP BY locality, stateprovince, countrycode, recordedby, kingdom, phylum, class, _order, family, genus, species"

insert_mg_recordgroups = "INSERT INTO mg_recordgroups (recgroup_id, collex_id, locality, stateprovince, countrycode, recordedby, kingdom, phylum, class, _order, family, genus, species, no_records) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"

insert_mg_records = "INSERT INTO mg_records (recgroup_id, mg_occurrenceid, updated_at) (SELECT %(recgroup_id)s AS recgroup_id, mg_occurrenceid, NOW() FROM mg_occurrences WHERE species = %(species)s AND countrycode = %(countrycode)s AND decimallatitude IS NULL AND lower(locality) <> ANY(ARRAY['none', 'unknown', 'no locality data']) AND locality = %(locality)s AND stateprovince = %(stateprovince)s AND kingdom = %(kingdom)s AND phylum = %(phylum)s AND class = %(class)s AND _order = %(_order)s AND family = %(family)s AND genus = %(genus)s)"

gbif_species_country = "SELECT MAX(gbifid::bigint) AS uid, locality AS name, count(*) AS no_records, countrycode, trim(leading ', ' FROM replace(municipality || ', ' || county || ', ' || stateprovince || ', ' || countrycode, ', , ', '')) AS located_at, stateprovince, recordedBy, decimallatitude, decimallongitude, count(*) AS no_features FROM gbif WHERE species = '{species}' AND lower(locality) <> ANY(ARRAY['none', 'unknown', 'no locality data']) AND countrycode = ANY('{{{countrycode}}}'::text[]) AND decimallatitude IS NOT NULL GROUP BY countrycode, locality, municipality, county, stateprovince, recordedBy, decimallatitude, decimallongitude"

gbif_genus_country = "SELECT MAX(gbifid::bigint) AS uid, species, locality AS name, count(*) AS no_records, countrycode, trim(leading ', ' FROM replace(municipality || ', ' || county || ', ' || stateprovince || ', ' || countrycode, ', , ', '')) AS located_at, stateprovince, recordedBy, decimallatitude, decimallongitude, count(*) AS no_features FROM gbif WHERE species ILIKE '{genus}%' AND species != '{species}' AND lower(locality) <> ANY(ARRAY['none', 'unknown', 'no locality data']) AND countrycode = ANY('{{{countrycode}}}'::text[]) AND decimallatitude IS NOT NULL GROUP BY species, countrycode, locality, municipality, county, stateprovince, recordedBy, decimallatitude, decimallongitude"

wdpa_iso = """
        WITH data AS (SELECT uid, name, gadm2 AS stateprovince, 'wdpa_polygons' AS data_source FROM wdpa_polygons WHERE parent_iso LIKE '%{iso}%' AND lower(name) != 'unknown'
        UNION 
        SELECT uid, orig_name AS name, gadm2 AS stateprovince, 'wdpa_polygons' AS data_source FROM wdpa_polygons WHERE parent_iso LIKE '%{iso}%' AND lower(name) != 'unknown'
        UNION 
        SELECT uid, name, gadm2 AS stateprovince, 'wdpa_points' AS data_source FROM wdpa_points WHERE parent_iso LIKE '%{iso}%' AND lower(name) != 'unknown'
        UNION 
        SELECT uid, orig_name AS name, gadm2 AS stateprovince, 'wdpa_points' AS data_source FROM wdpa_points WHERE parent_iso LIKE '%{iso}%' AND lower(name) != 'unknown')
        SELECT uid, name, stateprovince, data_source FROM data GROUP BY uid, name, stateprovince, data_source
            """

gadm_country = """
        SELECT uid, name_1 AS name, name_1 AS stateprovince, 'gadm1' AS data_source FROM gadm1 WHERE name_0 = %(country)s 
        UNION 
        SELECT uid, varname_1 AS name, name_1 AS stateprovince, 'gadm1' AS data_source FROM gadm1 WHERE name_0 = %(country)s AND varname_1 IS NOT NULL
        UNION
        SELECT uid, name_2 AS name, name_1 || ', ' || name_0 AS stateprovince, 'gadm2' AS data_source FROM gadm2 WHERE name_0 = %(country)s 
        UNION 
        SELECT uid, varname_2 AS name, name_1 || ', ' || name_0 AS stateprovince, 'gadm2' AS data_source FROM gadm2 WHERE name_0 = %(country)s AND varname_2 IS NOT NULL
        UNION
        SELECT uid, name_3 AS name, name_2 || ', ' || name_1 || ', ' || name_0 AS stateprovince, 'gadm3' AS data_source FROM gadm3 WHERE name_0 = %(country)s 
        UNION 
        SELECT uid, varname_3 AS name, name_2 || ', ' || name_1 || ', ' || name_0 AS stateprovince, 'gadm3' AS data_source FROM gadm3 WHERE name_0 = %(country)s AND varname_3 IS NOT NULL
        UNION
        SELECT uid, name_4 AS name, name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0 AS stateprovince, 'gadm4' AS data_source FROM gadm4 WHERE name_0 = %(country)s 
        UNION 
        SELECT uid, varname_4 AS name, name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0 AS stateprovince, 'gadm4' AS data_source FROM gadm4 WHERE name_0 = %(country)s AND varname_4 IS NOT NULL
        UNION 
        SELECT uid, name_5 AS name, name_4 || ', ' || name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0 AS stateprovince, 'gadm5' AS data_source FROM gadm5 WHERE name_0 = %(country)s
        """


gnis_query = "SELECT uid, feature_name AS name, gadm2 AS stateprovince, 'gnis' AS data_source FROM gnis WHERE gadm2 ILIKE '%{}, United States'"


tiger_query = "SELECT uid, fullname AS name, gadm2 AS stateprovince, 'tiger' AS data_source FROM tiger WHERE gadm2 ILIKE '%{}, United States'"


gns_query = "SELECT uid, full_name_nd_ro AS name, gadm2 AS stateprovince, 'gns' AS data_source FROM gns WHERE cc1 = %(countrycode)s"

global_lakes = "SELECT uid, lake_name AS name, gadm2 AS stateprovince, 'global_lakes' AS data_source FROM global_lakes WHERE country ILIKE '%{country}%'"

geonames = """
        WITH data AS (
            SELECT uid, name, gadm2 AS stateprovince, 'geonames' AS data_source FROM geonames WHERE country_code = %(countrycode)s
            UNION
            SELECT uid, unnest(string_to_array(alternatenames, ',')) AS name, gadm2 AS stateprovince, 'geonames' AS data_source FROM geonames WHERE country_code = %(countrycode)s
            )
        SELECT uid, name, stateprovince, data_source FROM data GROUP BY uid, name, stateprovince, data_source
            """

recordgroups_stats = """WITH stats AS (
                            SELECT 
                                recgroup_id, 
                                count(candidate_id) AS no_candidates
                            FROM 
                                mg_candidates 
                            WHERE 
                                recgroup_id IN (
                                            SELECT 
                                                recgroup_id 
                                            FROM 
                                                mg_recordgroups 
                                            WHERE 
                                                species = %(species)s
                                            ) 
                                GROUP BY recgroup_id
                            )
                        UPDATE mg_recordgroups r SET no_candidates = s.no_candidates FROM stats s WHERE r.recgroup_id = s.recgroup_id"""

get_species_candidates = "SELECT candidate_id, data_source, feature_id, %(species)s AS species FROM mg_candidates mc WHERE recgroup_id IN (SELECT recgroup_id FROM mg_recordgroups WHERE species = %(species)s) GROUP BY candidate_id, data_source, feature_id"

