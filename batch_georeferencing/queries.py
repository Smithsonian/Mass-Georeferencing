#Postgres queries for mass_georef
# 2020-06-25

get_collex = "SELECT * FROM mg_collex WHERE collex_id = %s"


get_collex_species = "SELECT DISTINCT species FROM mg_occurrences WHERE collex_id = %s"


delete_collex_matches = "DELETE FROM mg_recordgroups WHERE collex_id = %s"


get_spp_countries = "SELECT countrycode FROM mg_occurrences WHERE species = %s AND collex_id = %s AND lower(locality) <> ANY(ARRAY['none', 'unknown', 'no locality data']) GROUP BY countrycode"


get_records_for_country = "SELECT locality, stateprovince, countrycode, recordedby, kingdom, phylum, class, _order, family, genus, species, elevation, count(*) AS no_records FROM mg_occurrences WHERE species = %(species)s AND countrycode = %(countrycode)s AND collex_id = %(collex_id)s AND lower(locality) <> ANY(ARRAY['none', 'unknown', 'no locality data']) GROUP BY locality, stateprovince, countrycode, recordedby, kingdom, phylum, class, _order, family, genus, species, elevation"


insert_mg_recordgroups = "INSERT INTO mg_recordgroups (recgroup_id, collex_id, locality, stateprovince, countrycode, recordedby, kingdom, phylum, class, _order, family, genus, species, no_records) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"


insert_mg_records = "INSERT INTO mg_records (recgroup_id, mg_occurrenceid, updated_at) (SELECT %(recgroup_id)s AS recgroup_id, mg_occurrenceid, NOW() FROM mg_occurrences WHERE species = %(species)s AND countrycode = %(countrycode)s AND decimallatitude IS NULL AND lower(locality) <> ANY(ARRAY['none', 'unknown', 'no locality data']) AND locality = %(locality)s AND stateprovince = %(stateprovince)s AND kingdom = %(kingdom)s AND phylum = %(phylum)s AND class = %(class)s AND _order = %(_order)s AND family = %(family)s AND genus = %(genus)s)"


gbif_species_country = "SELECT MAX(gbifid::bigint) AS uid, locality AS name, count(*) AS no_records, countrycode, trim(leading ', ' FROM replace(municipality || ', ' || county || ', ' || stateprovince || ', ' || countrycode, ', , ', '')) AS located_at, stateprovince, recordedBy, decimallatitude, decimallongitude, count(*) AS no_features, 'gbif.species' AS data_source FROM gbif WHERE species = '{species}' AND lower(locality) <> ANY(ARRAY['none', 'unknown', 'no locality data']) AND countrycode = '{countrycode}' AND decimallatitude IS NOT NULL GROUP BY countrycode, locality, municipality, county, stateprovince, recordedBy, decimallatitude, decimallongitude"


gbif_species = "SELECT MAX(gbifid::bigint) AS uid, locality AS name, count(*) AS no_records, countrycode, trim(leading ', ' FROM replace(municipality || ', ' || county || ', ' || stateprovince || ', ' || countrycode, ', , ', '')) AS located_at, stateprovince, recordedBy, decimallatitude, decimallongitude, count(*) AS no_features, 'gbif.species' AS data_source FROM gbif WHERE species = '{species}' AND lower(locality) <> ANY(ARRAY['none', 'unknown', 'no locality data']) AND decimallatitude IS NOT NULL GROUP BY countrycode, locality, municipality, county, stateprovince, recordedBy, decimallatitude, decimallongitude"


gbif_species_genus_country = "SELECT MAX(gbifid::bigint) AS uid, locality AS name, count(*) AS no_records, countrycode, trim(leading ', ' FROM replace(municipality || ', ' || county || ', ' || stateprovince || ', ' || countrycode, ', , ', '')) AS located_at, stateprovince, recordedBy, decimallatitude, decimallongitude, count(*) AS no_features, 'gbif.species' AS data_source FROM gbif WHERE species = '{genus} %' AND lower(locality) <> ANY(ARRAY['none', 'unknown', 'no locality data']) AND countrycode = '{countrycode}' AND decimallatitude IS NOT NULL GROUP BY countrycode, locality, municipality, county, stateprovince, recordedBy, decimallatitude, decimallongitude"


