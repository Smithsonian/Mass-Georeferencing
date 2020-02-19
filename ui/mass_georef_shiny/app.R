library(shiny)
library(leaflet)
library(leaflet.extras)
library(jsonlite)
library(futile.logger)
library(countrycode)
library(parallel)
library(shinyWidgets)
library(rgdal)
library(shinycssloaders)
library(dplyr)
library(taxize)
library(sp)
library(rgbif)
library(DT)
library(DBI)

#Settings----
app_name <- "Mass Georeferencing Tool - DPO"
app_ver <- "0.1.0"
github_link <- "https://github.com/Smithsonian/"
options(stringsAsFactors = FALSE)
options(encoding = 'UTF-8')
#Logfile
logfile <- paste0("logs/", format(Sys.time(), "%Y%m%d_%H%M%S"), ".txt")


#Settings
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


#UI----
ui <- fluidPage(
          title = app_name, 
          fluidRow(
            column(width = 3,
                   h2("Mass Georeferencing Tool", id = "title_main"),
                   uiOutput("main"),
                   uiOutput("maingroup"),
                   uiOutput("species"),
                   hr(),
                   uiOutput("records_h"),
                   #shinycssloaders::withSpinner(
                   div(DT::dataTableOutput("records"), style = "font-size:80%"),
                   uiOutput("record_selected")
                     #)
            ),
            column(width = 3,
                   uiOutput("candidatematches_h"),
                   div(DT::dataTableOutput("candidatematches"), style = "font-size:80%"),
                   uiOutput("res1")
            ),
            column(width = 6,
                   uiOutput("map_header"),
                   leafletOutput("map", width = "100%", height = "460px"),
                   fluidRow(
                     column(width = 6,
                            div(uiOutput("candidate_matches_info_h"), style = "font-size:80%")
                     ),
                     column(width = 6,
                            div(uiOutput("marker_info"), style = "font-size:80%")
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
  
  #Setup Logging
  dir.create('logs', showWarnings = FALSE)
  flog.logger("spatial", INFO, appender=appender.file(logfile))
  
  #main----
  output$main <- renderUI({
    query <- parseQueryString(session$clientData$url_search)
    collex <- query['collex']
    
    if (collex == "NULL"){
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
    collex <- query['collex']
    
    if (collex != "NULL"){
      
      collex <- dbGetQuery(db, paste0("SELECT * FROM mg_collex WHERE collex_id = '", collex, "'::uuid"))
      
      HTML(paste0("<p><a href=\"./\"><span class=\"glyphicon glyphicon-home\" aria-hidden=\"true\"></span> Home</a></p>
                  <h4><a href = \"./?collex=", collex$collex_id, "\">", collex$collex_name, "</a></h4>"))
    }else{
      collex_menu <- "<p>Select group (rank in parenthesis is how the group is selected):
                  <ul>"
      
      collections <- dbGetQuery(db, "SELECT * FROM mg_collex")
      
      for (i in seq(1, dim(collections)[1])){
          collex_menu <- paste0(collex_menu, "<li><a href=\"./?collex=", collections$collex_id[i], "\">", collections$collex_name[i], "</a></li>")
      }
            
      collex_menu <- paste0(collex_menu, "</ul></ul></p>")
      
      HTML(collex_menu)
    }
  })
  
  
  
  # species ----
  output$species <- renderUI({
    query <- parseQueryString(session$clientData$url_search)
    collex <- query['collex']
    species <- query['species']

    if (collex == "NULL"){req(FALSE)}
    if (species != "NULL"){req(FALSE)}
    
    #Encoding
    species <- dbGetQuery(db, "SET CLIENT_ENCODING TO 'UTF-8';")
    
    species_query <- paste0("SELECT DISTINCT species FROM mg_recordgroups WHERE collex_id = '", collex, "'::uuid")
    species <- dbGetQuery(db, species_query)
    
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
    collex <- query['collex']
    
    output$main <- renderUI({
      HTML(paste0("<script>$(location).attr('href', './?collex=", collex, "&species=", input$species, "')</script>"))
    })
  })
    
  
  
  #records_header----
  output$records_h <- renderUI({
    
    query <- parseQueryString(session$clientData$url_search)
    species <- query['species']
    
    session$userData$species <- species
    
    req(species != "NULL")
    
    vernacular <- try(sci2comm(scinames = species$species, db = "ncbi", simplify = TRUE), silent = TRUE)
    
    if (class(vernacular) == "try-error" || vernacular[1] == "character(0)"){
      vernacular_name <- ""
    }else{
      vernacular_name <- as.character(vernacular[1])
      #From https://stackoverflow.com/a/32758968
      vernacular_name <- paste0("<p>Common name: ", toupper(substr(vernacular_name, 1, 1)), substr(vernacular_name, 2, nchar(vernacular_name)), "</p>")
    }
    
    HTML(paste0("<h3>Species: <em>", species$species, "</em></h3>", vernacular_name))
  })
  
  
  #records----
  output$records <- DT::renderDataTable({
    species <- session$userData$species
    
    req(species != "NULL")
    
    records_query <- paste0("SELECT * FROM mg_recordgroups WHERE species = '", species, "' ORDER BY no_records DESC")
    
    records <- dbGetQuery(db, records_query)
    
    session$userData$records <- records
    
    data <- records[c("locality", "countrycode", "no_records")]
    names(data) <- c("Locality", "Country", "No. records") 
    
    DT::datatable(data, 
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

  
  
  #record_selected----
  output$record_selected <- renderUI({
    req(input$records_rows_selected)
    
    records <- session$userData$records
    this_row <- records[input$records_rows_selected,]
    
    if (this_row$stateprovince == ""){
      located_at <- countrycode::countrycode(this_row$countrycode, origin = "iso2c", destination = "country.name")
    }else{
      located_at <- paste0(this_row$stateprovince, ", ", countrycode::countrycode(this_row$countrycode, origin = "iso2c", destination = "country.name"))
    }


    #Group of records----
    observeEvent(input$showgroup, {
      
      showModal(modalDialog(
        size = "l",
        title = "Grouped records",
        DT::dataTableOutput("grouped_records"),
        easyClose = TRUE
        ))
      })
      req(input$records_rows_selected)
      records <- session$userData$records
      this_row <- records[input$records_rows_selected,]
      


    HTML(paste0("<br><div class=\"panel panel-primary\">
      <div class=\"panel-heading\">
      <h3 class=\"panel-title\">Record Selected</h3>
      </div>
      <div class=\"panel-body\">
          <dl class=\"dl-horizontal\">
          <dt><strong>Locality</strong></dt><dd><strong>", this_row$locality, "</strong></dd>
          <dt><strong>Located at</strong></dt><dd><strong>", located_at, "</strong></dd>
          <dt>No. of records</dt><dd>", this_row$no_records, "</dd>
        </dl>
        ", 
        actionLink("showgroup", label = "Show records in this group", style='font-size:80%'),
    "</div>
    </div>"))
    
  })
  
  

    #showgroup----
    output$grouped_records <- DT::renderDataTable({
      req(input$records_rows_selected)
      records <- session$userData$records
      this_row <- records[input$records_rows_selected,]

      records_query <- paste0("SELECT gbifid, eventdate, locality, countrycode, higherclassification, issue, recordedby FROM mg_occurrences WHERE mg_occurrenceid IN (SELECT mg_occurrenceid FROM mg_records WHERE recgroup_id = '", this_row$recgroup_id, "'::uuid)")
      print(records_query)

      records <- dbGetQuery(db, records_query)

      DT::datatable(records,
                       escape = FALSE,
                       options = list(searching = FALSE,
                                      ordering = TRUE,
                                      pageLength = 15,
                                      paging = TRUE#,
                                      #scrollx = "680px"#,
                                      # dom = 'Pfrtip', columnDefs = list(list(
                                      #   searchPanes = list(show = FALSE), targets = 3:4
                                      # ))
                       ),
                       rownames = FALSE,
                       selection = list(mode = 'none')) %>%
          DT::formatStyle(columns = c("gbifid", "eventdate", "locality", "countrycode", "higherclassification", "issue", "recordedby"), fontSize = '80%')
       })


  #candidatematches_h----
  output$candidatematches_h <- renderUI({
    req(input$records_rows_selected)
    h3("Candidate Matches:")
  })
  
  #candidatematches----
  output$candidatematches <- DT::renderDataTable({
    
    if (!is.null(input$records_rows_selected)){

      species <- session$userData$species
    
      req(species != "NULL")

      search_url <- api_searchfuzzy_url
      
      records <- session$userData$records
      
      this_row <- records[input$records_rows_selected,]

      recgroup_id <- this_row$recgroup_id
      
      candidates_query <- paste0("
                        WITH score AS (
                            SELECT 
                              c.candidate_id, 
                              ROUND(AVG(s.score),1) AS score, 
                              c.data_source,
                              c.feature_id 
                            FROM 
                              mg_candidates c LEFT JOIN 
                              mg_candidates_scores s ON (c.candidate_id = s.candidate_id)
                            WHERE 
                              c.recgroup_id = '", recgroup_id, "'::uuid
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
                                  decimallatitude as latitude
                                FROM 
                                  score s,                                  
                                  gbif m
                                WHERE 
                                  s.feature_id = m.gbifid AND
                                  m.species = '", species, "' AND
                                  s.data_source = ANY('{gbif.species,gbif.genus}')

                                UNION

                                SELECT
                                  s.data_source,
                                  s.score,
                                  m.name_1 as name,
                                  m.name_0 as located_at,
                                  m.engtype_1 as type,
                                  round(st_x(m.centroid)::numeric, 5) as longitude,
                                  round(st_y(m.centroid)::numeric, 5) as latitude
                                FROM 
                                  score s,                                  
                                  gadm1 m
                                WHERE 
                                  s.feature_id = m.uid::text AND
                                  s.data_source = 'gadm1'

                                UNION 

                                SELECT
                                  s.data_source,
                                  s.score,
                                  m.name_2 as name,
                                  m.name_1 || ', ' || m.name_0 as located_at,
                                  m.engtype_2 as type,
                                  round(st_x(m.centroid)::numeric, 5) as longitude,
                                  round(st_y(m.centroid)::numeric, 5) as latitude
                                FROM 
                                  score s,                                  
                                  gadm2 m
                                WHERE 
                                  s.feature_id = m.uid::text AND
                                  s.data_source = 'gadm2'

                                UNION 

                                SELECT
                                  s.data_source,
                                  s.score,
                                  m.name_3 as name,
                                  m.name_1 || ', ' || m.name_0 as located_at,
                                  m.engtype_3 as type,
                                  round(st_x(m.centroid)::numeric, 5) as longitude,
                                  round(st_y(m.centroid)::numeric, 5) as latitude
                                FROM 
                                  score s,                                  
                                  gadm3 m
                                WHERE 
                                  s.feature_id = m.uid::text AND
                                  s.data_source = 'gadm3'

                                UNION 

                                SELECT
                                  s.data_source,
                                  s.score,
                                  m.name_4 as name,
                                  m.name_1 || ', ' || m.name_0 as located_at,
                                  m.engtype_4 as type,
                                  round(st_x(m.centroid)::numeric, 5) as longitude,
                                  round(st_y(m.centroid)::numeric, 5) as latitude
                                FROM 
                                  score s,                                  
                                  gadm4 m
                                WHERE 
                                  s.feature_id = m.uid::text AND
                                  s.data_source = 'gadm4'

                                UNION 

                                SELECT
                                  s.data_source,
                                  s.score,
                                  m.name_5 as name,
                                  m.name_1 || ', ' || m.name_0 as located_at,
                                  m.engtype_5 as type,
                                  round(st_x(m.centroid)::numeric, 5) as longitude,
                                  round(st_y(m.centroid)::numeric, 5) as latitude
                                FROM 
                                  score s,                                  
                                  gadm5 m
                                WHERE 
                                  s.feature_id = m.uid::text AND
                                  s.data_source = 'gadm5'

                                UNION 

                                SELECT
                                  s.data_source,
                                  s.score,
                                  m.name,
                                  m.gadm2 as located_at,
                                  m.desig_eng as type,
                                  round(st_x(m.centroid)::numeric, 5) as longitude,
                                  round(st_y(m.centroid)::numeric, 5) as latitude
                                FROM 
                                  score s,                               
                                  wdpa_polygons m
                                WHERE 
                                  s.feature_id = m.uid::text AND
                                  s.data_source = 'wdpa_polygons'

                                UNION 

                                SELECT
                                  s.data_source,
                                  s.score,
                                  m.name,
                                  m.gadm2 as located_at,
                                  m.desig_eng as type,
                                  st_x(m.the_geom)::numeric as longitude,
                                  st_y(m.the_geom)::numeric as latitude
                                FROM 
                                  score s,                               
                                  wdpa_points m
                                WHERE 
                                  s.feature_id = m.uid::text AND
                                  s.data_source = 'wdpa_points'

                                UNION 

                                SELECT
                                  s.data_source,
                                  s.score,
                                  m.lake_name as name,
                                  m.gadm2 as located_at,
                                  m.type,
                                  round(st_x(m.centroid)::numeric, 5) as longitude,
                                  round(st_y(m.centroid)::numeric, 5) as latitude
                                FROM 
                                  score s,                               
                                  global_lakes m
                                WHERE 
                                  s.feature_id = m.uid::text AND
                                  s.data_source = 'global_lakes'

                                UNION 

                                SELECT
                                  s.data_source,
                                  s.score,
                                  m.full_name_nd_ro as name,
                                  m.gadm2 as located_at,
                                  null as type,
                                  long::numeric as longitude,
                                  lat::numeric as latitude
                                FROM 
                                  score s,                               
                                  gns m
                                WHERE 
                                  s.feature_id = m.uid::text AND
                                  s.data_source = 'gns'

                                UNION

                                SELECT
                                  s.data_source,
                                  s.score,
                                  m.feature_name as name,
                                  m.gadm2 as located_at,
                                  m.feature_class as type,
                                  prim_long_dec::numeric as longitude,
                                  prim_lat_dec::numeric as latitude
                                FROM 
                                  score s,                               
                                  gnis m
                                WHERE 
                                  s.feature_id = m.uid::text AND
                                  s.data_source = 'gnis'
                                ")
                           
      #cat(matches_query)
      results <- dbGetQuery(db, candidates_query)
      
       if (dim(results)[1] == 0){

         results_table <- results
         
         output$res1 <- renderUI({
           tagList(
             tags$br(),tags$br(),
             tags$em("No results found.")
           )
         })

       }else{

         results <- results %>%
           dplyr::arrange(match(data_source, c("gbif.species", "gbif.genus", "wdpa_polygons", "wdpa_points", "global_lakes", "geonames", "gadm5", "gadm4", "gadm3", "gadm2", "gadm1", "gadm0"))) %>% 
           dplyr::arrange(dplyr::desc(score))
           
         session$userData$results <- results
         
         gadm_layers <- c("gadm", "gadm0", "gadm1", "gadm2", "gadm3", "gadm4", "gadm5")
         gbif_layers <- c("gbif.species", "gbif.genus", "gbif.family")
         wdpa_layers <- c("wdpa_polygons", "wdpa_points", "wdpa")
         
         for (i in seq(1, dim(results)[1])){
           if (results$data_source[i] %in% gadm_layers){
             results$name[i] <- paste0(results$name[i], "<span class=\"glyphicon glyphicon-flag pull-right\" aria-hidden=\"true\" title = \"Political locality from GADM\"></span>")
           }else if (results$data_source[i] == "gbif.species"){
             results$name[i] <- paste0(results$name[i], "<span class=\"glyphicon glyphicon-map-marker pull-right\" aria-hidden=\"true\" title = \"Locality from a GBIF record for the species\"></span>")
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
           }
         }
         
         #if (dim(results)[1] > 0){
         #results_table <- results# %>% dplyr::select(-gbifid) %>% 
           # dplyr::select(-match) %>% 
           # dplyr::select(-no_records) %>% 
           # dplyr::select(-eventdate)
         
         #Convert type to factor for filtering
         #results$type <- as.factor(results$type)
         
         #Reorder cols
         #results_table <- results[c("source", "name", "located_at", "score")]
         results_table <- results[c("name", "located_at", "score")]
         Encoding(results_table$name) <- "ASCII"
         Encoding(results_table$located_at) <- "ASCII"
         #names(results_table) <- c("Source", "Locality", "Located at", "Score")
         names(results_table) <- c("Locality", "Located at", "Score")
         #}
         
         output$res1 <- renderUI({

         })
       }
       
      if (dim(results_table)[1]==0){
        DT::datatable(NULL,
                      escape = FALSE,
                      options = list(searching = FALSE,
                                     ordering = TRUE,
                                     pageLength = 15,
                                     paging = FALSE,
                                     language = list(zeroRecords = "No matches found"),
                                     scrollY = "380px"
                      ),
                      rownames = FALSE,
                      selection = list(mode = 'single', selected = c(1)),
                      caption = "Select a locality to show on the map")
      }else if (dim(results_table)[1]==1){
         DT::datatable(results_table,
                       escape = FALSE,
                       options = list(searching = FALSE,
                                      ordering = TRUE,
                                      pageLength = 15,
                                      paging = FALSE,
                                      scrollY = "680px"
                       ),
                       rownames = FALSE,
                       selection = list(mode = 'single', selected = c(1)),
                       caption = "Select a locality to show on the map")
       }else{
         DT::datatable(results_table,
                       escape = FALSE,
                       options = list(searching = FALSE,
                                      ordering = TRUE,
                                      pageLength = 15,
                                      paging = TRUE,
                                      scrollY = "680px"#,
                                      # dom = 'Pfrtip', columnDefs = list(list(
                                      #   searchPanes = list(show = FALSE), targets = 3:4
                                      # ))
                       ),
                       #extensions = c('Select', 'SearchPanes'),
                       rownames = FALSE,
                       selection = list(mode = 'single'),
                       caption = "Select a locality to show on the map") %>% 
                                        formatStyle(c('Score'),
                                         background = styleColorBar(range(50, 100), 'lightblue'),
                                         backgroundSize = '98% 88%',
                                         backgroundRepeat = 'no-repeat',
                                         backgroundPosition = 'center')
       }
     }
  })

  
  
  #map----
  output$map <- renderLeaflet({
    species <- session$userData$species
    
    if (species == "NULL"){
      req(FALSE)
    }
      
    if (is.null(input$records_rows_selected)){
      #species only----
      
      api_convex_url <- "http://dpogis.si.edu/api/0.1/species_range?scientificname="
      
      url_get <- paste0(api_convex_url, species)
      
      #print(url_get)
      
      api_req <- httr::GET(url = URLencode(url_get),
                           httr::add_headers(
                             "X-Api-Key" = app_api_key
                           )
      )
      
      #print(api_req)
      
      convex_geom <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
      
      #from https://gis.stackexchange.com/a/252992
      y <- paste0('{\"type\":\"Feature\",\"properties\":{\"Species\": \"', convex_geom$type, ' of ', species, '\"},\"geometry\":', convex_geom$the_geom, '}')
      y2 <- paste(y, collapse=',')
      spp_geom <- paste0("{\"type\":\"FeatureCollection\",\"features\":[",y2,"]}")
      #print(spp_geom)
      
      spp_geom_bounds <- paste0("[
                          [", convex_geom$ymax, ", ", convex_geom$xmax, "],
                          [", convex_geom$ymin, ", ", convex_geom$xmin, "]
                      ]")
      
      #bounds
      xmin <- convex_geom$xmin
      ymin <- convex_geom$ymin
      xmax <- convex_geom$xmax
      ymax <- convex_geom$ymax
      
      if (xmin == xmax || ymin == ymax){
        xmin <- xmin - 0.05
        xmax <- xmax + 0.05
        ymin <- ymin - 0.05
        ymax <- ymax + 0.05
      }
      
      #species_geom_layer <- paste0(convex_geom$type, ' of\n', species)
      species_geom_layer <- "Species Dist"
      
      leaflet(options = leafletOptions(zoomControl = FALSE)) %>%
        htmlwidgets::onRender("function(el, x) {
              L.control.zoom({ position: 'topright' }).addTo(this)
          }") %>%
        addProviderTiles(providers$OpenStreetMap.HOT, group = "OSM") %>%
        addProviderTiles(providers$OpenTopoMap, group = "Topo") %>%
        addProviderTiles(providers$Esri.WorldStreetMap, group = "ESRI") %>%
        addProviderTiles(providers$Esri.WorldImagery, group = "ESRI Sat") %>%
        addGeoJSONv2(spp_geom, popupProperty='Species', color = "#36e265", opacity = 0.2, group = species_geom_layer) %>%
        addMiniMap(tiles = providers$OpenStreetMap.HOT, toggleDisplay = TRUE, zoomLevelOffset = -6) %>%
        fitBounds(xmin, ymin, xmax, ymax) %>%
        addScaleBar(position = "bottomleft") %>%
        # Layers control
        addLayersControl(
          baseGroups = c("OSM", "Topo", "ESRI", "ESRI Sat"),
          overlayGroups = species_geom_layer,
          options = layersControlOptions(collapsed = FALSE)
        ) %>% 
        addEasyButton(easyButton(
          icon="fa-search", title="Zoom to Species Range",
          onClick=JS("function(btn, map){ map.fitBounds([", spp_geom_bounds, "]);}"))
        ) %>% 
        addMeasure(primaryLengthUnit="kilometers", secondaryLengthUnit="miles", primaryAreaUnit = "sqkilometers", position = "topleft")
      
  }else{
      req(input$records_rows_selected)

      if (is.null(input$candidatematches_rows_selected)){
        
        #Only species dist----
        api_convex_url <- "http://dpogis.si.edu/api/0.1/species_range?scientificname="
        
        #convexhull
        url_get <- paste0(api_convex_url, species)
        
        #print(url_get)
        
        api_req <- httr::GET(url = URLencode(url_get),
                             httr::add_headers(
                               "X-Api-Key" = app_api_key
                             )
        )
        
        #print(api_req)
        
        if (api_req$status_code == 200){
          convex_geom <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
          
          #from https://gis.stackexchange.com/a/252992
          y <- paste0('{\"type\":\"Feature\",\"properties\":{\"Species\": \"', convex_geom$type, ' of ', species, '\"},\"geometry\":', convex_geom$the_geom, '}')
          y2 <- paste(y, collapse=',')
          spp_geom <- paste0("{\"type\":\"FeatureCollection\",\"features\":[",y2,"]}")
          #print(spp_geom)
          
          spp_geom_bounds <- paste0("[
                            [", convex_geom$ymax, ", ", convex_geom$xmax, "],
                            [", convex_geom$ymin, ", ", convex_geom$xmin, "]
                        ]")
          
          #bounds
          xmin <- convex_geom$xmin
          ymin <- convex_geom$ymin
          xmax <- convex_geom$xmax
          ymax <- convex_geom$ymax
        }else{
          convex_geom <- "{\"type\":\"FeatureCollection\",\"features\":[]}"
          xmin <- 0
          ymin <- 0
          xmax <- 0
          ymax <- 0
        }
        
        if (xmin == xmax || ymin == ymax){
          xmin <- xmin - 0.05
          xmax <- xmax + 0.05
          ymin <- ymin - 0.05
          ymax <- ymax + 0.05
        }
        
        #Draw all candidates
        results <- session$userData$results

        coords <- SpatialPoints(coords = data.frame(lng = as.numeric(results$longitude), lat = as.numeric(results$latitude)), proj4string = CRS("+proj=longlat +datum=WGS84"))
        #print(coords)
        data <- as.data.frame(results$name)
        #print(data)

        icons <- awesomeIcons(icon = "whatever",
                              iconColor = "red",
                              library = "ion")
        
        species_geom_layer <- "Species Dist"
        
        leaflet(options = leafletOptions(zoomControl = FALSE)) %>%
          htmlwidgets::onRender("function(el, x) {
                  L.control.zoom({ position: 'topright' }).addTo(this)
              }") %>%
          addProviderTiles(providers$OpenStreetMap.HOT, group = "OSM") %>%
          addProviderTiles(providers$OpenTopoMap, group = "Topo") %>%
          addProviderTiles(providers$Esri.WorldStreetMap, group = "ESRI") %>%
          addProviderTiles(providers$Esri.WorldImagery, group = "ESRI Sat") %>%
          addMiniMap(tiles = providers$OpenStreetMap.HOT, toggleDisplay = TRUE, zoomLevelOffset = -6) %>%
          addGeoJSONv2(spp_geom, popupProperty='Species', color = "#36e265", opacity = 0.2, group = species_geom_layer) %>%
          addScaleBar(position = "bottomleft") %>%
          fitBounds(xmin, ymin, xmax, ymax) %>%
          addLayersControl(
            baseGroups = c("OSM", "Topo", "ESRI", "ESRI Sat"),
            overlayGroups = species_geom_layer,
            options = layersControlOptions(collapsed = FALSE)
          ) %>% 
          addMeasure(primaryLengthUnit="kilometers", secondaryLengthUnit="miles", primaryAreaUnit = "sqkilometers", position = "topleft") %>% 
          addAwesomeMarkers(data = coords, popup = results$name, clusterOptions = markerClusterOptions())
          
      }else{
          results <- session$userData$results
          this_row <- results[input$candidatematches_rows_selected, ]
          
          Encoding(this_row$name) <- "ASCII"
          Encoding(this_row$located_at) <- "ASCII"
          
          #print(this_row)
          
          geom_layer <- this_row$data_source
          geom_uid <- this_row$feature_id
          geom_name <- this_row$name
          geom_located_at <- this_row$located_at
          gbifid <- this_row$feature_id
          
          #if geom from GBIF----
          if (geom_layer == "gbif.species" || geom_layer == "gbif.genus"){
            
            match_query <- paste0("SELECT 
                                  g.*,
                                  CASE WHEN d.organizationname = '' 
                                      THEN d.title
                                      ELSE CONCAT(d.title, ', ', d.organizationname) END AS dataset,
                                  d.datasetkey
                              FROM 
                                  gbif g,
                                  gbif_datasets d
                              WHERE 
                                  g.species = '", species, "' AND 
                                  g.gbifid = '", gbifid, "' AND
                                  g.datasetkey::uuid = d.datasetkey")
            cat(match_query)
            the_feature <- dbGetQuery(db, match_query)
            
            #candidate_matches_info_h----
            output$candidate_matches_info_h <- renderUI({
              
              observeEvent(input$map_click, {
                p <- input$map_click
                output$marker_info <- renderUI({
                  req(p)
    
                  click_lat <- format(round(as.numeric(p["lat"]), digits = 5), nsmall = 5)
                  click_lng <- format(round(as.numeric(p["lng"]), digits = 5), nsmall = 5)
                  
                  print(paste0("Click at: ", click_lat, "/", click_lng))
    
                  icons <- awesomeIcons(icon = "whatever",
                                        iconColor = "red",
                                        library = "ion")
                  leafletProxy('map') %>%
                    removeMarker(layerId = "newm") %>% 
                    addAwesomeMarkers(lng = as.numeric(click_lng), lat = as.numeric(click_lat), layerId = "newm", icon = icons)
                  
                  HTML(paste0("<br><div class=\"panel panel-success\">
                    <div class=\"panel-heading\">
                    <h3 class=\"panel-title\">Click on Map</h3>
                    </div>
                    <div class=\"panel-body\">
                        <dl class=\"dl-horizontal\">
                            <dt>Longitude</dt><dd>", click_lng, "</dd>
                            <dt>Latitude</dt><dd>", click_lat, "</dd>
                            <dt>Uncertainty</dt><dd>", 
                              
                            "</dd>
                            </dl>",
                            sliderInput("integer", "Set the value in m:",
                                        min = 10, max = 10000,
                                        value = 500),
                            actionButton("rec_save", "Save location for the records", style='font-size:80%'),
                  "</div>
                  </div>"))
                })
              })
              
              uncert <- the_feature$coordinateuncertaintyinmeters
              if (is.na(uncert)){
                uncert <- "NA"
              }else{
                uncert <- paste0(uncert, " m")
              }
                
              
              html_to_print <- paste0("<br><div class=\"panel panel-success\">
                    <div class=\"panel-heading\">
                    <h3 class=\"panel-title\">Match Selected</h3>
                    </div>
                    <div class=\"panel-body\">
                        <dl class=\"dl-horizontal\">
                            <dt>Name</dt><dd>", this_row$name, "</dd>
                            <dt>Located in</dt><dd>", this_row$located_at, "</dd>
                            <dt>Locality uncertainty</dt><dd>", uncert, "</dd>
                            <dt>Source</dt><dd><a href=\"https://www.gbif.org/occurrence/", the_feature$gbifid, "\" target=_blank title=\"Open record in GBIF\">GBIF record (", the_feature$gbifid, ")</a></dd>
                            <dt>Dataset</dt><dd><a href=\"https://www.gbif.org/dataset/", the_feature$datasetkey, "\" target=_blank title=\"View dataset in GBIF\">", the_feature$dataset, "</a></dd>
                            <dt>Date</dt><dd>", this_row$eventdate, "</dd>
                            <dt>Score</dt><dd>", this_row$score, "</dd>
                            <dt>No. of records</dt><dd>", this_row$no_records, "</dd>
                            <dt>Lat/Lon</dt><dd>", this_row$latitude, " / ", this_row$longitude, "</dd>
                            <dt>Record issues</dt><dd><small>")
              
              
              cat(the_feature$issue)
              if (the_feature$issue != ''){
                record_issues <- stringr::str_split(the_feature$issue, ";")[[1]]
                
                for (i in seq(1, length(record_issues))){
                  if (i > 1){
                    html_to_print <- paste0(html_to_print, "<br>")
                  }
                  
                  html_to_print <- paste0(html_to_print, "<abbr title=\"", gbif_issues_lookup(issue = record_issues[i])$description, "\">", record_issues[i], "</abbr>")
                }
              }
              
              html_to_print <- paste0(html_to_print, "</small></dd></dl>", 
                                      actionButton("gbif_rec_save", "Save location for the records", style='font-size:80%'),
                                      "</div></div>")
              
              HTML(html_to_print)
            })
            
            #convexhull
            api_convex_url <- "http://dpogis.si.edu/api/0.1/species_range?scientificname="
            
            url_get <- paste0(api_convex_url, species)
            
            #print(url_get)
            
            api_req <- httr::GET(url = URLencode(url_get),
                                 httr::add_headers(
                                   "X-Api-Key" = app_api_key
                                 )
            )
            
            #print(api_req)
            
            convex_geom <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
            
            #from https://gis.stackexchange.com/a/252992
            y <- paste0('{\"type\":\"Feature\",\"properties\":{\"Species\": \"', convex_geom$type, ' of ', species, '\"},\"geometry\":', convex_geom$the_geom, '}')
            y2 <- paste(y, collapse=',')
            spp_geom <- paste0("{\"type\":\"FeatureCollection\",\"features\":[",y2,"]}")
            #print(spp_geom)
            
            spp_geom_bounds <- paste0("[
                              [", convex_geom$ymax, ", ", convex_geom$xmax, "],
                              [", convex_geom$ymin, ", ", convex_geom$xmin, "]
                          ]")
            
            #bounds
            xmin <- convex_geom$xmin
            ymin <- convex_geom$ymin
            xmax <- convex_geom$xmax
            ymax <- convex_geom$ymax
            
            sitelon <- the_feature$decimallongitude
            sitelat <- the_feature$decimallatitude
            
            feat_long <- the_feature$decimallongitude
            feat_lat <- the_feature$decimallatitude
            feat_name <- the_feature$locality
            feat_country <- the_feature$countrycode
            feat_layer <- "GBIF"
            feat_type <- "Point"
            
            #bounds
            xmin <- the_feature$decimallongitude
            ymin <- the_feature$decimallatitude
            xmax <- the_feature$decimallongitude
            ymax <- the_feature$decimallatitude
            
            if (xmin == xmax || ymin == ymax){
              xmin <- xmin - 0.05
              xmax <- xmax + 0.05
              ymin <- ymin - 0.05
              ymax <- ymax + 0.05
            }
            
            #species_geom_layer <- paste0(convex_geom$type, ' of ', species)
            species_geom_layer <- "Species Dist"
            
            # %>% 
            #   addGeoJSONv2(spp_geom, popupProperty='Species', color = "#36e265", opacity = 0.2, group = species_geom_layer) #Uncertainty buffer
            # 
            # #from https://gis.stackexchange.com/a/252992
            # y <- paste0('{\"type\":\"Feature\",\"properties\":{\"Uncertainty of location\": ', the_feature$coordinateuncertaintym, '},\"geometry\":', convex_geom$the_geom, '}')
            # y2 <- paste(y, collapse=',')
            # spp_geom <- paste0("{\"type\":\"FeatureCollection\",\"features\":[",y2,"]}")
            # print(spp_geom)
            
            
            leaflet(options = leafletOptions(zoomControl = FALSE)) %>%
              htmlwidgets::onRender("function(el, x) {
                  L.control.zoom({ position: 'topright' }).addTo(this)
              }") %>%
              addProviderTiles(providers$OpenStreetMap.HOT, group = "OSM") %>%
              addProviderTiles(providers$OpenTopoMap, group = "Topo") %>%
              addProviderTiles(providers$Esri.WorldStreetMap, group = "ESRI") %>%
              addProviderTiles(providers$Esri.WorldImagery, group = "ESRI Sat") %>%
              addGeoJSONv2(spp_geom, popupProperty='Species', color = "#36e265", opacity = 0.2, group = species_geom_layer) %>%
              addAwesomeMarkers(data = cbind(feat_long, feat_lat), popup = paste0('Name: ', feat_name, '<br>Country: ', feat_country, '<br>Lon: ', sitelon, '<br>Lat: ', sitelat, '<br>Layer: ', feat_layer, '<br>Type: ', feat_type)) %>%
              addMiniMap(tiles = providers$OpenStreetMap.HOT, toggleDisplay = TRUE, zoomLevelOffset = -6) %>%
              fitBounds(xmin, ymin, xmax, ymax) %>%
              addScaleBar(position = "bottomleft") %>%
              addCircles(lng = feat_long, lat = feat_lat, weight = 1,
                         radius = as.numeric(the_feature$coordinateuncertaintyinmeters), popup = paste0("Uncertainty of the locality: ", the_feature$coordinateuncertaintyinmeters)) %>% 
              # Layers control
              addLayersControl(
                baseGroups = c("OSM", "Topo", "ESRI", "ESRI Sat"),
                overlayGroups = species_geom_layer,
                options = layersControlOptions(collapsed = FALSE)
              ) %>% 
              addEasyButton(easyButton(
                icon="fa-search", title="Zoom to Species Range",
                onClick=JS("function(btn, map){ map.fitBounds([", spp_geom_bounds, "]);}"))
                ) %>% 
              addMeasure(primaryLengthUnit="kilometers", secondaryLengthUnit="miles", primaryAreaUnit = "sqkilometers", position = "topleft")
          }else{
            #If geom from other----
            
            #Feature
            url_get <- paste0(api_detail_url, geom_uid, "&layer=", geom_layer)
            
            #print(url_get)
            
            api_req <- httr::GET(url = URLencode(url_get),
                                 httr::add_headers(
                                   "X-Api-Key" = app_api_key
                                 )
            )
            
            print("THE FEATURE")
            print(api_req)
            
            the_feature <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
            
            #Geometry
            url_get <- paste0(api_geom_url, geom_uid, "&layer=", geom_layer)
            
            #print(url_get)
            
            api_req <- httr::GET(url = URLencode(url_get),
                                 httr::add_headers(
                                   "X-Api-Key" = app_api_key
                                 )
            )
            
            #print(api_req)
            
            the_geom <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
            
            #candidate_matches_info_h----
            output$candidate_matches_info_h <- renderUI({
    
              observeEvent(input$map_click, {
                p <- input$map_click
                output$marker_info <- renderUI({
                  req(p)
    
                  click_lat <- format(round(as.numeric(p["lat"]), digits = 5), nsmall = 5)
                  click_lng <- format(round(as.numeric(p["lng"]), digits = 5), nsmall = 5)
                  
                  print(paste0(click_lat, "/", click_lng))
                  
                  #click = input$map_click
                  icons <- awesomeIcons(icon = "whatever",
                                        iconColor = "red",
                                        library = "ion")
                  leafletProxy('map') %>%
                    removeMarker(layerId = "newm") %>% 
                    addAwesomeMarkers(lng = as.numeric(click_lng), lat = as.numeric(click_lat), layerId = "newm", icon = icons)
                  
                  #HTML(paste0("Click on ", p$lng, "/", p$lat))
                  tagList(
                    HTML(paste0("<br><div class=\"panel panel-success\">
                    <div class=\"panel-heading\">
                    <h3 class=\"panel-title\">Click on Map</h3>
                    </div>
                    <div class=\"panel-body\">
                        <dl class=\"dl-horizontal\">
                            <dt>Longitude</dt><dd>", click_lng, "</dd>
                            <dt>Latitude</dt><dd>", click_lat, "</dd>
                            </dl>", 
                                
                                "
                  </div>")), 
                    #uiOutput("uncert_slider"),
                    
                    #uncert_slider----
                    #output$uncert_slider <- renderUI({
                      sliderInput("uncert_slider", "Uncertainty in m:", min = 5, max = 10000, value = 50),
                    actionButton("gbif_rec_save", "Save location for the records", style='font-size:80%'),
                    #})
                    HTML("</div>")
                  )
                  
                })
              })
                
              
              HTML(paste0("<br><div class=\"panel panel-success\">
                  <div class=\"panel-heading\">
                  <h3 class=\"panel-title\">Match Selected</h3>
                  </div>
                  <div class=\"panel-body\">
                     <dl class=\"dl-horizontal\">
                        <dt>Name</dt><dd>", this_row$name, "</dd>
                        <dt>Located in</dt><dd>", this_row$located_at, "</dd>
                        <dt>Uncertainty from<br> polygon area</dt><dd><br>", the_geom$min_bound_radius_m, " m</dd>
                        <dt>Type</dt><dd>", this_row$type, "</dd>
                        <dt>Source</dt><dd>", this_row$source, "</dd>
                        <dt>Score</dt><dd>", this_row$score, "</dd>
                      </dl>
                      ",
                          actionButton("button", "Georeference using point and uncertainty", style='font-size:80%'),
                          "<br><br>",
                          actionButton("button", "Georeference using polygon", style='font-size:80%'),
                          "<br><br>",
                          actionButton("button", "Georeference using both", style='font-size:80%'),
                      "
                </div>
                </div>"))
            })
            
            
            #from https://gis.stackexchange.com/a/252992
            y <- paste0('{\"type\":\"Feature\",\"properties\":{\"Polygon\": \"Name: ', the_geom$name, '<br>Located at: ', the_geom$parent, '<br>Type: ', the_geom$type, '<br>Layer: ', the_geom$layer, '\"},\"geometry\":', the_geom$the_geom, '}')
            y2 <- paste(y, collapse=',')
            x <- paste0("{\"type\":\"FeatureCollection\",\"features\":[",y2,"]}")
            #print(x)
            
            #convexhull
            
            api_convex_url <- "http://dpogis.si.edu/api/0.1/species_range?scientificname="
            
            url_get <- paste0(api_convex_url, species)
            
            #print(url_get)
            
            api_req <- httr::GET(url = URLencode(url_get),
                                 httr::add_headers(
                                   "X-Api-Key" = app_api_key
                                 )
            )
            
            #print(api_req)
            
            convex_geom <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
            
            #from https://gis.stackexchange.com/a/252992
            y <- paste0('{\"type\":\"Feature\",\"properties\":{\"Species\": \"', convex_geom$type, ' of ', species, '\"},\"geometry\":', convex_geom$the_geom, '}')
            y2 <- paste(y, collapse=',')
            spp_geom <- paste0("{\"type\":\"FeatureCollection\",\"features\":[",y2,"]}")
            #print(spp_geom)
            
            spp_geom_bounds <- paste0("[
                              [", convex_geom$ymax, ", ", convex_geom$xmax, "],
                              [", convex_geom$ymin, ", ", convex_geom$xmin, "]
                          ]")
            
            #bounds
            xmin <- convex_geom$xmin
            ymin <- convex_geom$ymin
            xmax <- convex_geom$xmax
            ymax <- convex_geom$ymax
            
            if (the_feature$geom_type == 'polygon'){
              sitelon <- paste0(round(the_feature$longitude, 5), " (centroid)")
              sitelat <- paste0(round(the_feature$latitude, 5), " (centroid)")
            }else{
              sitelon <- the_feature$longitude
              sitelat <- the_feature$latitude
            }
            
            feat_long <- the_feature$longitude
            feat_lat <- the_feature$latitude
            feat_name <- the_feature$name
            feat_country <- the_feature$parent
            feat_layer <- the_feature$layer
            feat_type <- the_feature$type
            
            #bounds
            xmin <- the_geom$xmin
            ymin <- the_geom$ymin
            xmax <- the_geom$xmax
            ymax <- the_geom$ymax
            
            if (xmin == xmax || ymin == ymax){
              xmin <- xmin - 0.05
              xmax <- xmax + 0.05
              ymin <- ymin - 0.05
              ymax <- ymax + 0.05
            }
            
            species_geom_layer <- paste0(convex_geom$type, ' of ', species)
            #species_geom_layer <- "Species Dist"
            
            #polygon uncertainty
            if (the_geom$geom_type == 'polygon'){
              y <- paste0('{\"type\":\"Feature\",\"properties\":{\"Extent\": \"Extent of the polygon for ', feat_name, '\"},\"geometry\":', the_geom$the_geom_extent, '}')
              y2 <- paste(y, collapse=',')
              extent_geom <- paste0("{\"type\":\"FeatureCollection\",\"features\":[",y2,"]}")
              
              leaflet(options = leafletOptions(zoomControl = FALSE)) %>%
                htmlwidgets::onRender("function(el, x) {
                  L.control.zoom({ position: 'topright' }).addTo(this)
              }") %>%
                addProviderTiles(providers$OpenStreetMap.HOT, group = "OSM") %>%
                addProviderTiles(providers$OpenTopoMap, group = "Topo") %>%
                addProviderTiles(providers$Esri.WorldStreetMap, group = "ESRI") %>%
                addProviderTiles(providers$Esri.WorldImagery, group = "ESRI Sat") %>%
                addGeoJSONv2(spp_geom, popupProperty='Species', color = "#36e265", opacity = 0.2, group = species_geom_layer) %>%
                addGeoJSONv2(extent_geom, popupProperty='Extent', color = "#E1E134", opacity = 0.2) %>%
                addGeoJSONv2(x, popupProperty='Polygon') %>%
                addAwesomeMarkers(data = cbind(feat_long, feat_lat), popup = paste0('Name: ', feat_name, '<br>Country: ', feat_country, '<br>Lon: ', sitelon, '<br>Lat: ', sitelat, '<br>Type: ', feat_type, '<br>Layer: ', feat_layer)) %>%
                addMiniMap(tiles = providers$OpenStreetMap.HOT, toggleDisplay = TRUE, zoomLevelOffset = -6) %>%
                fitBounds(xmin, ymin, xmax, ymax) %>%
                addScaleBar(position = "bottomleft") %>%
                # Layers control
                addLayersControl(
                  baseGroups = c("OSM", "Topo", "ESRI", "ESRI Sat"),
                  overlayGroups = species_geom_layer,
                  options = layersControlOptions(collapsed = FALSE)
                ) %>% 
                addEasyButton(easyButton(
                  icon="fa-search", title="Zoom to Species Range",
                  onClick=JS("function(btn, map){ map.fitBounds([", spp_geom_bounds, "]);}"))
                ) %>% 
                addMeasure(primaryLengthUnit="kilometers", secondaryLengthUnit="miles", primaryAreaUnit = "sqkilometers", position = "topleft")
            }else{
              poly_uncert <- NA
              poly_uncert_lon <- NA
              poly_uncert_lat <- NA
              
              leaflet(options = leafletOptions(zoomControl = FALSE)) %>%
                htmlwidgets::onRender("function(el, x) {
                  L.control.zoom({ position: 'topright' }).addTo(this)
              }") %>%
                addProviderTiles(providers$OpenStreetMap.HOT, group = "OSM") %>%
                addProviderTiles(providers$OpenTopoMap, group = "Topo") %>%
                addProviderTiles(providers$Esri.WorldStreetMap, group = "ESRI") %>%
                addProviderTiles(providers$Esri.WorldImagery, group = "ESRI Sat") %>%
                addGeoJSONv2(spp_geom, popupProperty='Species', color = "#36e265", opacity = 0.2, group = species_geom_layer) %>%
                addGeoJSONv2(x, popupProperty='Polygon') %>%
                addAwesomeMarkers(data = cbind(feat_long, feat_lat), popup = paste0('Name: ', feat_name, '<br>Country: ', feat_country, '<br>Lon: ', sitelon, '<br>Lat: ', sitelat, '<br>Type: ', feat_type, '<br>Layer: ', feat_layer)) %>%
                addMiniMap(tiles = providers$OpenStreetMap.HOT, toggleDisplay = TRUE, zoomLevelOffset = -6) %>%
                fitBounds(xmin, ymin, xmax, ymax) %>%
                addScaleBar(position = "bottomleft") %>%
                # Layers control
                addLayersControl(
                  baseGroups = c("OSM", "Topo", "ESRI", "ESRI Sat"),
                  overlayGroups = species_geom_layer,
                  options = layersControlOptions(collapsed = FALSE)
                ) %>% 
                addEasyButton(easyButton(
                  icon="fa-search", title="Zoom to Species Range",
                  onClick=JS("function(btn, map){ map.fitBounds([", spp_geom_bounds, "]);}"))
                ) %>% 
                addMeasure(primaryLengthUnit="kilometers", secondaryLengthUnit="miles", primaryAreaUnit = "sqkilometers", position = "topleft")
            }
            
            
        }
      }
    }
  })
  
  
  
  
  # footer ----
  output$footer <- renderUI({
    HTML(paste0("<br><br><br><div class=\"footer navbar-fixed-bottom\"><br><p>&nbsp;&nbsp;<a href=\"http://dpo.si.edu\" target = _blank><img src=\"dpologo.jpg\"></a> | ", app_name, ", ver. ", app_ver, " | ", actionLink("help", label = "Help"), " | <a href=\"", github_link, "\" target = _blank>Source code</a></p></div>"))
  })
  
  
  
  #Folder progress----
  observeEvent(input$help, {
    
    api_req <- httr::GET(url = URLencode(api_sources_url),
                         httr::add_headers(
                           "X-Api-Key" = app_api_key
                         )
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
                                   paging = FALSE
                    ),
                    rownames = FALSE,
                    selection = 'none')),
      easyClose = TRUE
    ))
  })
  
  
  
  
  
  # map_header ----
  output$map_header <- renderUI({
    
    query <- parseQueryString(session$clientData$url_search)
    collex <- query['collex']
    species <- query['species']
    
    if (collex == "NULL"){req(FALSE)}
    if (species == "NULL"){req(FALSE)}
    
    if (is.null(input$records_rows_selected)){
      h4("Map of the species distribution:")
    }else{
      h4("Map of the species distribution and candidate matches:")
    }
  })
    
  
}



#Run app----
shinyApp(ui = ui, server = server, onStart = function() {
  cat("Loading\n")
  #Cleanup on closing
  onStop(function() {
    cat("Closing\n")
    #Close db connection
    dbDisconnect(db)
  })
})