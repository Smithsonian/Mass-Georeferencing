library(shiny)
library(leaflet)
library(leaflet.extras)
library(jsonlite)
library(countrycode)
library(shinyWidgets)
library(shinycssloaders)
library(dplyr)
library(sp)
library(DT)
library(rgbif)
library(shinyjs)
library(rmarkdown)
library(DBI)
#library(rpostgis)
library(httr)
library(uuid)
set_config(config(ssl_verifypeer = 0L))


#Settings----
app_name <- "Mass Georeferencing Tool"
app_ver <- "0.1.0"
github_link <- "https://github.com/Smithsonian/Mass-Georeferencing"
options(stringsAsFactors = FALSE)
options(encoding = 'UTF-8')
#Logfile
#logfile <- paste0("logs/", format(Sys.time(), "%Y%m%d_%H%M%S"), ".txt")


#Settings
source("settings.R")
source("leafletmap.R")






jsCode <- '
        shinyjs.getcookie = function(params) {
          var cookie = Cookies.get("uid");
          if (typeof cookie !== "undefined") {
            Shiny.onInputChange("jscookie", cookie);
          } else {
            var cookie = "";
            Shiny.onInputChange("jscookie", cookie);
          }
        }
        shinyjs.setcookie = function(params) {
          Cookies.set("uid", escape(params), { expires: 6 });  
          Shiny.onInputChange("jscookie", params);
        }
        shinyjs.rmcookie = function(params) {
          Cookies.remove("uid");
          Shiny.onInputChange("jscookie", "");
        }
      '