gbif_genus = "SELECT MAX(gbifid::bigint) AS uid, locality AS name, count(*) AS no_records, countrycode, trim(leading ', ' FROM replace(municipality || ', ' || county || ', ' || stateprovince || ', ' || countrycode, ', , ', '')) AS located_at, stateprovince, recordedBy, decimallatitude, decimallongitude, count(*) AS no_features, 'gbif.genus' AS data_source FROM gbif WHERE species ILIKE '{genus} %' AND species != '{species}' AND lower(locality) <> ANY(ARRAY['none', 'unknown', 'no locality data']) AND decimallatitude IS NOT NULL GROUP BY countrycode, locality, municipality, county, stateprovince, recordedBy, decimallatitude, decimallongitude"


gbif_genus_country = "SELECT MAX(gbifid::bigint) AS uid, species, locality AS name, count(*) AS no_records, countrycode, trim(leading ', ' FROM replace(municipality || ', ' || county || ', ' || stateprovince || ', ' || countrycode, ', , ', '')) AS located_at, stateprovince, recordedBy, decimallatitude, decimallongitude, count(*) AS no_features, 'gbif.genus' AS data_source FROM gbif WHERE species ILIKE '{genus} %' AND species != '{species}' AND lower(locality) <> ANY(ARRAY['none', 'unknown', 'no locality data']) AND countrycode = '{countrycode}' AND decimallatitude IS NOT NULL GROUP BY species, countrycode, locality, municipality, county, stateprovince, recordedBy, decimallatitude, decimallongitude"


wdpa_iso = """
        WITH data AS (
            SELECT uid, name, gadm2 AS stateprovince, 'wdpa_polygons' AS data_source FROM wdpa_polygons WHERE parent_iso = '{iso}' AND lower(name) != 'unknown'
            UNION 
            SELECT uid, orig_name AS name, gadm2 AS stateprovince, 'wdpa_polygons' AS data_source FROM wdpa_polygons WHERE parent_iso = '{iso}' AND lower(name) != 'unknown'
            UNION 
            SELECT uid, name, gadm2 AS stateprovince, 'wdpa_points' AS data_source FROM wdpa_points WHERE parent_iso = '{iso}' AND lower(name) != 'unknown'
            UNION 
            SELECT uid, orig_name AS name, gadm2 AS stateprovince, 'wdpa_points' AS data_source FROM wdpa_points WHERE parent_iso = '{iso}' AND lower(name) != 'unknown'
        )
        SELECT uid, name, stateprovince, data_source FROM data GROUP BY uid, name, stateprovince, data_source
            """


wdpa_iso_state = """
        WITH data AS (
            SELECT uid, name, gadm2 AS stateprovince, 'wdpa_polygons' AS data_source FROM wdpa_polygons WHERE parent_iso = '{iso}' AND gadm2 ILIKE '%{stateprovince}%' AND lower(name) != 'unknown'
            UNION 
            SELECT uid, orig_name AS name, gadm2 AS stateprovince, 'wdpa_polygons' AS data_source FROM wdpa_polygons WHERE parent_iso = '{iso}' AND gadm2 ILIKE '%{stateprovince}%' AND lower(name) != 'unknown'
            UNION 
            SELECT uid, name, gadm2 AS stateprovince, 'wdpa_points' AS data_source FROM wdpa_points WHERE parent_iso = '{iso}' AND gadm2 ILIKE '%{stateprovince}%' AND lower(name) != 'unknown'
            UNION 
            SELECT uid, orig_name AS name, gadm2 AS stateprovince, 'wdpa_points' AS data_source FROM wdpa_points WHERE parent_iso = '{iso}' AND gadm2 ILIKE '%{stateprovince}%' AND lower(name) != 'unknown'
        )
        SELECT uid, name, stateprovince, data_source FROM data GROUP BY uid, name, stateprovince, data_source
            """


