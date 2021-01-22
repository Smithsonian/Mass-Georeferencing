library(DBI)

source("settings.R")

#Connect to the database ----
if (Sys.info()["nodename"] == "shiny.si.edu"){
  #For RHEL7 odbc driver
  pg_driver = "PostgreSQL"
}else if (Sys.info()["nodename"] == "OCIO-2SJKVD22"){
  #For RHEL7 odbc driver
  pg_driver = "PostgreSQL Unicode(x64)"
}else{
  pg_driver = "PostgreSQL Unicode"
}

db <- dbConnect(odbc::odbc(),
                driver = pg_driver,
                database = pg_db,
                uid = pg_user,
                pwd = pg_pass,
                server = pg_host,
                port = 5432)


getdl_query <- paste0("SELECT * FROM mg_collex_dl WHERE ready = 'f'")
dls <- dbGetQuery(db, getdl_query)

if (dim(dls)[1] > 0){
  
  for (i in seq(1, dim(dls)[1])){
    
    n <- dbSendQuery(db, paste0("UPDATE mg_collex_dl SET ready = 't' WHERE table_id = ", dls$table_id[i]))
    
    filespath <- dls$dl_file_path[i]
    
    getdl_query <- paste0("SELECT data_source, point_or_polygon, count(*) as no_records FROM mg_selected_candidates WHERE collex_id = '", dls$collex_id[i], "' GROUP BY data_source, point_or_polygon")
    datasources <- dbGetQuery(db, getdl_query)
    
    system(paste0("mkdir -p ", filespath))
    
    for (d in seq(1, dim(datasources)[1])){
      
      data_source <- ""
      data_source_filename <- paste0(datasources$data_source[d], "_", datasources$point_or_polygon[d], "_geoms")
      
      system("mkdir -p /tmp/mg")
      system("rm -f /tmp/mg/*")
      
      if (datasources$data_source[d] == "gbif"){
        uid = "null as geom_name"
      }else{
        uid = "d.uid, d.name as geom_name"
      }
      
      if (dls$collex_id[i] == "b93b40d3-dd98-4a8a-83d7-30bebc092af0"){
        query <- paste0("SELECT ", uid, ", d.the_geom as geom, o.occurrence_source, o.occurrenceid, o.continent, o.countrycode, o.stateprovince, o.county, o.locality, o.kingdom,o.phylum,o.family,o.genus,o.specificepithet,o.infraspecificepithet,o.scientificname,o.elevation,o.recordedby FROM mg_occurrences o, ", datasources$data_source[d], " d,     mg_selected_candidates c,     mg_recordgroups r,     mg_records mgr WHERE     o.collex_id = '", dls$collex_id[i], "'::uuid and o.collex_id = c.collex_id    and c.recgroup_id = r.recgroup_id   and r.recgroup_id = mgr.recgroup_id   and o.mg_occurrenceid = mgr.mg_occurrenceid  and d.uid IN   (SELECT feature_id::uuid as uid FROM mg_candidates WHERE candidate_id IN ( SELECT candidate_id AS uid FROM mg_selected_candidates WHERE data_source = '", datasources$data_source[d], "' AND collex_id = '", dls$collex_id[i], "'::uuid))")
      }else if (dls$collex_id[i] == "8733bb2d-aac9-4297-8440-d10e7117caef"){
        query <- paste0("SELECT ", uid, ", d.the_geom as geom, o.occurrence_source, o.occurrenceid, o.waterbody, o.countrycode, o.stateprovince, o.county, o.locality, o.kingdom,o.phylum,o.family,o.genus,o.specificepithet,o.infraspecificepithet,o.scientificname,o.elevation,o.recordedby FROM mg_occurrences o, ", datasources$data_source[d], " d,     mg_selected_candidates c,     mg_recordgroups r,     mg_records mgr WHERE     o.collex_id = '", dls$collex_id[i], "'::uuid and o.collex_id = c.collex_id    and c.recgroup_id = r.recgroup_id   and r.recgroup_id = mgr.recgroup_id   and o.mg_occurrenceid = mgr.mg_occurrenceid  and d.uid IN   (SELECT feature_id::uuid as uid FROM mg_candidates WHERE candidate_id IN ( SELECT candidate_id AS uid FROM mg_selected_candidates WHERE data_source = '", datasources$data_source[d], "' AND collex_id = '", dls$collex_id[i], "'::uuid))")
      }else{
        
        if (datasources$data_source[d] == "gbif"){
          
          q <- paste0("SELECT 
                        'ANY(''{' || string_agg(DISTINCT species, ',') || '}''::text[])'
                    FROM
                        mg_recordgroups g,
                        mg_candidates c,
                        mg_selected_candidates s
                    WHERE 
                        g.collex_id = '", dls$collex_id[i], "'::uuid AND
                        c.recgroup_id = g.recgroup_id AND
                        c.candidate_id = s.candidate_id")
          
          gbif_species <- dbGetQuery(db, q)
          
          # query <- paste0("SELECT ", uid, ", d.the_geom as geom, o.* FROM mg_occurrences o, ", datasources$data_source[d], " d,     mg_selected_candidates c,     mg_recordgroups r, mg_records mgr WHERE o.collex_id = '", dls$collex_id[i], "'::uuid and o.collex_id = c.collex_id    and c.recgroup_id = r.recgroup_id and r.recgroup_id = mgr.recgroup_id and o.mg_occurrenceid = mgr.mg_occurrenceid  and d.species = ", gbif_species, " AND d.gbifid IN   (SELECT feature_id as gbifid FROM mg_candidates WHERE candidate_id IN ( SELECT candidate_id AS uid FROM mg_selected_candidates WHERE data_source = '", datasources$data_source[d], "' AND collex_id = '", dls$collex_id[i], "'::uuid))")
          
          query <- paste0("
                  select 
                      g.decimallongitude as decimallongitude,
                      g.decimallatitude as decimallatitude,
                      g.gbifid,
                      g.the_geom as geom,
                      msc.data_source,
                      msc.notes,
                      msc.uncertainty_m,
                      mo.mg_occurrenceid, 
                      mo.occurrenceid, 
                      mo.gbifid, 
                      mo.datasetid, 
                      mo.datasetname, 
                      mo.basisofrecord, 
                      mo.eventdate, 
                      mo.eventtime, 
                      mo.highergeography, 
                      mo.stateprovince, 
                      mo.county, 
                      mo.locality, 
                      mo.hasgeospatialissues, 
                      mo.species, 
                      mo.acceptedscientificname, 
                      mo.recordedby, 
                      mo.countrycode
                  from 
                      mg_selected_candidates msc,
                      mg_candidates mc,
                      gbif g,
                      mg_records mr,
                      mg_occurrences mo
                  WHERE 
                      msc.candidate_id = mc.candidate_id AND
                      msc.collex_id = \'", dls$collex_id[i], "\'::uuid AND
                      msc.recgroup_id = mr.recgroup_id AND
                      msc.data_source = \'gbif\' AND
                      g.species = ANY{\'", gbif_species, "\'} AND
                      mc.feature_id = g.gbifid AND
                      mr.mg_occurrenceid = mo.mg_occurrenceid")
          
        }else if (datasources$data_source[d] == "custom"){
          
          query <- paste0("select cus.custom_decimallatitude as decimallongitude, cus.custom_decimallongitude as decimallatitude, cus.custom_name as name, st_setsrid(st_point(cus.custom_decimallongitude::numeric, cus.custom_decimallatitude::numeric), 4326) as geom, msc.data_source, msc.notes, msc.uncertainty_m, mo.mg_occurrenceid, mo.occurrenceid, mo.gbifid, mo.datasetid, mo.datasetname, mo.basisofrecord, mo.eventdate, mo.eventtime, mo.highergeography, mo.stateprovince, mo.county, mo.locality, mo.hasgeospatialissues, mo.species, mo.acceptedscientificname, mo.recordedby, mo.countrycode from mg_selected_candidates msc, mg_custom mc, mg_records mr, mg_occurrences mo, mg_custom cus WHERE msc.candidate_id = mc.candidate_id AND msc.collex_id = \'", dls$collex_id[i], "\'::uuid AND msc.recgroup_id = mr.recgroup_id AND msc.data_source = 'custom' AND mr.mg_occurrenceid = mo.mg_occurrenceid")
          
          
        }else{
          query <- paste0("SELECT ", uid, ", c.notes, c.uncertainty_m, st_setsrid(st_point(d.decimallongitude, d.decimallatitude), 4326) as geom, o.* FROM mg_occurrences o, ", datasources$data_source[d], " d,     mg_selected_candidates c,     mg_recordgroups r, mg_records mgr WHERE o.collex_id = \'", dls$collex_id[i], "\'::uuid and o.collex_id = c.collex_id    and c.recgroup_id = r.recgroup_id and r.recgroup_id = mgr.recgroup_id and o.mg_occurrenceid = mgr.mg_occurrenceid  and d.uid IN   (SELECT feature_id::uuid as uid FROM mg_candidates WHERE candidate_id IN ( SELECT candidate_id AS uid FROM mg_selected_candidates WHERE data_source = \'", datasources$data_source[d], "\' AND collex_id = \'", dls$collex_id[i], "\'::uuid))")
        }
        
      }
      
      
      data <- dbGetQuery(db, query)
      
       system(paste0("pgsql2shp -u ", pg_user, " -h ", pg_host, " -P ", pg_pass, " -g geom -f /tmp/mg/", data_source_filename, ".shp gis \"", gsub("[\r\n]", "", query), "\""))
      
      system(paste0("zip -j ", filespath, "/", data_source_filename, ".zip /tmp/mg/", data_source_filename, ".*"))
      system("rm -r /tmp/mg")
      
    }
    
    system(paste0("mv ", filespath, " ", server_path))
    
  }
  
  system(paste0("chmod -R 777 ", server_path))
  
}
