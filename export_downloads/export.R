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
    
    dbSendQuery(db, paste0("UPDATE mg_collex_dl SET ready = 't' WHERE table_id = ", dls$table_id[i]))
    
    filespath <- dls$dl_file_path[i]
    
    getdl_query <- paste0("SELECT data_source, point_or_polygon, count(*) as no_records FROM mg_selected_candidates WHERE collex_id = '", dls$collex_id[i], "' GROUP BY data_source, point_or_polygon")
    datasources <- dbGetQuery(db, getdl_query)
    
    system(paste0("mkdir -p ", filespath))
    
    for (d in seq(1, dim(datasources)[1])){
      
      data_source <- ""
      data_source_filename <- paste0(datasources$data_source[d], "_", datasources$point_or_polygon[d], "_geoms")
      
      system("mkdir -p /tmp/mg")
      system("rm -f /tmp/mg/*")
      
      if (dls$collex_id[i] == "b93b40d3-dd98-4a8a-83d7-30bebc092af0"){
        query <- paste0("SELECT d.uid geom_id, d.name as geom_name, d.the_geom as geom, o.occurrence_source, o.occurrenceid, o.continent, o.countrycode, o.stateprovince, o.county, o.locality, o.kingdom,o.phylum,o.family,o.genus,o.specificepithet,o.infraspecificepithet,o.scientificname,o.elevation,o.recordedby FROM mg_occurrences o, ", datasources$data_source, " d,     mg_selected_candidates c,     mg_recordgroups r,     mg_records mgr WHERE     o.collex_id = '", dls$collex_id[i], "'::uuid and o.collex_id = c.collex_id    and c.recgroup_id = r.recgroup_id   and r.recgroup_id = mgr.recgroup_id   and o.mg_occurrenceid = mgr.mg_occurrenceid  and d.uid IN   (SELECT feature_id::uuid as uid FROM mg_candidates WHERE candidate_id IN ( SELECT candidate_id AS uid FROM mg_selected_candidates WHERE data_source = '", datasources$data_source, "' AND collex_id = '", dls$collex_id[i], "'::uuid))")
      }else if (dls$collex_id[i] == "8733bb2d-aac9-4297-8440-d10e7117caef"){
        query <- paste0("SELECT d.uid geom_id, d.name as geom_name, d.the_geom as geom, o.occurrence_source, o.occurrenceid, o.waterbody, o.countrycode, o.stateprovince, o.county, o.locality, o.kingdom,o.phylum,o.family,o.genus,o.specificepithet,o.infraspecificepithet,o.scientificname,o.elevation,o.recordedby FROM mg_occurrences o, ", datasources$data_source, " d,     mg_selected_candidates c,     mg_recordgroups r,     mg_records mgr WHERE     o.collex_id = '", dls$collex_id[i], "'::uuid and o.collex_id = c.collex_id    and c.recgroup_id = r.recgroup_id   and r.recgroup_id = mgr.recgroup_id   and o.mg_occurrenceid = mgr.mg_occurrenceid  and d.uid IN   (SELECT feature_id::uuid as uid FROM mg_candidates WHERE candidate_id IN ( SELECT candidate_id AS uid FROM mg_selected_candidates WHERE data_source = '", datasources$data_source, "' AND collex_id = '", dls$collex_id[i], "'::uuid))")
      }else{
        query <- paste0("SELECT d.uid geom_id, d.name as geom_name, d.the_geom as geom, o.* FROM mg_occurrences o, ", datasources$data_source, " d,     mg_selected_candidates c,     mg_recordgroups r,     mg_records mgr WHERE     o.collex_id = '", dls$collex_id[i], "'::uuid and o.collex_id = c.collex_id    and c.recgroup_id = r.recgroup_id   and r.recgroup_id = mgr.recgroup_id   and o.mg_occurrenceid = mgr.mg_occurrenceid  and d.uid IN   (SELECT feature_id::uuid as uid FROM mg_candidates WHERE candidate_id IN ( SELECT candidate_id AS uid FROM mg_selected_candidates WHERE data_source = '", datasources$data_source, "' AND collex_id = '", dls$collex_id[i], "'::uuid))")
      }
      
      
      #data <- dbGetQuery(db, query)
      
      system(paste0("pgsql2shp -u ", pg_user, " -h ", pg_host, " -P ", pg_pass, " -g geom -f /tmp/mg/", data_source_filename, ".shp gis \"", query, "\""))
      
      system(paste0("zip -j ", filespath, "/", data_source_filename, ".zip /tmp/mg/", data_source_filename, ".*"))
      system("rm -r /tmp/mg")
      
    }
    
    system(paste0("mv ", filespath, " /var/www/api/dl/"))
    
  }
  
  system("chmod -R 777 /var/www/api/dl/")
  
}