gadm_country = """
        SELECT uid, name_1 AS name, name_1 AS stateprovince, 'gadm' AS data_source FROM gadm1 WHERE gid_0 = %(iso)s 
        UNION 
        SELECT uid, varname_1 AS name, name_1 AS stateprovince, 'gadm' AS data_source FROM gadm1 WHERE gid_0 = %(iso)s AND varname_1 IS NOT NULL
        UNION
        SELECT uid, name_2 AS name, name_1 || ', ' || name_0 AS stateprovince, 'gadm' AS data_source FROM gadm2 WHERE gid_0 = %(iso)s 
        UNION 
        SELECT uid, varname_2 AS name, name_1 || ', ' || name_0 AS stateprovince, 'gadm' AS data_source FROM gadm2 WHERE gid_0 = %(iso)s AND varname_2 IS NOT NULL
        UNION
        SELECT uid, name_3 AS name, name_2 || ', ' || name_1 || ', ' || name_0 AS stateprovince, 'gadm' AS data_source FROM gadm3 WHERE gid_0 = %(iso)s 
        UNION 
        SELECT uid, varname_3 AS name, name_2 || ', ' || name_1 || ', ' || name_0 AS stateprovince, 'gadm' AS data_source FROM gadm3 WHERE gid_0 = %(iso)s AND varname_3 IS NOT NULL
        UNION
        SELECT uid, name_4 AS name, name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0 AS stateprovince, 'gadm' AS data_source FROM gadm4 WHERE gid_0 = %(iso)s 
        UNION 
        SELECT uid, varname_4 AS name, name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0 AS stateprovince, 'gadm' AS data_source FROM gadm4 WHERE gid_0 = %(iso)s AND varname_4 IS NOT NULL
        UNION 
        SELECT uid, name_5 AS name, name_4 || ', ' || name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0 AS stateprovince, 'gadm' AS data_source FROM gadm5 WHERE gid_0 = %(iso)s
        
        UNION
        SELECT uid, name_2 || ' Co., ' || name_1 as name, name_1 || ', ' || name_0 AS stateprovince, 'gadm' AS data_source FROM gadm2 WHERE gid_0 = %(iso)s AND name_0 = 'United States' AND type_2 = 'County'
        UNION
        SELECT uid, name_2 || ' ' || type_2 || ', ' || name_1 as name, name_1 || ', ' || name_0 AS stateprovince, 'gadm' AS data_source FROM gadm2 WHERE gid_0 = %(iso)s AND name_0 = 'United States'
        UNION

        (SELECT uid, g.name_2 || ', ' || s.abbreviation as name, name_1 || ', ' || name_0 AS stateprovince, 'gadm' AS data_source FROM gadm2 g, us_state_abbreviations s WHERE gid_0 = %(iso)s AND g.name_1 = s.state AND g.name_0 = 'United States'
        GROUP BY uid, name, stateprovince)

        UNION

        (SELECT uid, g.name_2 || ' Co., ' || s.abbreviation as name, name_1 || ', ' || name_0 AS stateprovince, 'gadm' AS data_source FROM gadm2 g, us_state_abbreviations s WHERE gid_0 = %(iso)s AND g.name_1 = s.state AND g.name_0 = 'United States'
        GROUP BY uid, name, stateprovince)
        """


