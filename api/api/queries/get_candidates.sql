WITH score AS (
    SELECT 
      c.candidate_id, 
      ROUND(AVG(s.score),1) AS score, 
      c.data_source,
      c.feature_id,
      c.no_features
    FROM 
      mg_candidates c LEFT JOIN 
      mg_candidates_scores s ON (c.candidate_id = s.candidate_id)
    WHERE 
      c.recgroup_id = '{recgroup_id}'::uuid
    GROUP BY 
      c.candidate_id,
      c.data_source,
      c.feature_id
)


  SELECT
    s.data_source,
    s.score,
    m.locality as name,
    m.stateprovince || ', ' || m.countrycode as located_at,
    null as type,
    decimallongitude as longitude,
    decimallatitude as latitude,
    m.gbifid::text as feature_id,
    s.candidate_id,
    s.no_features
  FROM 
    score s,                                  
    gbif m
  WHERE 
    s.feature_id = m.gbifid AND
    m.species = '{species}' AND
    s.data_source = ANY('{{gbif.species,gbif.genus}}')

  UNION

  SELECT
    s.data_source,
    s.score,
    m.name_1 as name,
    m.name_0 as located_at,
    m.engtype_1 as type,
    round(st_x(m.centroid)::numeric, 5) as longitude,
    round(st_y(m.centroid)::numeric, 5) as latitude,
    m.uid::text as feature_id,
    s.candidate_id,
    s.no_features
  FROM 
    score s,                                  
    gadm1 m
  WHERE 
    s.feature_id::uuid = m.uid AND
    s.data_source = 'gadm1'

  UNION 

  SELECT
    s.data_source,
    s.score,
    m.name_2 as name,
    m.name_1 || ', ' || m.name_0 as located_at,
    m.engtype_2 as type,
    round(st_x(m.centroid)::numeric, 5) as longitude,
    round(st_y(m.centroid)::numeric, 5) as latitude,
    m.uid::text as feature_id,
    s.candidate_id,
    s.no_features
  FROM 
    score s,                                  
    gadm2 m
  WHERE 
    s.feature_id::uuid = m.uid AND
    s.data_source = 'gadm2'

  UNION 

  SELECT
    s.data_source,
    s.score,
    m.name_3 as name,
    m.name_1 || ', ' || m.name_0 as located_at,
    m.engtype_3 as type,
    round(st_x(m.centroid)::numeric, 5) as longitude,
    round(st_y(m.centroid)::numeric, 5) as latitude,
    m.uid::text as feature_id,
    s.candidate_id,
    s.no_features
  FROM 
    score s,                                  
    gadm3 m
  WHERE 
    s.feature_id::uuid = m.uid AND
    s.data_source = 'gadm3'

  UNION 

  SELECT
    s.data_source,
    s.score,
    m.name_4 as name,
    m.name_1 || ', ' || m.name_0 as located_at,
    m.engtype_4 as type,
    round(st_x(m.centroid)::numeric, 5) as longitude,
    round(st_y(m.centroid)::numeric, 5) as latitude,
    m.uid::text as feature_id,
    s.candidate_id,
    s.no_features
  FROM 
    score s,                                  
    gadm4 m
  WHERE 
    s.feature_id::uuid = m.uid AND
    s.data_source = 'gadm4'

  UNION 

  SELECT
    s.data_source,
    s.score,
    m.name_5 as name,
    m.name_1 || ', ' || m.name_0 as located_at,
    m.engtype_5 as type,
    round(st_x(m.centroid)::numeric, 5) as longitude,
    round(st_y(m.centroid)::numeric, 5) as latitude,
    m.uid::text as feature_id,
    s.candidate_id,
    s.no_features
  FROM 
    score s,                                  
    gadm5 m
  WHERE 
    s.feature_id::uuid = m.uid AND
    s.data_source = 'gadm5'

  UNION 

  SELECT
    s.data_source,
    s.score,
    m.name,
    m.gadm2 as located_at,
    m.desig_eng as type,
    round(st_x(m.centroid)::numeric, 5) as longitude,
    round(st_y(m.centroid)::numeric, 5) as latitude,
    m.uid::text as feature_id,
    s.candidate_id,
    s.no_features
  FROM 
    score s,                               
    wdpa_polygons m
  WHERE 
    s.feature_id::uuid = m.uid AND
    s.data_source = 'wdpa_polygons'

  UNION 

  SELECT
    s.data_source,
    s.score,
    m.name,
    m.gadm2 as located_at,
    m.desig_eng as type,
    st_x(m.the_geom)::numeric as longitude,
    st_y(m.the_geom)::numeric as latitude,
    m.uid::text as feature_id,
    s.candidate_id,
    s.no_features
  FROM 
    score s,                               
    wdpa_points m
  WHERE 
    s.feature_id::uuid = m.uid AND
    s.data_source = 'wdpa_points'

  UNION 

  SELECT
    s.data_source,
    s.score,
    m.lake_name as name,
    m.gadm2 as located_at,
    m.type,
    round(st_x(m.centroid)::numeric, 5) as longitude,
    round(st_y(m.centroid)::numeric, 5) as latitude,
    m.uid::text as feature_id,
    s.candidate_id,
    s.no_features
  FROM 
    score s,                               
    global_lakes m
  WHERE 
    s.feature_id::uuid = m.uid AND
    s.data_source = 'global_lakes'

  UNION 

  SELECT
    s.data_source,
    s.score,
    m.full_name_nd_ro as name,
    m.gadm2 as located_at,
    null as type,
    long::numeric as longitude,
    lat::numeric as latitude,
    m.uid::text as feature_id,
    s.candidate_id,
    s.no_features
  FROM 
    score s,                               
    gns m
  WHERE 
    s.feature_id::uuid = m.uid AND
    s.data_source = 'gns'

  UNION

  SELECT
    s.data_source,
    s.score,
    m.feature_name as name,
    m.gadm2 as located_at,
    m.feature_class as type,
    prim_long_dec::numeric as longitude,
    prim_lat_dec::numeric as latitude,
    m.uid::text as feature_id,
    s.candidate_id,
    s.no_features
  FROM 
    score s,                               
    gnis m
  WHERE 
    s.feature_id::uuid = m.uid AND
    s.data_source = 'gnis'

  UNION

  SELECT
    s.data_source,
    s.score,
    m.name,
    m.gadm2 as located_at,
    null as type,
    longitude,
    latitude,
    m.uid::text as feature_id,
    s.candidate_id,
    s.no_features
  FROM 
    score s,                               
    geonames m
  WHERE 
    s.feature_id::uuid = m.uid AND
    s.data_source = 'geonames'
