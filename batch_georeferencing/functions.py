#Functions for mass_georef
# 2020-02-27

import psycopg2, psycopg2.extras, re

def check_spatial(data_source, species, candidate_id, feature_id, cur, log):
    """
    Get the distance from the species' range
    To convert to API call
    """
    if data_source == 'gbif.species' or data_source == 'gbif.genus':
        return
    else:
        #Use a try in case there is a problem with the geom
        try:
            cur.execute(re.sub(' +', ' ', """
                WITH data AS (
                        SELECT 
                            ST_Union(the_geom) as the_geom
                        FROM 
                            iucn
                        WHERE
                            sciname = '{species}'

                        UNION ALL

                        SELECT 
                            ST_ConvexHull(ST_Collect(the_geom)) as the_geom
                        FROM 
                            gbif
                        WHERE
                            species = '{species}'
                ),
                range AS (
                    SELECT 
                        ST_Transform(ST_Union(the_geom), 3857) as the_geom_webmercator
                    FROM
                        data
                    ),
                datasource AS (
                    SELECT 
                        the_geom
                    FROM 
                        {data_source}
                    WHERE uid = '{feature_id}'::uuid
                ),
                calc AS (
                    SELECT 
                        '{candidate_id}' as candidate_id, 
                        'locality.spatial' as score_type, 
                        ST_Distance(ST_TRANSFORM(l.the_geom, 3857), r.the_geom_webmercator) AS geom_dist 
                    FROM 
                        datasource l, range r
                )
                INSERT INTO mg_candidates_scores 
                (candidate_id, score_type, score) 
                (
                    SELECT 
                        '{candidate_id}' as candidate_id, 
                        'locality.spatial' as score_type, 
                        CASE 
                            WHEN geom_dist = 0 THEN 100 
                            WHEN geom_dist > 0 AND geom_dist < 10000 THEN 95 
                            WHEN geom_dist > 0 AND geom_dist <= 10000 THEN 95 
                            WHEN geom_dist > 10000 AND geom_dist <= 50000 THEN 85 
                            WHEN geom_dist > 50000 AND geom_dist <= 100000 THEN 75
                            WHEN geom_dist > 100000 AND geom_dist <= 100000 THEN 65
                            ELSE 60
                            END AS score 
                    FROM 
                        calc
                )""".replace('\n', '')).format(candidate_id = candidate_id, data_source = data_source, species = species, feature_id = feature_id))
            log.debug(cur.query)
        except Exception as e:
            log.error(cur.query)
            log.error(e)
            return
    return



def check_spatial_extent(data_source, feature_id, candidate_id, collex_id, species, cur, log):
    """
    Delete candidates outside the project's area
    """
    try:
        if data_source == 'gbif.species' or data_source == 'gbif.genus' or data_source == 'gbif':
            cur.execute("""
            DELETE FROM ONLY mg_candidates
                 WHERE 
                    data_source = '{data_source}' AND
                    candidate_id = '{candidate_id}'::uuid AND
                    feature_id IN 
                    (
                        SELECT 
                            d.gbifid::text AS feature_id
                        FROM 
                            gbif d, 
                            mg_polygons g 
                        WHERE 
                            d.gbifid = '{feature_id}' AND
                            g.collex_id = '{collex_id}'::uuid AND
                            d.species = '{species}' AND
                            ST_INTERSECTS(d.the_geom, g.the_geom) = 'f'
                    )
            """.replace('\n', '').format(data_source = data_source, feature_id = feature_id, candidate_id = candidate_id, collex_id = collex_id, species = species))
        else:
            cur.execute("""
            DELETE FROM ONLY mg_candidates
                 WHERE 
                    data_source = '{data_source}' AND
                    candidate_id = '{candidate_id}'::uuid AND
                    feature_id IN 
                    (
                        SELECT 
                            d.uid::text AS feature_id
                        FROM 
                            {data_source} d, 
                            mg_polygons g 
                        WHERE 
                            d.uid = '{feature_id}'::uuid AND
                            g.collex_id = '{collex_id}'::uuid AND
                            ST_INTERSECTS(d.the_geom, g.the_geom) = 'f'
                    )
            """.replace('\n', '').format(data_source = data_source, feature_id = feature_id, candidate_id = candidate_id, collex_id = collex_id))        
        log.debug(cur.query)
    except Exception as e:
        log.error(cur.query)
        log.error(e)
        return
    return



