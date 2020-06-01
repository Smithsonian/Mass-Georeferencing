library(shiny)
library(leaflet)
library(leaflet.extras)
library(jsonlite)
#library(futile.logger)
library(countrycode)
#library(parallel)
library(shinyWidgets)
library(rgdal)
library(shinycssloaders)
library(dplyr)
library(sp)
library(DT)
library(rgbif)
#library(DBI)
#library(httr)


#Settings----
app_name <- "Mass Georeferencing Tool"
app_ver <- "0.1.0"
github_link <- "https://github.com/Smithsonian/Mass-Georeferencing"
options(stringsAsFactors = FALSE)
options(encoding = 'UTF-8')
#Logfile
logfile <- paste0("logs/", format(Sys.time(), "%Y%m%d_%H%M%S"), ".txt")


#Settings
source("settings.R")
source("leafletmap.R")



#Connect to the database ----
# if (Sys.info()["nodename"] == "shiny.si.edu"){
#   #For RHEL7 odbc driver
#   pg_driver = "PostgreSQL"
# }else if (Sys.info()["nodename"] == "OCIO-2SJKVD22"){
#   #For RHEL7 odbc driver
#   pg_driver = "PostgreSQL Unicode(x64)"
# }else{
#   pg_driver = "PostgreSQL Unicode"
# }

# db <- dbConnect(odbc::odbc(),
#                 driver = pg_driver,
#                 database = pg_db,
#                 uid = pg_user,
#                 pwd = pg_pass,
#                 server = pg_host,
#                 port = 5432)



#UI----
ui <- fluidPage(
          #title = app_name,
          fluidRow(
            column(width = 4,
                   #h2("Mass Georeferencing Tool", id = "title_main"),
                   #h2(div(a(img(src="mass_geo_icon.png", height = "30px"), app_name, href="./")), id = "title_main"),
                   uiOutput("title"),
                   uiOutput("main"),
                   uiOutput("maingroup"),
                   uiOutput("species"),
                   uiOutput("records_h"),
                   div(DT::dataTableOutput("records"), style = "font-size:80%"),
                   div(uiOutput("record_selected"), style = "font-size:90%"),
                   uiOutput("candidatematches_h")
            ),
            column(width = 8,
                   uiOutput("map_header"),
                   shinycssloaders::withSpinner(leafletOutput("map", width = "100%", height = "520px")),
                   fluidRow(
                     column(width = 4,
                            div(uiOutput("candidate_matches_info_h"), style = "font-size:80%")
                     ),
                     column(width = 4,
                            uiOutput("candidatescores_box"),
                            div(uiOutput("marker_info"), style = "font-size:80%")
                     ),
                     column(width = 4,
                            uiOutput("actions_box")
                     )
                   )
            )
          ),
               
         #footer ----
         uiOutput("footer")
         
)