gadm_country_state = """
        SELECT uid, name_1 AS name, name_1 AS stateprovince, 'gadm' AS data_source FROM gadm1 WHERE gid_0 = %(iso)s AND name_1 ILIKE %(stateprovince)s
        UNION 
        SELECT uid, varname_1 AS name, name_1 AS stateprovince, 'gadm' AS data_source FROM gadm1 WHERE gid_0 = %(iso)s AND name_1 ILIKE %(stateprovince)s AND varname_1 IS NOT NULL 
        UNION
        SELECT uid, name_2 AS name, name_1 || ', ' || name_0 AS stateprovince, 'gadm' AS data_source FROM gadm2 WHERE gid_0 = %(iso)s AND name_1 ILIKE %(stateprovince)s
        UNION 
        SELECT uid, varname_2 AS name, name_1 || ', ' || name_0 AS stateprovince, 'gadm' AS data_source FROM gadm2 WHERE gid_0 = %(iso)s AND name_1 ILIKE %(stateprovince)s AND varname_2 IS NOT NULL
        UNION
        SELECT uid, name_3 AS name, name_2 || ', ' || name_1 || ', ' || name_0 AS stateprovince, 'gadm' AS data_source FROM gadm3 WHERE gid_0 = %(iso)s AND name_1 ILIKE %(stateprovince)s
        UNION 
        SELECT uid, varname_3 AS name, name_2 || ', ' || name_1 || ', ' || name_0 AS stateprovince, 'gadm' AS data_source FROM gadm3 WHERE gid_0 = %(iso)s AND name_1 ILIKE %(stateprovince)s AND varname_3 IS NOT NULL
        UNION
        SELECT uid, name_4 AS name, name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0 AS stateprovince, 'gadm' AS data_source FROM gadm4 WHERE gid_0 = %(iso)s AND name_1 ILIKE %(stateprovince)s
        UNION 
        SELECT uid, varname_4 AS name, name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0 AS stateprovince, 'gadm' AS data_source FROM gadm4 WHERE gid_0 = %(iso)s AND name_1 ILIKE %(stateprovince)s AND varname_4 IS NOT NULL
        UNION 
        SELECT uid, name_5 AS name, name_4 || ', ' || name_3 || ', ' || name_2 || ', ' || name_1 || ', ' || name_0 AS stateprovince, 'gadm' AS data_source FROM gadm5 WHERE gid_0 = %(iso)s AND name_1 ILIKE %(stateprovince)s
        
        UNION
        SELECT uid, name_2 || ' Co., ' || name_1 as name, name_1 || ', ' || name_0 AS stateprovince, 'gadm' AS data_source FROM gadm2 WHERE gid_0 = %(iso)s AND name_1 ILIKE %(stateprovince)s AND name_0 = 'United States' AND type_2 = 'County'
        UNION
        SELECT uid, name_2 || ' ' || type_2 || ', ' || name_1 as name, name_1 || ', ' || name_0 AS stateprovince, 'gadm' AS data_source FROM gadm2 WHERE gid_0 = %(iso)s AND name_1 ILIKE %(stateprovince)s AND name_0 = 'United States'
        UNION

        (SELECT uid, g.name_2 || ', ' || s.abbreviation as name, name_1 || ', ' || name_0 AS stateprovince, 'gadm' AS data_source FROM gadm2 g, us_state_abbreviations s WHERE gid_0 = %(iso)s AND name_1 ILIKE %(stateprovince)s AND g.name_1 = s.state AND g.name_0 = 'United States'
        GROUP BY uid, name, stateprovince)

        UNION

        (SELECT uid, g.name_2 || ' Co., ' || s.abbreviation as name, name_1 || ', ' || name_0 AS stateprovince, 'gadm' AS data_source FROM gadm2 g, us_state_abbreviations s WHERE gid_0 = %(iso)s AND name_1 ILIKE %(stateprovince)s AND g.name_1 = s.state AND g.name_0 = 'United States'
        GROUP BY uid, name, stateprovince)
        """


gnis_query = "SELECT uid, feature_name AS name, gadm2 AS stateprovince, 'gnis' AS data_source FROM gnis"


gnis_query_state = "SELECT uid, feature_name AS name, gadm2 AS stateprovince, 'gnis' AS data_source FROM gnis WHERE gadm2 ILIKE %(state)s"


#hist_counties_query = "SELECT uid, name, state_terr AS stateprovince, 'hist_counties' AS data_source FROM hist_counties WHERE state_terr ILIKE '{}' AND start_date >= '{}'::date AND end_date <= '{}'::date"


hist_counties_query_nodate = "SELECT uid, name, state_terr AS stateprovince, 'hist_counties' AS data_source, start_date, end_date FROM hist_counties"


hist_counties_query_nodate_state = "SELECT uid, name, state_terr AS stateprovince, 'hist_counties' AS data_source, start_date, end_date FROM hist_counties WHERE state_terr ILIKE %(state)s"


tiger_query = "SELECT uid, name, stateprovince, data_source FROM tiger"


tiger_query_state = "SELECT uid, name, stateprovince, data_source FROM tiger WHERE stateprovince ILIKE %(state)s"


topos_query = """SELECT 
                    uid, name, stateprovince, data_source 
                FROM 
                    topo_map_points
                UNION
                SELECT 
                    uid, name, stateprovince, data_source 
                FROM 
                    topo_map_polygons
                """