def check_elev(data_source, species, occ_elevation, candidate_id, feature_id, cur, log):
    """
    Get the closest elevation
    """
    #Use a try in case there is a problem with the geom
    try:
        if data_source[:4] == "gbif":
            cur.execute("""
                WITH feat AS (
                    SELECT 
                        '{candidate_id}'::uuid as candidate_id, 
                        the_geom
                    FROM 
                        gbif
                    WHERE 
                        species = '{species}' AND
                        gbifid = '{feature_id}'
                ),
                calc AS (
                    SELECT 
                        l.candidate_id,
                        r.contourele as elevation,
                        ABS({occ_elevation} - r.contourele) AS elev_diff
                    FROM 
                        feat l, topo_map_vector_elev r
                    ORDER BY ST_Distance(l.the_geom, r.the_geom) ASC
                    LIMIT 1
                )
                INSERT INTO mg_candidates_scores 
                (candidate_id, score_type, score) 
                (
                    SELECT 
                        candidate_id, 
                        'elevation' as score_type, 
                        CASE 
                            WHEN elev_diff <= 100 THEN 100 
                            WHEN elev_diff > 100 AND elev_diff <= 300 THEN 90
                            WHEN elev_diff > 300 AND elev_diff <= 600 THEN 80
                            WHEN elev_diff > 600 AND elev_diff <= 1000 THEN 70
                            ELSE 20
                            END AS score 
                    FROM 
                        calc
                )""".replace('\n', '').format(candidate_id = candidate_id, species = species, data_source = data_source, feature_id = feature_id, occ_elevation = occ_elevation))
        else:
            cur.execute("""
                WITH feat AS (
                    SELECT 
                        '{candidate_id}'::uuid as candidate_id, 
                        the_geom
                    FROM 
                        {data_source}
                    WHERE uid = '{feature_id}'::uuid
                ),
                calc AS (
                    SELECT 
                        l.candidate_id,
                        r.contourele as elevation,
                        ABS({occ_elevation} - r.contourele) AS elev_diff
                    FROM 
                        feat l, topo_map_vector_elev r
                    ORDER BY ST_Distance(l.the_geom, r.the_geom) ASC
                    LIMIT 1
                )
                INSERT INTO mg_candidates_scores 
                (candidate_id, score_type, score) 
                (
                    SELECT 
                        candidate_id, 
                        'elevation' as score_type, 
                        CASE 
                            WHEN elev_diff <= 100 THEN 100 
                            WHEN elev_diff > 100 AND elev_diff <= 300 THEN 90
                            WHEN elev_diff > 300 AND elev_diff <= 600 THEN 80
                            WHEN elev_diff > 600 AND elev_diff <= 1000 THEN 70
                            ELSE 20
                            END AS score 
                    FROM 
                        calc
                )""".replace('\n', '').format(candidate_id = candidate_id, data_source = data_source, feature_id = feature_id, occ_elevation = occ_elevation))
        log.debug(cur.query)
    except Exception as e:
        log.error(cur.query)
        log.error(e)
        return
    return



def insert_candidates(candidates, cur, log):
    candidates_vals = candidates.values.tolist()
    query = """INSERT INTO mg_candidates 
                (candidate_id, recgroup_id, data_source, feature_id, no_features) 
            VALUES 
                (%s, %s, %s, %s, %s)"""
    query = re.sub(' +', ' ', query.replace('\n', ''))
    psycopg2.extras.execute_batch(cur, query, candidates_vals)
    log.debug(cur.query)
    return


def insert_scores(candidates, cur, log):
    candidates_vals = candidates.values.tolist()
    query = """INSERT INTO mg_candidates_scores 
                                (candidate_id, score_type, score) 
                            VALUES 
                                (%s, %s, %s)"""
    query = re.sub(' +', ' ', query.replace('\n', ''))
    psycopg2.extras.execute_batch(cur, query, candidates_vals)
    log.debug(cur.query)
    return