#UI----
ui <- fluidPage(
  
    #cookies
    tags$script(src = "js.cookie.min.js"),

    useShinyjs(),
    extendShinyjs(text = jsCode),
    
    #title = app_name,
    fluidRow(
      column(width = 4,
             #h2("Mass Georeferencing Tool", id = "title_main"),
             #h2(div(a(img(src="mass_geo_icon.png", height = "30px"), app_name, href="./")), id = "title_main"),
             uiOutput("title"),
             uiOutput("main"),
             uiOutput("userlogin"),
             uiOutput("maingroup"),
             uiOutput("species"),
             uiOutput("records_h"),
             div(DT::dataTableOutput("records"), style = "font-size:80%"),
             div(uiOutput("record_selected"), style = "font-size:90%"),
             uiOutput("candidatematches_h")
      ),
      column(width = 8,
             fluidRow(
               column(width = 10,
                      uiOutput("map_header")
               ),
               column(width = 2,
                      uiOutput("userinfo")
               )
             ),
             shinycssloaders::withSpinner(leafletOutput("map", width = "100%", height = "520px")),
             fluidRow(
               column(width = 4,
                      div(uiOutput("candidate_matches_info_h"))
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
  
  status <- reactiveVal(value = NULL)
  # check if a cookie is present and matching our super random sessionid
  observe({
    js$getcookie()
    
    if (is.null(input$jscookie)) {
      status(paste0('in with sessionid ', input$jscookie))
    }
    else {
      status('out')
    }
  })
  
  status <- reactiveVal(value = NULL)
  # check if a cookie is present and matching our super random sessionid  
  observe({
    js$getcookie()
    if (!is.null(input$jscookie)) {
      #print(paste0("157 ", input$jscookie))
      api_req <- httr::POST(URLencode(paste0(api_url, "mg/check_cookie")),
                            body = list(cookie = input$jscookie),
                            httr::add_headers(
                              "X-Api-Key" = app_api_key
                            ),
                            encode = "form"
      )
      cookie_check <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
      if (length(cookie_check$user_id) != 1){
        status('out168')
        js$rmcookie()
      }
    }
  })
  
  
  
  #userlogin----
  output$userlogin <- renderUI({
    js$getcookie()
    
    if (is.null(input$jscookie)){
      tagList(
        br(),br(),br(),br(),
        textInput("username", "Username:"),
        passwordInput("password", "Password:"),
        actionButton("login", "Login")
      )
      
    }else{
      api_req <- httr::POST(URLencode(paste0(api_url, "mg/check_cookie")),
                            body = list(cookie = input$jscookie),
                            httr::add_headers(
                              "X-Api-Key" = app_api_key
                            ),
                            encode = "form"
      )
      cookie_check <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
      
      if (length(cookie_check$user_id) != 1){
        js$rmcookie()
        tagList(
          br(),br(),br(),
          textInput("username", "Username:"),
          passwordInput("password", "Password:"),
          actionButton("login", "Login")
        )
      }else{
        session$userData$user_id <- cookie_check$user_id
        session$userData$username <- cookie_check$user_name
        HTML("&nbsp;")
      }
    }
  })
  
  
  
  #observeEvent_login----
  observeEvent(input$login, {
    api_req <- httr::POST(URLencode(paste0(api_url, "mg/login")),
                          body = list(user_name = input$username,
                                      password = input$password
                                      ),
                          httr::add_headers(
                            "X-Api-Key" = app_api_key
                          ),
                          encode = "form"
    )
    login <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
    
    if (length(login$user_id) != 1){
      output$userlogin <- renderUI({
        p("Error: User not found or password not correct.")
      }) 
    }else{
      api_req <- httr::POST(URLencode(paste0(api_url, "mg/check_cookie")),
                            body = list(cookie = input$jscookie),
                            httr::add_headers(
                              "X-Api-Key" = app_api_key
                            ),
                            encode = "form"
      )
      cookie_check <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
      
      if (length(cookie_check$user_id) != 1){
        sessionid <- paste(
          collapse = '',
          sample(x = c(letters, LETTERS, 0:9), size = 64, replace = TRUE)
        )
        
        js$setcookie(sessionid)
        
        api_req <- httr::POST(URLencode(paste0(api_url, "mg/new_cookie")),
                              body = list(user_id = login$user_id,
                                          cookie = sessionid),
                              httr::add_headers(
                                "X-Api-Key" = app_api_key
                              ),
                              encode = "form"
        )
        new_cookie <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
        
        session$userData$user_id <- cookie_check$user_id
        session$userData$username <- cookie_check$user_name
      }else{
        session$userData$user_id <- cookie_check$user_id
        session$userData$username <- cookie_check$user_name
      }
      
      output$userlogin <- renderUI({
        HTML("&nbsp;")
      }) 
    }
  })
  
  
  
  #userinfo----
  output$userinfo <- renderUI({
    js$getcookie()
    req(input$jscookie)
    
    tagList(
      HTML("<div class = \"pull-right\">"),
      tags$small(session$userData$username, "  ", actionLink('logout', '[Logout]')),
      HTML("</div>")
    )
  }) 
  
  
  
  #observeEvent_logout----
  observeEvent(input$logout, {
    js$rmcookie()
    #runqc_refresh----
    output$runqc <- renderUI({
      HTML("<script>$(location).attr('href', './')</script>")
    })
  })
  
  
  
  
  source("functions.R")
  
  #title
  output$title <- renderUI({
    query <- parseQueryString(session$clientData$url_search)
    collex_id <- query['collex_id']
    
    h2(div(a(img(src="mass_geo_icon.png", height = "30px"), app_name, href="./")), id = "title_main")
  })
  
  #main----
  output$main <- renderUI({
    query <- parseQueryString(session$clientData$url_search)
    collex_id <- query['collex_id']
    
    if (collex_id == "NULL"){
      shinyWidgets::panel(
        p("To use this app, select a dataset to see the list of species available for georeferencing."),
        p("This app was made by the Digitization Program Office, OCIO."),
        heading = "Welcome",
        status = "primary"
      )
    }
  })
  
  
  #maingroup ----
  output$maingroup <- renderUI({
    js$getcookie()
    req(input$jscookie)
    
    query <- parseQueryString(session$clientData$url_search)
    collex_id <- query['collex_id']
    species <- query['species']
    
    api_req <- httr::POST(URLencode(paste0(api_url, "mg/check_cookie")),
                          body = list(cookie = input$jscookie),
                          httr::add_headers(
                            "X-Api-Key" = app_api_key
                          ),
                          encode = "form"
    )
    cookie_check <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
    
    session$userData$user_id <- cookie_check$user_id
    session$userData$username <- cookie_check$user_name
    
    if (length(session$userData$user_id) == 0){
      req(FALSE)
      }
    
    if (collex_id != "NULL"){
      
      session$userData$collex_id <- collex_id
      
      api_req <- httr::POST(URLencode(paste0(api_url, "mg/collex_info")),
                            body = list(collex_id = collex_id),
                            httr::add_headers(
                              "X-Api-Key" = app_api_key
                            ),
                            encode = "form"
      )
      
      collex <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
      
      if (species == "NULL"){
        HTML(paste0("<h4>", collex$collex_name, "</h4>"))
      }else{
        HTML(paste0("<p><a href = \"./?collex_id=", collex$collex_id, "\"><span class=\"glyphicon glyphicon-home\" aria-hidden=\"true\"></span> Home</a></p>"))
      }
  
    }else{
      collex_menu <- "<p>Select group:
                  <ul>"
      
      api_req <- httr::POST(URLencode(paste0(api_url, "mg/all_collex")),
                            body = list(user_id = session$userData$user_id),
                            httr::add_headers(
                              "X-Api-Key" = app_api_key
                            ),
                            encode = "form"
      )
      
      collections <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
      
      for (i in seq(1, dim(collections)[1])){
          collex_menu <- paste0(collex_menu, "<li><a href=\"./?collex_id=", collections$collex_id[i], "\">", collections$collex_name[i], "</a> - ", collections$collex_definition[i], "</li>")
          
          api_req <- httr::POST(URLencode(paste0(api_url, "mg/collex_dl")),
                                body = list(collex_id = collections$collex_id[i]),
                                httr::add_headers(
                                  "X-Api-Key" = app_api_key
                                ),
                                encode = "form"
          )
          
          collex_dl <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
          
          if (is.null(collex_dl) == FALSE){
            if (is.null(dim(collex_dl)) == FALSE){
              
              collex_menu <- paste0(collex_menu, "<em>Downloads</em>: <ul>")
              for (c in seq(1, dim(collex_dl)[1])){
                collex_menu <- paste0(collex_menu, "<li><a href=\"", collex_dl$dl_file_path[c], "\">Path to exported files</a></li>")
              }
              
              collex_menu <- paste0(collex_menu, "</ul>")
            }
            
          }
          
          collex_menu <- paste0(collex_menu, "</li>")
      }
            
      collex_menu <- paste0(collex_menu, "</ul></p>")
      
      HTML(collex_menu)
    }
  })
  
  
  
  # species ----
  output$species <- renderUI({
    js$getcookie()
    req(input$jscookie)
    
    query <- parseQueryString(session$clientData$url_search)
    collex_id <- query['collex_id']
    species <- query['species']

    if (collex_id == "NULL"){req(FALSE)}
    if (species != "NULL"){req(FALSE)}
    
    api_req <- httr::POST(URLencode(paste0(api_url, "mg/collex_info")),
                          body = list(collex_id = collex_id),
                          httr::add_headers(
                            "X-Api-Key" = app_api_key
                          ),
                          encode = "form"
    )
    
    collex <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
    
    api_req <- httr::POST(URLencode(paste0(api_url, "mg/collex_species")),
                          body = list(collex_id = collex_id),
                          httr::add_headers(
                            "X-Api-Key" = app_api_key
                          ),
                          encode = "form"
    )
    
    species <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
    
    if (length(species) > 1){
      names(species) <- species
    }
    
    to_dl <- HTML("<p><b>Generate exports to download the georeferenced data:</b></p>")
    
    if (collex$no_selected_matches > 0){
        to_dl2 <- actionButton("generate_dl", "Default Recipe", class = "btn-success")
        to_dl3 <- actionButton("generate_dl2", "Recipe 1 (SQL and KMZ) - coming soon", class = "btn-success disabled")
        to_dl4 <- actionButton("generate_dl2", "Recipe VZ (CSV, SQL, and SHP) - coming soon", class = "btn-success disabled")
        to_dl5 <- actionButton("generate_dl2", "Recipe VZ 2 (CSV, SQL, and KMZ) - coming soon", class = "btn-success disabled")
    }else{
        to_dl2 <- p("Select matches to enable the export function...")
        to_dl3 <- ""
        to_dl4 <- ""
        to_dl5 <- ""
    }
    
    tagList(
      selectInput("species", "Select a species:", species),
      actionButton("submit_species", "Georeference species records", class = "btn-primary"),
      br(),
      hr(),
      
      h4("Dataset statistics:"),
      
      HTML(paste0("<dl class=\"dl-horizontal\">
                  <dt>", prettyNum(collex$no_species, big.mark = ",", scientific = FALSE), "</dt><dd>Species</dd>
                  <dt>", prettyNum(collex$no_records, big.mark = ",", scientific = FALSE), "</dt><dd>No. records</dd>
                  <dt>", prettyNum(collex$no_recordgroups, big.mark = ",", scientific = FALSE), "</dt><dd>No. record groups</dd>
                  <dt>", prettyNum(collex$no_selected_matches, big.mark = ",", scientific = FALSE), " (", round((collex$no_selected_matches/collex$no_recordgroups) * 100, 2), "%)</dt><dd>Georeferenced record groups</dd></dl>")),
      
      to_dl,
      to_dl2,
      p(),
      to_dl3,
      p(),
      to_dl4,
      p(),
      to_dl5
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
    
  
  
  
  #generate_dl - Generate download----
  observeEvent(input$generate_dl, {
    
    query <- parseQueryString(session$clientData$url_search)
    collex_id <- query['collex_id']

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

    # Create a Progress object
    progress <- shiny::Progress$new()
    # Make sure it closes when we exit this reactive, even if there's an error
    on.exit(progress$close())
    
    progress$set(message = "Exporting data from database", value = 0.05)
    
    # getdl_query <- paste0("SELECT o.* FROM mg_occurrences o, mg_selected_candidates s, WHERE s.collex_id = '", collex_id, "'")
    # collex_data <- dbGetQuery(db, getdl_query)
    # 
    getdl_query <- paste0("SELECT data_source, point_or_polygon, count(*) as no_records FROM mg_selected_candidates WHERE collex_id = '", collex_id, "' GROUP BY data_source, point_or_polygon")
    datasources <- dbGetQuery(db, getdl_query)
    
    steps <- 0.9 / dim(datasources)[1]
    
    progress$set(message = "Exporting layers from database", value = 0.1)
    
    filespath <- toupper(UUIDgenerate())
    
    no_recs <- sum(datasources$no_records)
    
    ins_query <- paste0("INSERT INTO mg_collex_dl (collex_id, dl_recipe, dl_file_path, dl_norecords) VALUES ('", collex_id, "'::UUID, 'Default', '", filespath, "', '", no_recs, "')")
    
    dbSendQuery(db, ins_query)
    
    Sys.sleep(5)
    
    # system(paste0("mkdir -p www/", filespath))
    # 
    # links <- "<h3>Links to downloads:</h3>"
    # 
    # for (d in seq(1, dim(datasources)[1])){
    #   
    #   progress$set(message = paste0("Exporting ", datasources$data_source[d], " (", datasources$point_or_polygon[d], ") from database"), value = 0.1 + (d * steps))
    #   
    #   
    #   data_source <- ""
    #   data_source_filename <- paste0(datasources$data_source[d], "_", datasources$point_or_polygon[d], "_geoms")
    #   
    #   system("mkdir -p /tmp/mg")
    #   system("rm -f /tmp/mg/*")
    #   
    #   query <- paste0("SELECT d.uid geom_id, d.name as geom_name, d.the_geom as geom, o.* FROM mg_occurrences o,     topo_map_polygons d,     mg_selected_candidates c,     mg_recordgroups r,     mg_records mgr WHERE     o.collex_id = '", collex_id, "'::uuid and o.collex_id = c.collex_id    and c.recgroup_id = r.recgroup_id   and r.recgroup_id = mgr.recgroup_id   and o.mg_occurrenceid = mgr.mg_occurrenceid  and d.uid IN   (SELECT feature_id::uuid as uid FROM mg_candidates WHERE candidate_id IN ( SELECT candidate_id AS uid FROM mg_selected_candidates WHERE data_source = 'topo_map_polygons' AND collex_id = '", collex_id, "'::uuid))")
    #   
    #   data <- dbGetQuery(db, query)
    #     
    #   system(paste0("pgsql2shp -u ", pg_user, " -h ", pg_host, " -P ", pg_pass, " -f /tmp/mg/", data_source_filename, ".shp gis \"", query, "\""))
    #   
    #   system(paste0("zip -j www/", filespath, "/", data_source_filename, ".zip /tmp/mg/", data_source_filename, ".*"))
    #   system("rm -r /tmp/mg")
    #   
    #   links <- paste0(links, "<p><a href=\"", filespath, "/", data_source_filename, ".zip\">", datasources$data_source[d], "</a></p>")
    #   
    # }
    # 
    # #Georeferenced records
    # system("mkdir -p /tmp/mg")
    # system("rm -f /tmp/mg/*")
    # 
    # system(paste0("pgsql2shp -u ", pg_user, " -h ", pg_host, " -P ", pg_pass, " -f /tmp/mg/occ_results.shp gis \"SELECT uid, the_geom as geom FROM mg_occurrence\""))
    
    # system(paste0("zip -j www/", filespath, "/occ_results_.zip /tmp/mg/occ_results.*"))
    # system("rm -r /tmp/mg")
    # 
    # output$species <- renderUI({
    #   HTML("Generating files. Please wait...")
    # })
    output$main <- renderUI({
      HTML(paste0("<br><p><a href=\"https://dpogis.si.edu/dl/", filespath, "\">Click here to download the files</a>.</p><br><br><p>Generating downloads may take a minute.</p><br><br><p><a href=\"./\">Home</a><hr>"))
    })
    
    output$species <- renderUI({
      HTML("&nbsp;")
    })
    
    output$maingroup <- renderUI({
      HTML("&nbsp;")
    })
  })
  
  
  #Species selected----
  #species records header----
  output$records_h <- renderUI({
    js$getcookie()
    req(input$jscookie)
    
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
    js$getcookie()
    req(input$jscookie)
    
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
    
    if (length(records) > 0){
      records <- arrange(records, desc(no_records))
      session$userData$speciesrecords <- records
    }else{
      output$main <- renderUI({
        HTML(paste0("<br><br><p><strong>No more records available. Please select another species in the <a href=\"./?collex_id=", collex_id, "\">main menu</a></strong></p>"))
      })
      
      req(FALSE)
      
    }
    
    records <- records[c("locality", "countrycode", "no_records")]
    names(records) <- c("Locality", "Country", "No. records") 
    
    DT::datatable(records, 
                escape = FALSE,
                options = list(searching = FALSE,
                               ordering = TRUE,
                               pageLength = 5,
                               paging = TRUE,
                               language = list(zeroRecords = "No more records available")
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
    js$getcookie()
    req(input$jscookie)
    
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
    js$getcookie()
    req(input$jscookie)
    
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
    #group_records$occurrenceid <- paste0("<a href='",group_records$occurrenceid,"' target='_blank'>",group_records$occurrenceid,"</a>")
    
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
    js$getcookie()
    req(input$jscookie)
    
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
    js$getcookie()
    req(input$jscookie)
    
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
      
      candidates <- as.data.frame(fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE))
      
      candidates$longitude <- as.numeric(candidates$longitude)
      candidates$latitude <- as.numeric(candidates$latitude)
      
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
             results$name[i] <- paste0(results$name[i], "<img src=\"gbif_logo.png\" title = \"Locality from a GBIF record for the species\" alt = \"Locality from a GBIF record for the genus\" height = \"16px\" class=\"pull-right\">")
           }else if (results$data_source[i] == "gbif.family"){
             results$name[i] <- paste0(results$name[i], "<img src=\"gbif_logo.png\" title = \"Locality from a GBIF record for the species\" alt = \"Locality from a GBIF record for the family\" height = \"16px\" class=\"pull-right\">")
           }else if (results$data_source[i] == "wikidata"){
             results$name[i] <- paste0(results$name[i], "<img src=\"wikidata-logo.png\" title = \"Locality from Wikidata\" alt = \"Locality from Wikidata\" height = \"12px\" class=\"pull-right\">")
           }else if (results$data_source[i] == "osm"){
             results$name[i] <- paste0(results$name[i], "<img src=\"osm_logo.png\" title = \"Locality from Wikidata\" alt = \"Locality from OpenStreetMap\" height = \"16px\" class=\"pull-right\">")
           }else if (results$data_source[i] == "topo_map_points" || results$data_source[i] == "topo_map_polygons"){
             results$name[i] <- paste0(results$name[i], "<img src=\"usgs_logo.png\" title = \"Locality from Topo Vector Data\" alt = \"Locality from Topo Vector Data\" height = \"16px\" class=\"pull-right\">")
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
           }else if (results$data_source[i] == "usa_rivers"){
             results$name[i] <- paste0(results$name[i], "<span class=\"glyphicon glyphicon-tint pull-right\" aria-hidden=\"true\" title = \"Locality from USA Rivers and Streams\"></span>")
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
        
        query <- parseQueryString(session$clientData$url_search)

        if (is.null(spp_map_data)){
          leaflet_map(species_map = FALSE, markers = TRUE, markers_data = candidates)
        }else{
          leaflet_map(species_data = spp_map_data, markers = TRUE, markers_data = candidates, query = query)
        }
        
      })
      
      output$map_header <- renderUI({
        tagList(
          h4("Map of the species distribution and candidate matches:"),
          HTML("<small>Click on the map to create a new locality; you may need to turn off buffers to create a point in that area</small>")
        )
      })
      
       if (candidate_id == "NULL"){
         DT::datatable(results_table,
                       escape = FALSE,
                       options = list(searching = FALSE,
                                      ordering = TRUE,
                                      pageLength = 8,
                                      paging = TRUE,
                                      bLengthChange = FALSE
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
                                      bLengthChange = FALSE
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
    js$getcookie()
    req(input$jscookie)
    
    query <- parseQueryString(session$clientData$url_search)
    species <- query['species']
    recgrp_id <- query['recgrp_id']
    collex_id <- query['collex_id']
    candidate_id <- query['candidate_id']

    if (candidate_id == "NULL"){
      req(FALSE)
    }
    
    req(input$candidatematches_rows_selected)
    
    tagList(
      HTML("<br><div class=\"panel panel-success\">
        <div class=\"panel-heading\">
        <h3 class=\"panel-title\">Scores for the Candidate Locality Selected</h3>
        </div>
        <div class=\"panel-body\">"),
      div(DT::dataTableOutput("candidatescores"), style = "font-size:80%"),
      HTML("</div></div>")
    )
  })
  
  
  #candidatescores----
  output$candidatescores <- DT::renderDataTable({
    js$getcookie()
    req(input$jscookie)
    
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
    
    if(dim(other_candidates)[1] > 0){
      other_candidates$link <- paste0(other_candidates$name, "<br>Located at: ", other_candidates$located_at, "<br>Source: ", other_candidates$data_source, "<br>Uncertainty (m): ", prettyNum(other_candidates$uncertainty_m, big.mark = ",", scientific = FALSE), "<br>Score: ", other_candidates$score, "<br><small><a href=\"./?collex_id=", collex_id, "&species=", species, "&recgrp_id=", recgrp_id, "&candidate_id=", other_candidates$candidate_id, "\">Select this locality</a></small>")
    }
    
    #Display map of selected candidate----
    output$map <- renderLeaflet({
      spp_map <- session$userData$spp_map
      spp_map_data <- session$userData$spp_map_data
      
      if (is.null(spp_map_data)){
        leaflet_map(species_map = FALSE, candidate = TRUE, candidate_data = candidate_selected, markers = TRUE, markers_data = other_candidates)
      }else{
        leaflet_map(species_data = spp_map_data, candidate = TRUE, candidate_data = candidate_selected, markers = TRUE, markers_data = other_candidates)
      }
      
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
    js$getcookie()
    req(input$jscookie)
    
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
    js$getcookie()
    req(input$jscookie)
    
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
    js$getcookie()
    req(input$jscookie)
    
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
    #if (candidate_info$data_source == "gbif.species" || candidate_info$data_source == "gbif.genus"){
    if (substring(candidate_info$data_source, 0, 4) == "gbif"){
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
      
      session$userData$the_feature <- the_feature
      
      uncert <- the_feature$coordinateuncertaintyinmeters
      
      if (is.na(uncert)){
        uncert <- "NA"
      }else{
        uncert <- paste0(uncert, " m")
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
        uncert <- "<abbr title=\"No uncertainty or area was given in the source\">NA</abbr>"
      }else{
          uncert <- paste0(uncert, " m<br>(yellow buffer in map; from polygon area)")
      }
    }
    
    if (api_req$status_code == 200){
      
      html_to_print <- paste0("<br><div class=\"panel panel-success\">
          <div class=\"panel-heading\">
          <h3 class=\"panel-title\">Candidate Locality Selected</h3>
          </div>
          <div class=\"panel-body\" style = \"font-size:80%;\">
              <dl class=\"dl-horizontal\">
                  <dt>Name</dt><dd>", the_feature$name, "</dd>
                  <dt>Located at</dt><dd>", the_feature$located_at, "</dd>
                  <dt>Locality uncertainty (m)</dt><dd>", uncert, "</dd>")
      
      
      
      api_req_d <- httr::POST(URLencode(paste0(api_url, "api/data_sources")),
                            httr::add_headers(
                              "X-Api-Key" = app_api_key
                            ),
                            encode = "form"
      )
      
      data_sources <- fromJSON(httr::content(api_req_d, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
      
      data_source_info <- data_sources[data_sources$datasource_id == data_source, ]
      
      
      if (data_source == "gbif"){
        the_feature <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
        
        html_to_print <- paste0(html_to_print, "<dt>Source</dt><dd><abbr title=\"", data_source_info$source_title, "\"><a href=\"https://www.gbif.org/occurrence/", the_feature$gbifid, "\" target=_blank title=\"Open record in GBIF\">GBIF record (", the_feature$gbifid, ")</a></abbr></dd>
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
        html_to_print <- paste0(html_to_print, "<dt>Source</dt><dd><abbr title=\"", data_source_info$source_title, "\">", data_source, " </abbr></dd>
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
      select(-datasource_id, -source_notes, -source_date, -source_refresh, -is_online)
    
    total_feats <- prettyNum(sum(data_sources$no_features), big.mark = ",", scientific = FALSE)
    
    data_sources <- data_sources %>% mutate("No. of features" = prettyNum(no_features, big.mark = ",", scientific = FALSE)) %>% 
      select(-no_features) %>% 
      mutate("Source" = paste0("<a href=\"", source_url, "\" target=_blank title = \"Open link to source\">", source_title, "</a>")) %>% 
      arrange(source_title) %>% 
      select(-source_url, -source_title) %>% 
      select('Source', 'No. of features')
    
    showModal(modalDialog(
      size = "m",
      title = "Help",
      br(),
      HTML("<p style=\"font-size:80%;\">This application is a demo on an approach to georeference records on a massive scale. The georeferencing clusters records by species that share similar localities. Then, the system will display possible matches based on similar localities in GBIF, as well as locations from other databases.</p>
           <p style=\"font-size:80%;\">It is recommneded to run this application in full screen (F11) in a full HD display (1920x1080).</p>
           <p style=\"font-size:80%;\">Area of polygons is measured in meters using a UTM projection.</p>"),
      h4("Known Issues"),
      HTML("<ul style=\"font-size:80%;\"><li>The login form may appear briefly while the page is loading</li><li>Invalid countries or country names written in non-standard ways will have less matches</li></ul>"),
      h4("Data Sources"),
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
      br(),
      HTML(paste0("<p class=\"pull-right\"><strong>Total number of features: ", total_feats, "</strong></p><br>")),
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
        
        #req(input$candidatematches_rows_selected)
        req(input$map_click)
        
        tagList(
          HTML("<br><div class=\"panel panel-info\">
        <div class=\"panel-heading\">
        <h3 class=\"panel-title\">Save Click Locality</h3>
        </div>
        <div class=\"panel-body\">"),
          uiOutput("actions_click", style = "font-size:80%"),
          HTML("</div></div>")
        )
      })
      
      #actions----
      output$actions_click <- renderUI({
        #req(input$candidatematches_rows_selected)
        req(input$map_click)
        
        records <- session$userData$records
        recgrp_id <- session$userData$recgrp_id
        
        this_row <- records[records$recgroup_id == recgrp_id,]
        
        query <- parseQueryString(session$clientData$url_search)
        species <- query['species']
        recgrp_id <- query['recgrp_id']
        collex_id <- query['collex_id']
        candidate_id <- query['candidate_id']
        
        tagList(
          sliderInput("uncert_slider", "Set the Uncertainty Value (in meters):",
                  min = 0, max = 20000,
                  value = uncertainty_m, step = 25, width = "100%"),
          textInput("save_locality", label = "Locality name:", value = this_row$locality),
          textInput("save_notes", "Notes:"),
          actionButton("click_rec_save", "Save location for the records", class = "btn-primary")
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
    
    #
    #
    #
    #
    #
    #
    #
    #
    #
    #
    #
    #
    #
    #
    #
    #
    #
    #
    
    user_id <- session$userData$user_id
    
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
    if (the_feature$layer == "gbif"){
      uncert <- the_feature$coordinateuncertaintyinmeters
      if (is.na(uncert)){
        #if (is.na(uncert)){
        u <- sliderInput("save_uncert", "Set the Uncertainty Value (in meters):",
                         min = 0, max = 20000,
                         value = 0, step = 25, width = "100%")
      }else{
        session$userData$uncert <- uncert
        u <- p(paste0("Uncertainty: ", prettyNum(uncert, big.mark = ",", scientific = FALSE), "m"))
      }
    }else{
      uncert <- the_feature$min_bound_radius_m
      if (is.null(uncert)){
        #if (is.na(uncert)){
        u <- sliderInput("save_uncert", "Set the Uncertainty Value (in meters):",
                         min = 0, max = 20000,
                         value = 0, step = 25, width = "100%")
      }else{
        session$userData$uncert <- uncert
        u <- p(paste0("Uncertainty: ", prettyNum(uncert, big.mark = ",", scientific = FALSE), "m"))
      }
    }
    # 
    # if (is.na(uncert)){
    #   #if (is.na(uncert)){
    #   u <- sliderInput("save_uncert", "Set the Uncertainty Value (in meters):",
    #               min = 0, max = 20000,
    #               value = 0, step = 25, width = "100%")
    # }else{
    #   session$userData$uncert <- uncert
    #   u <- p(paste0("Uncertainty: ", prettyNum(uncert, big.mark = ",", scientific = FALSE), "m"))
    # }
    
    tagList(
      u,
      p(textInput("save_notes", "Notes:")),
      p(actionButton("rec_save", "Review match", class = "btn-primary"))
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
  
  
  
  
  #click_rec_save modal----
  observeEvent(input$click_rec_save, {
    
    records <- session$userData$records
    recgrp_id <- session$userData$recgrp_id
    species <- session$userData$species
    collex_id <- session$userData$collex_id
    
    uncert_slider <- session$userData$uncert_slider
    
    req(records)
    req(recgrp_id)
    req(species)
    req(collex_id)
    
    #Get record group
    this_row <- records[records$recgroup_id == recgrp_id,]
    
    #Selected match
    the_feature <- session$userData$the_feature
    #Get uncertainty
    uncert <- uncert_slider
    if (is.null(uncert)){
      input_uncert <- input$save_uncert
    }else{
      input_uncert <- uncert
    }
    
    req(input$map_click)
    
    #Get clickmap
    p <- input$map_click
    
    api_req <- httr::POST(URLencode(paste0(api_url, "api/intersection")),
                          body = list(lat = p["lat"],
                                      lng = p["lng"],
                                      layer = 'gadm'),
                          httr::add_headers(
                            "X-Api-Key" = app_api_key
                          ),
                          encode = "form"
    )
    
    api_locality <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
    #print(api_locality)
    
    locality <- data.frame(api_locality)
    
    located_at <- dplyr::filter(locality, intersection.layer == 'gadm2')
    #print(located_at)
    
    
    lat_to_save <- format(round(as.numeric(p["lat"]), digits = 5), nsmall = 5)
    lng_to_save <- format(round(as.numeric(p["lng"]), digits = 5), nsmall = 5)
    data_source <- "Custom location"
    located_at <- located_at$intersection.located_at
    name <- this_row$locality
    
    print(1692)
    print(this_row)
    print(1694)
    print(located_at)
    
    showModal(modalDialog(
      size = "l",
      title = "Save match",
      fluidRow(
        column(width = 6,
               HTML("<div class=\"panel panel-primary\">
        <div class=\"panel-heading\">
        <h3 class=\"panel-title\">Record Group</h3>
        </div>
        <div class=\"panel-body\">"),
               HTML(paste0("<dl>
                      <dt>Locality</dt><dd>", this_row$locality, "</dd>
                      <dt>No. records</dt><dd>", this_row$no_records, "</dd>
                    ")),
              HTML(paste0("
                      <dt>Species</dt><dd><em>", this_row$species, "</em></dd>
                      <dt>Family</dt><dd>", this_row$family, "</dd>
                    </dl>")),
               
               HTML("</div></div>")
        ),
        column(width = 6,
               HTML("<div class=\"panel panel-success\">
        <div class=\"panel-heading\">
        <h3 class=\"panel-title\">Selected Match</h3>
          </div>
          <div class=\"panel-body\">
              <dl>
                  <dt>Name</dt><dd>", name, "</dd>
                  <dt>Located at</dt><dd>", located_at, "</dd>
                  <dt>Locality uncertainty (m)</dt><dd>", prettyNum(uncert_slider, big.mark = ",", scientific = FALSE), "</dd>
                  <dt>Source</dt><dd>", data_source, "</dd>
                  <dt>Lat/Lon</dt><dd>", lat_to_save, " / ", lng_to_save, "</dd>
              </dl>"
               ),
               
               HTML("</div></div>")
        )
      ),
      br(),
      p(actionButton("write_db", "Save locality for these records", class = "btn-primary")),
      easyClose = TRUE
    ))
  })
  
  
  
  
  #rec_save modal----
  observeEvent(input$rec_save, {
    
    records <- session$userData$records
    recgrp_id <- session$userData$recgrp_id
    species <- session$userData$species
    collex_id <- session$userData$collex_id
    
    req(records)
    req(recgrp_id)
    req(species)
    req(collex_id)
    
    #Get record group
    this_row <- records[records$recgroup_id == recgrp_id,]
    
    #Selected match
    the_feature <- session$userData$the_feature
    
    #Get uncertainty
    uncert_slider <- input$save_uncert
    
    uncert <- session$userData$uncert
    
    if (is.null(uncert_slider)){
      uncert_display <- paste0(prettyNum(uncert, big.mark = ",", scientific = FALSE), " m")
    }else{
      uncert <- uncert_slider
      if (uncert_slider == 0){
        uncert_display <- "NA"
      }else{
        uncert_display <- paste0(prettyNum(uncert_slider, big.mark = ",", scientific = FALSE), " m")
      }
    }
  
    
    lat_to_save <- the_feature$latitude
    lng_to_save <- the_feature$longitude
    data_source <- the_feature$layer
    located_at <- the_feature$located_at
    name <- this_row$locality
    
    showModal(modalDialog(
      size = "l",
      title = "Save match",
      fluidRow(
        column(width = 6,
               HTML("<div class=\"panel panel-primary\">
        <div class=\"panel-heading\">
        <h3 class=\"panel-title\">Record Group</h3>
        </div>
        <div class=\"panel-body\">"),
               HTML(paste0("<dl>
                      <dt>Locality</dt><dd>", this_row$locality, "</dd>
                      <dt>No. records</dt><dd>", this_row$no_records, "</dd>
                    ")),
               HTML(paste0("
                      <dt>Species</dt><dd><em>", this_row$species, "</em></dd>
                      <dt>Family</dt><dd>", this_row$family, "</dd>
                    </dl>")),
               
               HTML("</div></div>")
        ),
        column(width = 6,
               HTML("<div class=\"panel panel-success\">
        <div class=\"panel-heading\">
        <h3 class=\"panel-title\">Selected Match</h3>
          </div>
          <div class=\"panel-body\">
              <dl>
                  <dt>Name</dt><dd>", name, "</dd>
                  <dt>Located at</dt><dd>", located_at, "</dd>
                  <dt>Locality uncertainty (m)</dt><dd>", uncert_display, "</dd>
                  <dt>Source</dt><dd>", data_source, "</dd>
                  <dt>Lat/Lon</dt><dd>", lat_to_save, " / ", lng_to_save, "</dd>
                  <dt>Notes</dt><dd>", input$save_notes, "</dd>
              </dl>"
               ),
               
               HTML("</div></div>")
        )
      ),
      br(),
      p(actionButton("write_db", "Save locality for these records", class = "btn-primary")),
      easyClose = TRUE
    ))
  })
  
  
  
  
  #write_db modal----
  observeEvent(input$write_db, {
    records <- session$userData$records
    recgrp_id <- session$userData$recgrp_id
    species <- session$userData$species
    collex_id <- session$userData$collex_id
    candidate_id <- session$userData$candidate_id
      
    req(records)
    req(recgrp_id)
    req(species)
    req(collex_id)
    
    #Get record group
    #this_row <- records[records$recgroup_id == recgrp_id,]
    
    #Selected match
    the_feature <- session$userData$the_feature
    
    
    if (!is.null(input$map_click)){
      #Get uncertainty
      uncert <- input$uncert_slider
      
      p <- input$map_click
      
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
      
      if (is.null(uncert)){
        input_uncert <- input$save_uncert
      }else{
        input_uncert <- uncert
      }
      
      data_source <- 'custom'
      point_or_polygon <- 'point'
      candidate_id <- "00000000-0000-0000-0000-000000000000"
    }else{
      data_source <- the_feature$layer
      point_or_polygon <- the_feature$geom_type
      
    }
    
    
    
    #collex_id
    recgroup_id <- recgrp_id
    #candidate_id
    #data_source <- the_feature$layer
    #point_or_polygon <- the_feature$geom_type
    
    
    if (data_source == "gbif"){
      uncert <- the_feature$coordinateuncertaintyinmeters
      if (is.na(uncert)){
        uncertainty_m <- "NULL"
      }else{
        uncertainty_m <- uncert
      }
    }else{
      uncert <- the_feature$min_bound_radius_m
      if (is.null(uncert)){
        uncertainty_m <- "NULL"
      }else{
        uncertainty_m <- uncert
      }
    }
    
    
    
    if (is.null(input$save_notes)){
      notes <- "NULL"
    }else{
      notes <- paste0("'", input$save_notes, "'")
    }
    
    
    # #Connect to the database ----
    if (Sys.info()["nodename"] == "shiny.si.edu"){
      #For RHEL7 odbc driver
      pg_driver = "PostgreSQL"
    }else if (Sys.info()["nodename"] == "OCIO-2SJKVD22"){
      #For windows driver
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
    
    insert_query <- paste0("INSERT INTO mg_selected_candidates (collex_id, recgroup_id, candidate_id, data_source, point_or_polygon, uncertainty_m, notes) VALUES ('", collex_id, "', '", recgroup_id, "', '", candidate_id, "', '", data_source, "', '", point_or_polygon, "', ", uncertainty_m, ", ", notes, ")")
    dbSendQuery(db, insert_query)
    
    removeModal()
    output$main <- renderUI({
      HTML(paste0("<script>$(location).attr('href', './?collex_id=", collex_id, "&species=", species, "&prev=", recgrp_id, "')</script>"))
    })
    
  })
  
  
  
  # footer ----
  output$footer <- renderUI({
    HTML(paste0("<br><br><br><div class=\"footer navbar-fixed-bottom\"><br><p>&nbsp;&nbsp;<a href=\"http://dpo.si.edu\" target = _blank><img src=\"dpologo.jpg\"></a> | ", app_name, ", ver. ", app_ver, " | ", actionLink("help", label = "Help/Data Sources"), " | <a href=\"", github_link, "\" target = _blank>Source code</a></p></div>"))  
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