topos_query_state = """SELECT 
                    uid, name, stateprovince, data_source 
                FROM 
                    topo_map_points
                WHERE 
                    stateprovince ILIKE %(state)s
                UNION
                SELECT 
                    uid, name, stateprovince, data_source 
                FROM 
                    topo_map_polygons 
                WHERE 
                    stateprovince ILIKE %(state)s"""


#usa_rivers_query = "WITH data AS (SELECT uid, TRIM(REPLACE(REPLACE(REPLACE(REPLACE(LOWER(name), 'river', ''), 'lake', ''), 'lagoon', ''), 'creek', '')) AS name, gadm2 as stateprovince, 'usa_rivers' as data_source FROM usa_rivers) SELECT * FROM data WHERE name != ''"
usa_rivers_query = "SELECT uid, name, gadm2 as stateprovince, 'usa_rivers' as data_source FROM usa_rivers"


usa_rivers_query_state = "SELECT uid, name, gadm2 as stateprovince, 'usa_rivers' as data_source FROM usa_rivers WHERE gadm2 ILIKE %(state)s"


usgs_nat_struct_query = "SELECT uid, name, gadm2 as stateprovince, 'usgs_nat_struct' as data_source FROM usgs_nat_struct"


usgs_nat_struct_query_state = "SELECT uid, name, gadm2 as stateprovince, 'usgs_nat_struct' as data_source FROM usgs_nat_struct WHERE gadm2 ILIKE %(state)s"


usa_histplaces_query = """
            SELECT uid, name, stateprovince, 'usa_histplaces_points' as data_source FROM usa_histplaces_points
            UNION
            SELECT uid, name, stateprovince, 'usa_histplaces_poly' as data_source FROM usa_histplaces_poly
            """


usa_histplaces_query_state = """
            SELECT uid, name, stateprovince, 'usa_histplaces_points' as data_source FROM usa_histplaces_points WHERE stateprovince ILIKE %(state)s
            UNION
            SELECT uid, name, stateprovince, 'usa_histplaces_poly' as data_source FROM usa_histplaces_poly WHERE stateprovince ILIKE %(state)s
            """


gns_query = "SELECT uid, full_name_nd_ro AS name, gadm2 AS stateprovince, 'gns' AS data_source FROM gns"


gns_query_country = "SELECT uid, full_name_nd_ro AS name, gadm2 AS stateprovince, 'gns' AS data_source FROM gns WHERE gadm2 ILIKE %(country)s"


gns_query_country_state = "SELECT uid, full_name_nd_ro AS name, gadm2 AS stateprovince, 'gns' AS data_source FROM gns WHERE gadm2 ILIKE %(statecountry)s"


global_lakes_null = "SELECT uid, lake_name AS name, gadm2 AS stateprovince, 'global_lakes' AS data_source FROM global_lakes"


global_lakes = "SELECT uid, lake_name AS name, gadm2 AS stateprovince, 'global_lakes' AS data_source FROM global_lakes WHERE country ILIKE %(country)s"


geonames = """
        WITH data AS (
            SELECT uid, name, gadm2 AS stateprovince, 'geonames' AS data_source FROM geonames WHERE country_code = %(countrycode)s
            UNION
            SELECT uid, unnest(string_to_array(alternatenames, ',')) AS name, gadm2 AS stateprovince, 'geonames' AS data_source FROM geonames WHERE country_code = %(countrycode)s
            )
        SELECT uid, name, stateprovince, data_source FROM data GROUP BY uid, name, stateprovince, data_source
            """


geonames_state = """
        WITH data AS (
            SELECT uid, name, gadm2 AS stateprovince, 'geonames' AS data_source FROM geonames WHERE country_code = %(countrycode)s AND gadm2 ILIKE %(stateprovince)s
            UNION
            SELECT uid, unnest(string_to_array(alternatenames, ',')) AS name, gadm2 AS stateprovince, 'geonames' AS data_source FROM geonames WHERE country_code = %(countrycode)s AND gadm2 ILIKE %(stateprovince)s
            )
        SELECT uid, name, stateprovince, data_source FROM data GROUP BY uid, name, stateprovince, data_source
            """


