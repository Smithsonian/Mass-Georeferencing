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
                calc AS (
                    SELECT 
                        '{candidate_id}' as candidate_id, 
                        'locality.spatial' as score_type, 
                        ST_Distance(l.the_geom_webmercator, r.the_geom_webmercator) AS geom_dist 
                    FROM 
                        {data_source} l, range r
                    WHERE l.uid = '{feature_id}'::uuid
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

