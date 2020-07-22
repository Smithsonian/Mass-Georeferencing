#Functions for mass_georef
# 2020-02-27

import psycopg2, psycopg2.extras, swifter, uuid, unicodedata
import pandas as pd
import numpy as np
from tqdm import tqdm


#import re
from rapidfuzz import fuzz

import settings


def check_spatial(data_source, candidate_id, feature_id, species, cur, log):
    """
    Get the distance from the species' range
    To convert to API call
    """
    if data_source == 'gbif.species' or data_source == 'gbif.genus':
        return
    else:
        #Use a try in case there is a problem with the geom
        try:
            cur.execute("""
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
                )""".replace('\n', '').format(candidate_id = candidate_id, data_source = data_source, species = species, feature_id = feature_id))
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
    query = query.replace('\n', '')
    psycopg2.extras.execute_batch(cur, query, candidates_vals)
    log.debug(cur.query)
    return


def insert_scores(candidates, cur, log):
    candidates_vals = candidates.values.tolist()
    query = """INSERT INTO mg_candidates_scores 
                                (candidate_id, score_type, score) 
                            VALUES 
                                (%s, %s, %s)"""
    query = query.replace('\n', '')
    psycopg2.extras.execute_batch(cur, query, candidates_vals)
    log.debug(cur.query)
    return


def process_cands(candidates, record, cur, log, gbif = False, state = True):
    candidates['candidate_id'] = [uuid.uuid4() for _ in range(len(candidates.index))]
    candidates['candidate_id'] = candidates['candidate_id'].astype('str')
    #Remove diacritic characters
    candidates['name'].replace(np.nan, "", inplace=True)
    candidates['stateprovince'].replace(np.nan, "", inplace=True)                        
    candidates['name_ascii'] = candidates['name'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
    candidates['stateprovince_ascii'] = candidates['stateprovince'].apply(lambda x: unicodedata.normalize('NFD', x).encode('ascii', 'ignore').decode("utf-8"))
    ##################
    #Execute matches
    ##################
    #locality.partial_ratio
    #candidates['score1'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['locality'], row['name_ascii']), axis = 1)
    tqdm.pandas(desc="score1")
    candidates['score1'] = candidates.progress_apply(lambda row : fuzz.partial_ratio(record['locality'], row['name_ascii']), axis = 1)
    candidates['score1_type'] = "locality.partial_ratio"
    #locality.token_set_ratio
    #candidates['score2'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.token_set_ratio(record['locality_without_stopwords'], row['name_ascii']), axis = 1)
    tqdm.pandas(desc="score2")
    candidates['score2'] = candidates.progress_apply(lambda row : fuzz.token_set_ratio(record['locality_without_stopwords'], row['name_ascii']), axis = 1)
    candidates['score2_type'] = "locality.token_set_ratio"
    #candidates['score_locality'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).apply(lambda row : max(row['score1'], row['score2']), axis = 1)
    #tqdm.pandas(desc="score_locality")
    #allcandidates.progress_apply
    #candidates['score_locality'] = candidates.progress_apply(lambda row : max(row['score1'], row['score2']), axis = 1)
    #candidates['score_locality_type'] = "locality"
    #stateprovince
    if state == True:
        #candidates['score_state'] = candidates.swifter.set_npartitions(npartitions = settings.no_cores).allow_dask_on_strings(enable=True).apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince_ascii']), axis = 1)
        tqdm.pandas(desc="score_state")
        #allcandidates.progress_apply
        candidates['score_state'] = candidates.progress_apply(lambda row : fuzz.partial_ratio(record['stateprovince'], row['stateprovince_ascii']), axis = 1)
        candidates['score_state_type'] = "stateprovince"
    #Drop candidates with too low locality score
    candidates = candidates[(candidates.score1 + candidates.score2) > 140]
    candidates.insert(len(candidates.columns), 'recgroup_id', record['recgroup_id'])
    if gbif == False:
        candidates = candidates.assign(no_features = 1)
    #Select top 50 candidates
    if state == True:
        candidates = candidates.nlargest(50, ['score1', 'score2', 'score_state', 'no_features'])
    else:
        candidates = candidates.nlargest(50, ['score1', 'score2', 'no_features'])
    #Insert candidates and each score
    insert_candidates(candidates[['candidate_id', 'recgroup_id', 'data_source', 'uid', 'no_features']].copy(), cur, log)
    #locality
    insert_scores(candidates[['candidate_id', 'score1_type', 'score1']].copy(), cur, log)
    insert_scores(candidates[['candidate_id', 'score2_type', 'score2']].copy(), cur, log)
    if state == True:
        #stateprovince
        insert_scores(candidates[['candidate_id', 'score_state_type', 'score_state']].copy(), cur, log)
    return candidates



def delete_lowscore(species, cur, log):
    query = """WITH scores AS (
                    SELECT 
                        c.candidate_id, 
                        ROUND(AVG(s.score),1) AS score
                    FROM 
                        mg_candidates c LEFT JOIN 
                        mg_candidates_scores s ON (c.candidate_id = s.candidate_id)
                    WHERE 
                        c.recgroup_id IN (
                            SELECT 
                                recgroup_id 
                            FROM 
                                mg_recordgroups 
                            WHERE 
                                collex_id = '{collex_id}'::uuid AND
                                species = '{species}'
                            )
                    GROUP BY 
                        c.candidate_id,
                        c.data_source,
                        c.feature_id
                    )
                DELETE FROM ONLY mg_candidates c
                    USING 
                        scores s
                    WHERE 
                        c.candidate_id = s.candidate_id AND
                        s.score IS NOT NULL AND
                        s.score < {threshold}"""
    query = query.replace('\n', '')
    cur.execute(query.format(species = species, collex_id = settings.collex_id, threshold = settings.min_score))
    log.debug(cur.query)
    return