# geonames_null = """
#         WITH data AS (
#             SELECT uid, name, gadm2 AS stateprovince, 'geonames' AS data_source FROM geonames
#             UNION
#             SELECT uid, unnest(string_to_array(alternatenames, ',')) AS name, gadm2 AS stateprovince, 'geonames' AS data_source FROM geonames WHERE alternatenames != ''
#             )
#         SELECT uid, name, stateprovince, data_source FROM data GROUP BY uid, name, stateprovince, data_source
#             """


wikidata_by_country = """
        WITH data AS (
            SELECT uid, name, gadm2 AS stateprovince, 'wikidata' AS data_source FROM wikidata_records WHERE gadm2 ILIKE %(country)s
            UNION
            SELECT r.uid, n.name, r.gadm2 AS stateprovince, 'wikidata' AS data_source FROM wikidata_records r, wikidata_names n WHERE r.source_id = n.source_id AND gadm2 ILIKE %(country)s
            )
        SELECT uid, name, stateprovince, data_source FROM data GROUP BY uid, name, stateprovince, data_source
            """


wikidata_by_country_state = """
        WITH data AS (
            SELECT uid, name, gadm2 AS stateprovince, 'wikidata' AS data_source FROM wikidata_records WHERE gadm2 ILIKE %(statecountry)s
            UNION
            SELECT r.uid, n.name, r.gadm2 AS stateprovince, 'wikidata' AS data_source FROM wikidata_records r, wikidata_names n WHERE r.source_id = n.source_id AND gadm2 ILIKE %(statecountry)s
            )
        SELECT uid, name, stateprovince, data_source FROM data GROUP BY uid, name, stateprovince, data_source
            """


wikidata_all = """
        WITH data AS (
            SELECT uid, name, gadm2 AS stateprovince, 'wikidata' AS data_source FROM wikidata_records
            UNION
            SELECT r.uid, n.name, r.gadm2 AS stateprovince, 'wikidata' AS data_source FROM wikidata_records r, wikidata_names n WHERE r.source_id = n.source_id
            )
        SELECT uid, name, stateprovince, data_source FROM data GROUP BY uid, name, stateprovince, data_source
            """


osm_by_country = """
            SELECT 
                uid, name, gadm2 AS stateprovince, 'osm' AS data_source 
            FROM 
                osm 
            WHERE 
                gadm2 ILIKE %(country)s
            GROUP BY 
                uid, name, gadm2
            """


osm_by_country_state = """
            SELECT 
                uid, name, gadm2 AS stateprovince, 'osm' AS data_source 
            FROM 
                osm 
            WHERE 
                gadm2 ILIKE %(statecountry)s
            GROUP BY 
                uid, name, gadm2
                """


# osm_all = """
#         WITH data AS (
#             SELECT uid, name, gadm2 AS stateprovince, 'osm' AS data_source FROM osm
#             )
#         SELECT uid, name, stateprovince, data_source FROM data GROUP BY uid, name, stateprovince, data_source
#             """


recordgroups_stats = """WITH stats AS (
                            SELECT 
                                recgroup_id, 
                                coalesce(count(candidate_id), 0) AS no_candidates
                            FROM 
                                mg_candidates 
                            WHERE 
                                recgroup_id IN (
                                            SELECT 
                                                recgroup_id 
                                            FROM 
                                                mg_recordgroups 
                                            WHERE 
                                                species = %(species)s AND
                                                collex_id = %(collex_id)s
                                            ) 
                                GROUP BY recgroup_id
                            )
                        UPDATE mg_recordgroups r SET no_candidates = s.no_candidates FROM stats s WHERE r.recgroup_id = s.recgroup_id"""

get_species_candidates = "SELECT candidate_id, data_source, feature_id, %(species)s AS species FROM mg_candidates mc WHERE recgroup_id IN (SELECT recgroup_id FROM mg_recordgroups WHERE species = %(species)s AND collex_id = %(collex_id)s) GROUP BY candidate_id, data_source, feature_id"

get_candidates_country = "SELECT candidate_id, data_source, feature_id, %(species)s AS species FROM mg_candidates mc WHERE recgroup_id IN (SELECT recgroup_id FROM mg_recordgroups WHERE species = %(species)s AND collex_id = %(collex_id)s AND countrycode = %(countrycode)s) GROUP BY candidate_id, data_source, feature_id"