#Server----
server <- function(input, output, session) {
  
  source("functions.R")
  
  #title
  output$title <- renderUI({
    query <- parseQueryString(session$clientData$url_search)
    collex_id <- query['collex_id']
    
    if (collex_id == "NULL"){
      h2(div(a(img(src="mass_geo_icon.png", height = "30px"), app_name, href="./")), id = "title_main")
    }else{
      h2(div(a(img(src="mass_geo_icon.png", height = "30px"), app_name, href=paste0("./?collex_id=", collex_id))), id = "title_main")
    }
  })
  
  #main----
  output$main <- renderUI({
    query <- parseQueryString(session$clientData$url_search)
    collex_id <- query['collex_id']
    
    if (collex_id == "NULL"){
      shinyWidgets::panel(
        p("To use this app, select a collection to see the list of species available for georeferencing."),
        p("This is a test system and does not contain all the species in each collection"),
        p("This app was made by the Digitization Program Office, OCIO."),
        heading = "Welcome",
        status = "primary"
      )
    }
  })
  
  
  #maingroup ----
  output$maingroup <- renderUI({
    query <- parseQueryString(session$clientData$url_search)
    collex_id <- query['collex_id']
    species <- query['species']
    
    if (collex_id != "NULL"){
      
      session$userData$collex_id <- collex_id
      
      api_req <- httr::POST(URLencode(paste0(api_url, "mg/collex_info")),
                            body = list(collex_id = collex_id),
                            httr::add_headers(
                              "X-Api-Key" = app_api_key
                            ),
                            encode = "form"
      )
      api_req
      
      collex <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
      
      if (species == "NULL"){
        HTML(paste0("<h4>", collex$collex_name, "</h4>"))
      }else{
        HTML(paste0("<p><a href = \"./?collex_id=", collex$collex_id, "\"><span class=\"glyphicon glyphicon-home\" aria-hidden=\"true\"></span> Home</a></p>"))
      }
  
    }else{
      collex_menu <- "<p>Select group (rank in parenthesis is how the group is selected):
                  <ul>"
      
      api_req <- httr::POST(URLencode(paste0(api_url, "mg/all_collex")),
                            httr::add_headers(
                              "X-Api-Key" = app_api_key
                            ),
                            encode = "form"
      )
      
      collections <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
      
      for (i in seq(1, dim(collections)[1])){
          collex_menu <- paste0(collex_menu, "<li><a href=\"./?collex_id=", collections$collex_id[i], "\">", collections$collex_name[i], "</a></li>")
      }
            
      collex_menu <- paste0(collex_menu, "</ul></ul></p>")
      
      HTML(collex_menu)
    }
  })
  
  
  
  # species ----
  output$species <- renderUI({
    query <- parseQueryString(session$clientData$url_search)
    collex_id <- query['collex_id']
    species <- query['species']

    if (collex_id == "NULL"){req(FALSE)}
    if (species != "NULL"){req(FALSE)}
    
    api_req <- httr::POST(URLencode(paste0(api_url, "mg/collex_species")),
                          body = list(collex_id = collex_id),
                          httr::add_headers(
                            "X-Api-Key" = app_api_key
                          ),
                          encode = "form"
    )
    api_req
    
    species <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
    
    if (length(species) > 1){
      names(species) <- species
    }
    
    tagList(
      selectInput("species", "Select a species:", species),
      actionButton("submit_species", "Submit")
    )
  })
  
  
  
  # submit_species react ----
  observeEvent(input$submit_species, {
  
    req(input$species)
    query <- parseQueryString(session$clientData$url_search)
    collex_id <- query['collex_id']
    
    output$main <- renderUI({
      HTML(paste0("<script>$(location).attr('href', './?collex_id=", collex_id, "&species=", input$species, "')</script>"))
    })
  })
    
  
  #Species selected----
  #species records header----
  output$records_h <- renderUI({
    
    query <- parseQueryString(session$clientData$url_search)
    species <- query['species']
    recgrp_id <- query['recgrp_id']
    collex_id <- query['collex_id']
    
    session$userData$species <- species
    session$userData$recgrp_id <- recgrp_id
    session$userData$collex_id <- collex_id
    
    if (recgrp_id != "NULL"){
      req(FALSE)
    }
    
    req(species != "NULL")
    
    HTML(paste0("<h3>Species: <em>", species, "</em></h3>"))
  })
  
  
  #species records----
  output$records <- DT::renderDataTable({
    species <- session$userData$species
    collex_id <- session$userData$collex_id
    recgrp_id <- session$userData$recgrp_id
    
    req(species != "NULL")
    
    if (recgrp_id != "NULL"){
      req(FALSE)
    }
    
    api_req <- httr::POST(URLencode(paste0(api_url, "mg/species_recgroups")),
                          body = list(species = species, 
                                      collex_id = collex_id),
                          httr::add_headers(
                            "X-Api-Key" = app_api_key
                          ),
                          encode = "form"
    )
    api_req
    
    records <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
    
    records <- arrange(records, desc(no_records))
    
    session$userData$speciesrecords <- records
    
    records <- records[c("locality", "countrycode", "no_records")]
    
    names(records) <- c("Locality", "Country", "No. records") 
    
    DT::datatable(records, 
                escape = FALSE,
                options = list(searching = FALSE,
                               ordering = TRUE,
                               pageLength = 5,
                               paging = TRUE,
                               language = list(zeroRecords = "No matches found")
                ),
                rownames = FALSE,
                selection = 'single',
                caption = "Records grouped by locality. Select a record to show candidate matches")
  })

  
  # records_rows_selected react ----
  observeEvent(input$records_rows_selected, {
    query <- parseQueryString(session$clientData$url_search)
    collex_id <- query['collex_id']
    species <- query['species']
    
    speciesrecords <- session$userData$speciesrecords
    this_row <- speciesrecords[input$records_rows_selected,]
    
    output$main <- renderUI({
      HTML(paste0("<script>$(location).attr('href', './?collex_id=", collex_id, "&species=", species, "&recgrp_id=", this_row$recgroup_id, "')</script>"))
    })
  })
  
  
  #record_selected----
  output$record_selected <- renderUI({
    
    query <- parseQueryString(session$clientData$url_search)
    species <- query['species']
    recgrp_id <- query['recgrp_id']
    collex_id <- query['collex_id']
    
    if (recgrp_id == "NULL"){
      req(FALSE)
    }
    
    api_req <- httr::POST(URLencode(paste0(api_url, "mg/species_recgroups")),
                          body = list(species = species,
                                      collex_id = collex_id),
                          httr::add_headers(
                            "X-Api-Key" = app_api_key
                          ),
                          encode = "form"
    )
    
    records <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)

    session$userData$records <- records
    session$userData$recgrp_id <- recgrp_id
    session$userData$species <- species
    session$userData$collex_id <- collex_id
    
    this_row <- records[records$recgroup_id == recgrp_id,]
    
    #print(this_row)
    
    if (this_row$stateprovince == ""){
      located_at <- countrycode::countrycode(this_row$countrycode, origin = "iso2c", destination = "country.name")
    }else{
      located_at <- paste0(this_row$stateprovince, ", ", countrycode::countrycode(this_row$countrycode, origin = "iso2c", destination = "country.name"))
    }
    
    tagList(
      HTML("<br><div class=\"panel panel-primary\">
        <div class=\"panel-heading\">
        <h3 class=\"panel-title\">Record Group Selected</h3>
        </div>
        <div class=\"panel-body\">"),
      fluidRow(
        column(width = 6,
               HTML(paste0("<a href=\"./?collex_id=", collex_id, "&species=", species, "\">")),
               icon("arrow-left", lib = "glyphicon"), 
               HTML("Go back</a>")
        ),
        column(width = 6,
               actionLink("showgroup", label = HTML(paste0(icon("th-list", lib = "glyphicon"), " Show records in this group")))
        )
      ),
      
      hr(),
      
      fluidRow(
        column(width = 6,
               HTML(paste0("<dl>
                      <dt>Locality</dt><dd>", this_row$locality, "</dd>
                      <dt>Located at</dt><dd>", located_at, "</dd>
                      <dt>No. records</dt><dd>", this_row$no_records, "</dd>
                    </dl>"))
        ),
        column(width = 6,
               HTML(paste0("<dl>
                      <dt>Species</dt><dd><em>", this_row$species, "</em></dd>
                      <dt>Family</dt><dd>", this_row$family, "</dd>
                    </dl>"))
        )
      ),
      
      HTML("</div></div>")
    )
    
  })
  
  
  
  #Group of records----
  output$grouped_records <- DT::renderDataTable({
    
    records <- session$userData$records
    recgrp_id <- session$userData$recgrp_id
    species <- session$userData$species
    collex_id <- session$userData$collex_id
    
    req(records)
    req(recgrp_id)
    req(species)
    req(collex_id)
    
    this_row <- records[records$recgroup_id == recgrp_id,]
    
    #print(this_row)
    
    api_req <- httr::POST(URLencode(paste0(api_url, "mg/recgroups_records")),
                          body = list(recgroup_id = this_row$recgroup_id),
                          httr::add_headers(
                            "X-Api-Key" = app_api_key
                          ),
                          encode = "form"
    )
    
    #print(api_req)
    
    group_records <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
    group_records <- select(as.data.frame(group_records), -mg_occurrenceid)
    group_records$occurrenceid <- paste0("<a href='",group_records$occurrenceid,"' target='_blank'>",group_records$occurrenceid,"</a>")
    
    DT::datatable(group_records,
                  escape = FALSE,
                  options = list(searching = FALSE,
                                 ordering = TRUE,
                                 pageLength = 15,
                                 paging = TRUE,
                                 scrollx = "680px"
                  ),
                  rownames = FALSE,
                  selection = list(mode = 'none'))
  })
  

  observeEvent(input$showgroup, {
    showModal(modalDialog(
      size = "l",
      title = "Grouped records",
      div(DT::dataTableOutput("grouped_records"), style = "font-size:80%"),
      easyClose = TRUE
    ))
  })
  


  #Candidate Matches----
  output$candidatematches_h <- renderUI({
    query <- parseQueryString(session$clientData$url_search)
    species <- query['species']
    recgrp_id <- query['recgrp_id']
    collex <- query['collex']
    candidate_id <- query['candidate_id']
    
    session$userData$species <- species
    session$userData$collex <- collex
    session$userData$recgrp_id <- recgrp_id
    session$userData$candidate_id <- candidate_id
    
    if (recgrp_id == "NULL"){
      req(FALSE)
    }
    
    tagList(
      HTML("<br><div class=\"panel panel-info\">
        <div class=\"panel-heading\">
        <h3 class=\"panel-title\">Candidate Localities</h3>
        </div>
        <div class=\"panel-body\">"),
      div(DT::dataTableOutput("candidatematches"), style = "font-size:80%"),
      HTML("</div></div>")
    )
  })
  
  
  output$candidatematches <- DT::renderDataTable({
    
    species <- session$userData$species
    collex <- session$userData$collex
    recgrp_id <- session$userData$recgrp_id
    candidate_id <- session$userData$candidate_id
    
    if (recgrp_id == "NULL"){
      req(FALSE)
    }else{
      req(species != "NULL")

      api_req <- httr::POST(URLencode(paste0(api_url, "mg/candidates")),
                            body = list(recgroup_id = recgrp_id,
                                          species = species),
                            httr::add_headers(
                              "X-Api-Key" = app_api_key
                            ),
                            encode = "form"
      )
      
      #print(api_req$request)
      candidates <- as.data.frame(fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE))
      
      candidates$longitude <- as.numeric(candidates$longitude)
      candidates$latitude <- as.numeric(candidates$latitude)
      
      #session$userData$candidates <- candidates
      
      if (api_req$status != 200){
         results_table <- candidates
      }else{
         results <- candidates %>%
            dplyr::arrange(match(data_source, c("gbif.species", "gbif.genus", "wdpa_polygons", "wdpa_points", "global_lakes", "geonames", "gadm5", "gadm4", "gadm3", "gadm2", "gadm1", "gadm0"))) %>% 
            dplyr::arrange(dplyr::desc(score))
        
         session$userData$candidates <- results
         
         gadm_layers <- c("gadm", "gadm0", "gadm1", "gadm2", "gadm3", "gadm4", "gadm5")
         gbif_layers <- c("gbif.species", "gbif.genus", "gbif.family")
         wdpa_layers <- c("wdpa_polygons", "wdpa_points", "wdpa")
       
         for (i in seq(1, dim(results)[1])){
           if (results$data_source[i] %in% gadm_layers){
             results$name[i] <- paste0(results$name[i], "<span class=\"glyphicon glyphicon-flag pull-right\" aria-hidden=\"true\" title = \"Political locality from GADM\"></span>")
           }else if (results$data_source[i] == "gbif.species"){
             results$name[i] <- paste0(results$name[i], "<img src=\"gbif_logo.png\" title = \"Locality from a GBIF record for the species\" alt = \"Locality from a GBIF record for the species\" height = \"16px\" class=\"pull-right\">")
           }else if (results$data_source[i] == "gbif.genus"){
             results$name[i] <- paste0(results$name[i], "<span class=\"glyphicon glyphicon-map-marker pull-right\" aria-hidden=\"true\" title = \"Locality from a GBIF record for the genus\"></span>")
           }else if (results$data_source[i] == "gbif.family"){
             results$name[i] <- paste0(results$name[i], "<span class=\"glyphicon glyphicon-map-marker pull-right\" aria-hidden=\"true\" title = \"Locality from a GBIF record for the family\"></span>")
           }else if (results$data_source[i] %in% wdpa_layers){
             results$name[i] <- paste0(results$name[i], "<span class=\"glyphicon glyphicon-leaf pull-right\" aria-hidden=\"true\" title = \"Protected Area\"></span>")
           }else if (results$data_source[i] == "geonames"){
             results$name[i] <- paste0(results$name[i], "<span class=\"glyphicon glyphicon-pushpin pull-right\" aria-hidden=\"true\" title = \"Locality from Geonames\"></span>")
           }else if (results$data_source[i] == "global_lakes"){
             results$name[i] <- paste0(results$name[i], "<span class=\"glyphicon glyphicon-tint pull-right\" aria-hidden=\"true\" title = \"Locality from Global Lakes\"></span>")
           }else if (results$data_source[i] == "gnis"){
             results$name[i] <- paste0(results$name[i], "<span class=\"glyphicon glyphicon-pushpin pull-right\" aria-hidden=\"true\" title = \"Locality from GNIS\"></span>")
           }else if (results$data_source[i] == "gns"){
             results$name[i] <- paste0(results$name[i], "<span class=\"glyphicon glyphicon-pushpin pull-right\" aria-hidden=\"true\" title = \"Locality from GNS\"></span>")
           }
         }
           
         #Reorder cols
         results_table <- results[c("name", "located_at", "score")]
         Encoding(results_table$name) <- "ASCII"
         Encoding(results_table$located_at) <- "ASCII"
         names(results_table) <- c("Locality", "Located at", "Mean Score")
       
      }
       
      #Display map of candidates----
      output$map <- renderLeaflet({
        spp_map <- session$userData$spp_map
        spp_map_data <- session$userData$spp_map_data

        leaflet_map(species_data = spp_map_data, markers = TRUE, markers_data = candidates)
      })
      
      output$map_header <- renderUI({
        tagList(
          h4("Map of the species distribution and candidate matches:"),
          HTML("<em>Click on the map to create a new locality - turn off buffers to create a point in that area</em>")
        )
      })
      
      if (dim(results_table)[1]==1){
         DT::datatable(results_table,
                       escape = FALSE,
                       options = list(searching = FALSE,
                                      ordering = TRUE,
                                      pageLength = 8,
                                      paging = FALSE,
                                      bLengthChange = FALSE#,
                                      #scrollY = "440px"
                       ),
                       rownames = FALSE,
                       selection = list(mode = 'single', selected = c(1)),
                       caption = "Select a locality to show on the map")
       }else{
         if (candidate_id == "NULL"){
           DT::datatable(results_table,
                         escape = FALSE,
                         options = list(searching = FALSE,
                                        ordering = TRUE,
                                        pageLength = 8,
                                        paging = TRUE,
                                        bLengthChange = FALSE#,
                                        #scrollY = "440px"
                         ),
                         rownames = FALSE,
                         selection = list(mode = 'single'),
                         caption = "Select a locality to show on the map") %>% 
             formatStyle(c('Mean Score'),
                         background = styleColorBar(range(50, 100), 'lightblue'),
                         backgroundSize = '98% 88%',
                         backgroundRepeat = 'no-repeat',
                         backgroundPosition = 'center')
         }else{
           which_row <- which(results$candidate_id == candidate_id)

           DT::datatable(results_table,
                         escape = FALSE,
                         options = list(searching = FALSE,
                                        ordering = TRUE,
                                        pageLength = 8,
                                        paging = TRUE,
                                        bLengthChange = FALSE#,
                                        #scrollY = "440px"
                         ),
                         rownames = FALSE,
                         selection = list(mode = 'single', selected = c(which_row)),
                         caption = "Select a locality to show on the map") %>% 
             formatStyle(c('Mean Score'),
                         background = styleColorBar(range(50, 100), 'lightblue'),
                         backgroundSize = '98% 88%',
                         backgroundRepeat = 'no-repeat',
                         backgroundPosition = 'center')
         }
       }
     }
  }, server = FALSE)

  
  
  # candidatematches_rows_selected react ----
  observeEvent(input$candidatematches_rows_selected, {
    
    query <- parseQueryString(session$clientData$url_search)
    species <- query['species']
    recgrp_id <- query['recgrp_id']
    collex_id <- query['collex_id']
    candidate_id <- query['candidate_id']
    
    if (candidate_id != "NULL" && input$candidatematches_rows_selected == "NULL"){
      #Unselected row
      output$main <- renderUI({
        HTML(paste0("<script>$(location).attr('href', './?collex_id=", collex_id, "&species=", species, "&recgrp_id=", recgrp_id, "')</script>"))
      })
    }
    
    candidates <- session$userData$candidates
    candidate_selected <- candidates[input$candidatematches_rows_selected,]
    
    if (candidate_id == candidate_selected$candidate_id){
      req(FALSE)
    }
    
    output$main <- renderUI({
      HTML(paste0("<script>$(location).attr('href', './?collex_id=", collex_id, "&species=", species, "&recgrp_id=", recgrp_id, "&candidate_id=", candidate_selected$candidate_id, "')</script>"))
    })
    
  })
  
  
  #Candidate Scores Box----
  output$candidatescores_box <- renderUI({
    query <- parseQueryString(session$clientData$url_search)
    species <- query['species']
    recgrp_id <- query['recgrp_id']
    collex_id <- query['collex_id']
    candidate_id <- query['candidate_id']

    if (candidate_id == "NULL"){
      req(FALSE)
    }
    
    tagList(
      HTML("<br><div class=\"panel panel-success\">
        <div class=\"panel-heading\">
        <h3 class=\"panel-title\">Scores for this Candidate Locality</h3>
        </div>
        <div class=\"panel-body\">"),
      div(DT::dataTableOutput("candidatescores"), style = "font-size:80%"),
      HTML("</div></div>")
    )
  })
  
  
  #candidatescores----
  output$candidatescores <- DT::renderDataTable({
    query <- parseQueryString(session$clientData$url_search)
    species <- query['species']
    recgrp_id <- query['recgrp_id']
    collex_id <- query['collex_id']
    candidate_id <- query['candidate_id']
    
    if (candidate_id == "NULL"){
      req(FALSE)
    }
    
    candidates <- session$userData$candidates
    
    which_row <- which(candidates$candidate_id == candidate_id)
    which_page <- floor(which_row/8) + 1
    
    dataTableProxy("candidatematches") %>% 
      selectPage(c(which_page))
    
    candidate_selected <- candidates[candidates$candidate_id == candidate_id,]
    #print(candidate_selected)
    other_candidates <- candidates[candidates$candidate_id != candidate_id,]
    
    other_candidates$link <- paste0(other_candidates$name, "<br>Located at: ", other_candidates$located_at, "<br>Source: ", other_candidates$data_source, "<br>Uncertainty (m): ", prettyNum(other_candidates$uncertainty_m, big.mark = ",", scientific = FALSE), "<br>Score: ", other_candidates$score, "<br><small><a href=\"./?collex_id=", collex_id, "&species=", species, "&recgrp_id=", recgrp_id, "&candidate_id=", other_candidates$candidate_id, "\">Select this locality</a></small>")
    
    #Display map of selected candidate----
    output$map <- renderLeaflet({
      spp_map <- session$userData$spp_map
      spp_map_data <- session$userData$spp_map_data
      print(spp_map_data)
      leaflet_map(species_data = spp_map_data, candidate = TRUE, candidate_data = candidate_selected, markers = TRUE, markers_data = other_candidates)
    })
    
    api_req <- httr::POST(URLencode(paste0(api_url, "mg/candidate_scores")),
                          body = list(candidate_id = candidate_selected$candidate_id),
                          httr::add_headers(
                            "X-Api-Key" = app_api_key
                          ),
                          encode = "form"
    )
    #print(api_req)
    candidate_scores <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
    #print(candidate_scores)
    
    candidate_scores <- data.frame(cbind(paste0("<abbr title=\"", candidate_scores$score_info, "\">", candidate_scores$score_type, "</abbr>"), candidate_scores$score))
    
    names(candidate_scores) <- c("Match Type", "Score")
    
    DT::datatable(candidate_scores,
                  escape = FALSE,
                  options = list(searching = FALSE,
                                 ordering = TRUE,
                                 pageLength = 10,
                                 paging = FALSE
                  ),
                  rownames = FALSE,
                  selection = list(mode = 'none')) %>% 
                  formatStyle(c('Score'),
                  background = styleColorBar(range(50, 100), 'lightblue'),
                  backgroundSize = '98% 88%',
                  backgroundRepeat = 'no-repeat',
                  backgroundPosition = 'center')
  })
  
  
  
  
  # map_header ----
  output$map_header <- renderUI({
    query <- parseQueryString(session$clientData$url_search)
    species <- query['species']
    recgrp_id <- query['recgrp_id']
    collex_id <- query['collex_id']

    session$userData$species <- species
    session$userData$collex_id <- collex_id
    session$userData$recgrp_id <- recgrp_id
    
    if (collex_id == "NULL"){
      session$userData$spp_map <- FALSE
      session$userData$spp_map_data <- NULL
      req(FALSE)
      }
    if (species == "NULL"){
      session$userData$spp_map <- FALSE
      session$userData$spp_map_data <- NULL
      req(FALSE)
      }

    api_req <- httr::POST(URLencode(paste0(api_url, "api/species_range")),
                          body = list(scientificname = species, type = "any"),
                          httr::add_headers(
                            "X-Api-Key" = app_api_key
                          ),
                          encode = "form"
    )
    
    if (api_req$status == 200){
      spp_map <- TRUE
      session$userData$spp_map <- spp_map
      convex_geom <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
      session$userData$spp_map_data <- convex_geom
    }else{
      spp_map <- FALSE
      session$userData$spp_map <- spp_map
      session$userData$spp_map_data <- NULL
    }
    
    
    if (is.null(input$candidatematches_rows_selected)){
      cand_sel <- FALSE
      candidates_data <- NULL
    }else{
      cand_sel <- TRUE
      candidates_data <- NULL
    }
    
    
    if (spp_map){
      if (is.null(input$records_rows_selected)){
        h4("Map of the species distribution:")
      }else{
        h4("Map of the species distribution and candidate matches:")
      }
    }else{
      h4("No map is available for the species")
    }
  })
  
  
  
  #map----
  output$map <- renderLeaflet({
    
    spp_map <- session$userData$spp_map
    spp_map_data <- session$userData$spp_map_data
    
    #If no species is set, stop
    if (spp_map == TRUE){
      convex_geom <- spp_map_data
      leaflet_map(species_data = spp_map_data)
    }else{
      req(FALSE)
    }
  })

  
  
  #candidate_matches_info_h----
  output$candidate_matches_info_h <- renderUI({
    req(input$candidatematches_rows_selected)
    
    query <- parseQueryString(session$clientData$url_search)
    species <- query['species']
    recgrp_id <- query['recgrp_id']
    collex_id <- query['collex_id']
    candidate_id <- query['candidate_id']
    
    if (candidate_id == "NULL"){
      req(FALSE)
    }
    
    candidates <- session$userData$candidates
    
    candidate_selected <- candidates[candidates$candidate_id == candidate_id,]
    other_candidates <- candidates[candidates$candidate_id != candidate_id,]
    
    #Get ID and layer of candidate
    api_req <- httr::POST(URLencode(paste0(api_url, "mg/candidate_info")),
                          body = list(candidate_id = candidate_selected$candidate_id),
                          httr::add_headers(
                            "X-Api-Key" = app_api_key
                          ),
                          encode = "form"
    )
    
    if (api_req$status_code != 200){
      req(FALSE)
    }
    
    candidate_info <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
    
    #Geom and details of candidate
    if (candidate_info$data_source == "gbif.species" || candidate_info$data_source == "gbif.genus"){
      data_source = "gbif"
      api_req <- httr::POST(URLencode(paste0(api_url, "/mg/get_gbif_record")),
                            body = list(uid = candidate_info$feature_id,
                                        species = species),
                            httr::add_headers(
                              "X-Api-Key" = app_api_key
                            ),
                            encode = "form"
      )
      
      the_feature <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
      
      uncert <- the_feature$coordinateuncertaintyinmeters
      
      if (is.na(uncert)){
        uncert <- "NA"
      }else{
        uncert <- paste0(uncert, " m (yellow buffer in map)")
      }
    }else{
      data_source = candidate_info$data_source
      api_req <- httr::POST(URLencode(paste0(api_url, "api/geom")),
                            body = list(uid = candidate_info$feature_id,
                                        layer = data_source),
                            httr::add_headers(
                              "X-Api-Key" = app_api_key
                            ),
                            encode = "form"
      )
      
      the_feature <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
      
      session$userData$the_feature <- the_feature
      
      uncert <- the_feature$min_bound_radius_m
      if (is.null(uncert)){
        uncert <- "NA"
      }else{
          uncert <- paste0(uncert, " m (yellow buffer in map)")
      }
    }
    
    if (api_req$status_code == 200){
      
      html_to_print <- paste0("<br><div class=\"panel panel-success\">
          <div class=\"panel-heading\">
          <h3 class=\"panel-title\">Candidate Locality Selected</h3>
          </div>
          <div class=\"panel-body\">
              <dl class=\"dl-horizontal\">
                  <dt>Name</dt><dd>", the_feature$name, "</dd>
                  <dt>Located at</dt><dd>", the_feature$located_at, "</dd>
                  <dt>Locality uncertainty (m)</dt><dd>", uncert, "</dd>")
      
      
      if (data_source == "gbif"){
        the_feature <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)

        html_to_print <- paste0(html_to_print, "<dt>Source</dt><dd><a href=\"https://www.gbif.org/occurrence/", the_feature$gbifid, "\" target=_blank title=\"Open record in GBIF\">GBIF record (", the_feature$gbifid, ")</a></dd>
                    <dt>Dataset</dt><dd><a href=\"https://www.gbif.org/dataset/", the_feature$datasetkey, "\" target=_blank title=\"View dataset in GBIF\">", the_feature$dataset, "</a></dd>
                    <dt>Institution</dt><dd>", the_feature$organizationname, "</dd>
                    <dt>Date</dt><dd>", the_feature$eventdate, "</dd>
                    <dt>Lat/Lon</dt><dd>", the_feature$latitude, " / ", the_feature$longitude, "</dd>
                    <dt>No. of records</dt><dd>", candidate_selected$no_features, "</dd>
                    <dt>Record issues</dt><dd><small>")
  
        if (the_feature$issue != ''){
            record_issues <- stringr::str_split(the_feature$issue, ";")[[1]]
      
          for (i in seq(1, length(record_issues))){
            if (i > 1){
              html_to_print <- paste0(html_to_print, "<br>")
            }
            
            html_to_print <- paste0(html_to_print, "<abbr title=\"", rgbif::gbif_issues_lookup(issue = record_issues[i])$description, "\">", record_issues[i], "</abbr>")
          }
        }
      }else{
        html_to_print <- paste0(html_to_print, "<dt>Source</dt><dd>", data_source, "</dd>
                              <dt>Score</dt><dd>", candidate_selected$score, "</dd>")
      }
    
    html_to_print <- paste0(html_to_print, "</small></dd></dl>",
                            "</div></div>")
    
    HTML(html_to_print)
    }
  })
  

  
  

  
  #delete marker----
  observeEvent(input$delete1, {
    
    proxy <- leafletProxy('map')
    
    proxy %>% removeMarker(layerId = "newm") %>% 
      removeShape(layerId = "circles")
      
    output$marker_info <- renderUI({req(FALSE)})
    
    removeUI("map_click")
    
    query <- parseQueryString(session$clientData$url_search)
    species <- query['species']
    recgrp_id <- query['recgrp_id']
    collex_id <- query['collex_id']
    candidate_id <- query['candidate_id']
    
    output$main <- renderUI({
      HTML(paste0("<script>$(location).attr('href', './?collex_id=", collex_id, "&species=", species, "&recgrp_id=", recgrp_id, "&candidate_id=", candidate_id, "')</script>"))
    })
    
  })
  
  
  
  #Folder progress----
  observeEvent(input$help, {
    
    api_req <- httr::POST(URLencode(paste0(api_url, "/api/data_sources")),
                          httr::add_headers(
                            "X-Api-Key" = app_api_key
                          ),
                          encode = "form"
    )
    
    data_sources <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
    
    data_sources <- data_sources %>% filter(is_online == TRUE) %>% 
      select(-datasource_id, -source_notes, -source_date, -source_refresh, -is_online) %>% 
      mutate("No. of features" = prettyNum(no_features, big.mark = ",", scientific = FALSE)) %>% 
      select(-no_features) %>% 
      mutate("URL" = paste0("<a href=\"", source_url, "\" target=_blank title = \"Open link to source\">", source_url, "</a>")) %>% 
      arrange(source_title) %>% 
      rename("Source" = source_title) %>% 
      select(-source_url)
    
    showModal(modalDialog(
      size = "l",
      title = "Help",
      br(),
      p("This application is a demo on an approach to georeference records on a massive scale. The georeferencing clusters records by species that share similar localities. Then, the system will display possible matches based on similar localities in GBIF, as well as locations from other databases."),
      DT::renderDataTable(DT::datatable(data_sources, 
                    escape = FALSE,
                    options = list(searching = FALSE,
                                   ordering = FALSE,
                                   pageLength = 30,
                                   paging = FALSE,
                                   columnDefs = list(list(
                                     className = 'dt-right', targets = 1
                                   ))
                    ),
                    rownames = FALSE,
                    selection = 'none')),
      easyClose = TRUE
    ))
  })
  
  
  
  #map_click----
  observeEvent(input$map_click, {
    output$candidatescores <- DT::renderDataTable(req(FALSE))
    p <- input$map_click
    
    output$candidatescores_box <- renderUI({req(FALSE)})
    
    output$marker_info <- renderUI({
      req(p)
      
      query <- parseQueryString(session$clientData$url_search)
      species <- query['species']
      recgrp_id <- query['recgrp_id']
      
      if(recgrp_id == "NULL"){
        req(FALSE)
      }
      
      click_lat <- format(round(as.numeric(p["lat"]), digits = 5), nsmall = 5)
      click_lng <- format(round(as.numeric(p["lng"]), digits = 5), nsmall = 5)
      
      session$userData$click_lat <- click_lat
      session$userData$click_lng <- click_lng
      
      #print(paste0("Click at: ", click_lat, "/", click_lng))
      
      icons <- awesomeIcons(icon = "map-pin",
                            markerColor = "green",
                            library = "fa")
      
      uncert_slider <- session$userData$uncert_slider
      
      query <- parseQueryString(session$clientData$url_search)
      uncertainty_m <- query['uncertainty_m']
      
      if (uncertainty_m == "NULL"){
        uncertainty_m = 500
      }
      
      leafletProxy('map') %>%
        removeMarker(layerId = "newm") %>% 
        addAwesomeMarkers(lng = as.numeric(click_lng), lat = as.numeric(click_lat), layerId = "newm", icon = icons) %>% 
        removeMarker(layerId = "newm_b") %>% 
        addCircles(lng = as.numeric(click_lng), lat = as.numeric(click_lat), radius = uncertainty_m, layerId = "newm_b", fillColor = "green", color = "green")
      
      #Actions
      #actions_box----
      output$actions_box <- renderUI({
        req(input$candidatematches_rows_selected)
        
        tagList(
          HTML("<br><div class=\"panel panel-info\">
        <div class=\"panel-heading\">
        <h3 class=\"panel-title\">Save Click Locality</h3>
        </div>
        <div class=\"panel-body\">"),
          uiOutput("actions_click"),
          HTML("</div></div>")
        )
      })
      
      #actions----
      output$actions_click <- renderUI({
        req(input$candidatematches_rows_selected)
        
        query <- parseQueryString(session$clientData$url_search)
        species <- query['species']
        recgrp_id <- query['recgrp_id']
        collex_id <- query['collex_id']
        candidate_id <- query['candidate_id']
        
        tagList(
          sliderInput("uncert_slider", "Set the Uncertainty Value (in meters):",
                  min = 0, max = 10000,
                  value = uncertainty_m, step = 25, width = "100%"),
          p(textInput("save_notes", "Notes:")),
          p(actionButton("click_rec_save", "Save location for the records", class = "btn-primary"))
        )
        
      })
      
      tagList(
        HTML(paste0("<br><div class=\"panel panel-success\">
                    <div class=\"panel-heading\">
                    <h3 class=\"panel-title\">Click on Map</h3>
                    </div>
                    <div class=\"panel-body\">
                        <dl class=\"dl-horizontal\">
                            <dt>Longitude</dt><dd>", click_lng, "</dd>
                            <dt>Latitude</dt><dd>", click_lat, "</dd></dl>")),
              #sliderInput("uncert_slider", "Set the Uncertainty Value (in meters):",
              #            min = 0, max = 10000,
              #            value = uncertainty_m, step = 25, width = "100%"),
              br(),
              actionButton("delete1", "Remove Click on Map", class = "btn-warning", style='font-size:80%'),
              HTML("</div>
                  </div>")
      )
    })
  })
  
  
  
  
  #uncert_slider----
  observeEvent(input$uncert_slider, {
    
    click_lat <- session$userData$click_lat
    click_lng <- session$userData$click_lng
    session$userData$uncert_slider <- input$uncert_slider
    
    leafletProxy('map') %>%
      removeMarker(layerId = "newm_b") %>% 
      addCircles(lng = as.numeric(click_lng), lat = as.numeric(click_lat), radius = input$uncert_slider, layerId = "newm_b", fillColor = "green", color = "green")
  })
  
  
  
  
  #actions_box----
  output$actions_box <- renderUI({
    req(input$candidatematches_rows_selected)
    
    tagList(
      HTML("<br><div class=\"panel panel-primary\">
        <div class=\"panel-heading\">
        <h3 class=\"panel-title\">Save Locality</h3>
        </div>
        <div class=\"panel-body\">"),
      uiOutput("actions"),
      HTML("</div></div>")
    )
  })
  
  
  #actions----
  output$actions <- renderUI({
    req(input$candidatematches_rows_selected)
    
    query <- parseQueryString(session$clientData$url_search)
    species <- query['species']
    recgrp_id <- query['recgrp_id']
    collex_id <- query['collex_id']
    candidate_id <- query['candidate_id']
    
    the_feature <- session$userData$the_feature
    #Get uncertainty
    uncert <- the_feature$min_bound_radius_m
    if (is.null(uncert)){
      u <- sliderInput("save_uncert", "Set the Uncertainty Value (in meters):",
                  min = 0, max = 10000,
                  value = 0, step = 25, width = "100%")
    }else{
      u <- p("Uncertainty: ", uncert)
    }
    
    tagList(
      u,
      p(textInput("save_notes", "Notes:")),
      p(actionButton("gbif_rec_save", "Save location for the records", class = "btn-primary"))
    )
  })
  
  
  #save_uncert----
  observeEvent(input$save_uncert, {
    the_feature <- session$userData$the_feature
    lat <- the_feature$latitude
    lng <- the_feature$longitude
    session$userData$save_uncert <- input$save_uncert
    
    leafletProxy('map') %>%
      removeMarker(layerId = "save_uncert") %>% 
      addCircles(lng = as.numeric(lng), lat = as.numeric(lat), radius = input$save_uncert, layerId = "save_uncert", fillColor = "yellow", color = "yellow")
  })
  
  
  # footer ----
  output$footer <- renderUI({
    HTML(paste0("<br><br><br><div class=\"footer navbar-fixed-bottom\"><br><p>&nbsp;&nbsp;<a href=\"http://dpo.si.edu\" target = _blank><img src=\"dpologo.jpg\"></a> | ", app_name, ", ver. ", app_ver, " | ", actionLink("help", label = "Help"), " | <a href=\"", github_link, "\" target = _blank>Source code</a></p></div>"))  
  })
}



#Run app----
shinyApp(ui = ui, server = server, onStart = function() {
  cat("Loading\n")
  #Cleanup on closing
  onStop(function() {
    cat("Closing\n")
    #
  })
})