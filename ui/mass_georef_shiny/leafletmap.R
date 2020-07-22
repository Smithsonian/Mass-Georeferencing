
leaflet_map <- function(species_map = TRUE, species_data = NULL, markers = FALSE, markers_data = NULL, candidate = FALSE, candidate_data = NULL, polygons = FALSE, polygons_data = NULL, query = NULL){
  #from https://gis.stackexchange.com/a/252992
  
  #print(species_data)
  if (is.null(species_data) == FALSE){
    y <- paste0('{\"type\":\"Feature\",\"properties\":{\"Species\": \"', species_data$type, ' of ', species_data$species, '\"},\"geometry\":', species_data$the_geom, '}')
    y2 <- paste(y, collapse=',')
    spp_geom <- paste0("{\"type\":\"FeatureCollection\",\"features\":[",y2,"]}")
    #print(spp_geom)
    
    spp_geom_bounds <- paste0("[
                        [", species_data$ymax, ", ", species_data$xmax, "],
                        [", species_data$ymin, ", ", species_data$xmin, "]
                    ]")
    
    #bounds
    xmin <- species_data$xmin
    ymin <- species_data$ymin
    xmax <- species_data$xmax
    ymax <- species_data$ymax
    
    #print(species_data)
    
    if (xmin == xmax || ymin == ymax){
      xmin <- xmin - 0.05
      xmax <- xmax + 0.05
      ymin <- ymin - 0.05
      ymax <- ymax + 0.05
    }
    
    #species_geom_layer <- paste0(species_data$type, ' of\n', species)
    species_geom_layer <- "Species Dist"
  }
  
  #Testing custom proj
  # custom_crs <- leafletCRS(crsClass = "L.Proj.CRS", 
  #                        proj4def = "+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m +no_defs"
  # )
  
  
  res <- leaflet(options = leafletOptions(zoomControl = FALSE)) %>%
    htmlwidgets::onRender("function(el, x) {
            L.control.zoom({ position: 'topright' }).addTo(this)
        }") %>%
    addProviderTiles(providers$OpenStreetMap.HOT, group = "OSM (default)") %>%
    addProviderTiles(providers$OpenTopoMap, group = "Topo") %>%
    addProviderTiles(providers$Esri.WorldStreetMap, group = "ESRI") %>%
    addProviderTiles(providers$Esri.WorldImagery, group = "ESRI Sat") %>%
    addMiniMap(tiles = providers$OpenStreetMap.HOT, toggleDisplay = TRUE, zoomLevelOffset = -6) %>%
    addScaleBar(position = "bottomleft") %>%
    addMeasure(primaryLengthUnit="kilometers", secondaryLengthUnit="miles", primaryAreaUnit = "sqkilometers", position = "topleft")
    
  
    if (species_map == TRUE & markers == FALSE & candidate == FALSE & polygons == FALSE){
      if (is.null(species_data) == FALSE){
        res <- res %>% 
          fitBounds(xmin, ymin, xmax, ymax) %>%
          # Layers control
          addLayersControl(
            baseGroups = c("OSM (default)", "Topo", "ESRI", "ESRI Sat"),
            overlayGroups = c(species_geom_layer),
            options = layersControlOptions(collapsed = FALSE)
          ) %>% 
          addGeoJSONv2(spp_geom, popupProperty='Species', color = "#36e265", opacity = 0.2, group = species_geom_layer) %>% 
          addEasyButton(easyButton(
            icon="fa-map", title="Zoom to Species Range",
            onClick=JS("function(btn, map){ map.fitBounds([", spp_geom_bounds, "]);}"))
          )
      }else{
        res <- res %>% 
          # Layers control
          addLayersControl(
            baseGroups = c("OSM (default)", "Topo", "ESRI", "ESRI Sat"),
            options = layersControlOptions(collapsed = FALSE)
          )
      }
    }else if (species_map == TRUE & markers == TRUE & candidate == FALSE & polygons == FALSE){
      #All candidates
      
      cand_coords <- SpatialPoints(coords = data.frame(lng = as.numeric(markers_data$longitude), lat = as.numeric(markers_data$latitude)), proj4string = CRS("+proj=longlat +datum=WGS84"))
      
      
      #print(query)
      species <- query['species']
      recgrp_id <- query['recgrp_id']
      collex_id <- query['collex_id']
      
      
      candidate_popup <- paste0(markers_data$name, "<br>Located at: ", markers_data$located_at, "<br>Source: ", markers_data$data_source, "<br>Uncertainty (m): ", prettyNum(markers_data$uncertainty_m, big.mark = ",", scientific = FALSE), "<br>Score: ", markers_data$score, "<br><small><a href=\"./?collex_id=", collex_id, "&species=", species, "&recgrp_id=", recgrp_id, "&candidate_id=", markers_data$candidate_id, "\">Select this locality</a></small>")
      
      marker_options <- markerOptions(
        zIndexOffset = 100
      )
      
      #coords <- SpatialPoints(coords = data.frame(lng = as.numeric(markers_data$longitude), lat = as.numeric(markers_data$latitude)), proj4string = CRS("+proj=longlat +datum=WGS84"))

      icons <- awesomeIcons(icon = "whatever",
                            iconColor = "red",
                            library = "ion")

      markers_geom_bounds <- paste0("[
                        [", max(markers_data$latitude), ", ", max(markers_data$longitude), "],
                        [", min(markers_data$latitude), ", ", min(markers_data$longitude), "]
                    ]")
      
      
      # print(108)
      # print(markers_data)
      
      res <- res %>% 
        addGeoJSONv2(spp_geom, popupProperty='Species', color = "#36e265", opacity = 0.8, group = species_geom_layer, fill = FALSE) %>%
        addLayersControl(
            baseGroups = c("OSM (default)", "Topo", "ESRI", "ESRI Sat"),
            overlayGroups = species_geom_layer,
            options = layersControlOptions(collapsed = FALSE)
          ) %>%
        addAwesomeMarkers(data = cand_coords, popup = candidate_popup, options = marker_options, clusterOptions = markerClusterOptions()) %>% 
        addEasyButton(easyButton(
          icon="fa-list", title="Zoom to Candidate Localities",
          onClick=JS("function(btn, map){ map.fitBounds([", markers_geom_bounds, "]);}"))
        )
        #fitBounds(min(as.numeric(markers_data$longitude)), min(as.numeric(markers_data$latitude)), max(as.numeric(markers_data$longitude)), max(as.numeric(markers_data$latitude))) %>% 
        #addAwesomeMarkers(data = coords, popup = markers_data$name, clusterOptions = markerClusterOptions()) %>% 
    }else if (species_map == TRUE & markers == FALSE & candidate == TRUE){
      #Selected candidate
      
      longitude <- candidate_data$longitude
      latitude <- candidate_data$latitude
      geom_type <- candidate_data$geom_type
      the_geom <- candidate_data$the_geom
      the_geom_extent <- candidate_data$the_geom_extent
      
      coords <- SpatialPoints(coords = data.frame(lng = as.numeric(longitude), lat = as.numeric(latitude)), proj4string = CRS("+proj=longlat +datum=WGS84"))

      res <- res %>% 
        addGeoJSONv2(spp_geom, popupProperty='Species', color = "#36e265", opacity = 0.8, group = species_geom_layer, fill = FALSE) %>%
        addLayersControl(
          baseGroups = c("OSM (default)", "Topo", "ESRI", "ESRI Sat"),
          overlayGroups = species_geom_layer,
          options = layersControlOptions(collapsed = FALSE)
        )
        
    }else if (markers == TRUE & candidate == TRUE){
      #Selected candidate and all others in grey
      cand_coords <- SpatialPoints(coords = data.frame(lng = as.numeric(candidate_data$longitude), lat = as.numeric(candidate_data$latitude)), proj4string = CRS("+proj=longlat +datum=WGS84"))
      
      marker_options <- markerOptions(
        zIndexOffset = 100
      )
      
      candidates_options <- markerOptions(
        opacity = 0.5
      )
      
      if(dim(markers_data)[1] > 0){
        coords <- SpatialPoints(coords = data.frame(lng = as.numeric(markers_data$longitude), lat = as.numeric(markers_data$latitude)), proj4string = CRS("+proj=longlat +datum=WGS84"))
        
        markers_geom_bounds <- paste0("[
                        [", max(markers_data$latitude), ", ", max(markers_data$longitude), "],
                        [", min(markers_data$latitude), ", ", min(markers_data$longitude), "]
                    ]")
      }
      
      icons <- awesomeIcons(icon = "map-pin",
                            markerColor = "gray",
                            library = "fa")
      
      uncert_layer <- "Uncertainty buffers<br>of candidates"
      
      api_req <- httr::POST(URLencode(paste0(api_url, "api/geom")),
                            body = list(uid = candidate_data$feature_id,
                                        layer = candidate_data$data_source,
                                        species = species_data$species),
                            httr::add_headers(
                              "X-Api-Key" = app_api_key
                            ),
                            encode = "form"
      )
      
      the_feature <- fromJSON(httr::content(api_req, as = "text", encoding = "UTF-8"), flatten = FALSE, simplifyVector = TRUE)
      
      if (the_feature$geom_type == "point"){
        #Candidate is point
        
        candidate_popup <- paste0(candidate_data$name, "<br>Located at: ", candidate_data$located_at, "<br>Source: ", candidate_data$data_source, "<br>Uncertainty (m): ", prettyNum(candidate_data$uncertainty_m, big.mark = ",", scientific = FALSE), "<br>Score: ", candidate_data$score)
        
        if (species_map == TRUE){
          res <- res %>% 
            addGeoJSONv2(spp_geom, popupProperty='Species', color = "#36e265", opacity = 0.8, group = species_geom_layer, fill = FALSE) %>% 
            addLayersControl(
              baseGroups = c("OSM (default)", "Topo", "ESRI", "ESRI Sat"),
              overlayGroups = c(species_geom_layer, uncert_layer),
              options = layersControlOptions(collapsed = FALSE)
            )
        }else{
          res <- res %>% 
            addLayersControl(
              baseGroups = c("OSM (default)", "Topo", "ESRI", "ESRI Sat"),
              overlayGroups = c(uncert_layer),
              options = layersControlOptions(collapsed = FALSE)
            )
        }
        
        res <- res %>%
          addAwesomeMarkers(data = cand_coords, popup = candidate_popup, options = marker_options) %>% 
          fitBounds(min(as.numeric(candidate_data$longitude)) - 0.05, min(as.numeric(candidate_data$latitude)) - 0.05, max(as.numeric(candidate_data$longitude)) + 0.05, max(as.numeric(candidate_data$latitude)) + 0.05) %>% 
          addCircles(lng = candidate_data$longitude, lat = candidate_data$latitude, weight = 1,
                     radius = candidate_data$uncertainty_m, popup = "Uncertainty of Candidate Locality",
                     fillOpacity = 0.2, 
                     group = uncert_layer
          )
        
        if(dim(markers_data)[1] > 0){
          res <- res %>% 
            addAwesomeMarkers(data = coords, popup = markers_data$link, icon = icons, options = candidates_options) %>%
            addCircles(lng = markers_data$longitude, lat = markers_data$latitude, weight = 1,
                       radius = markers_data$uncertainty_m, popup = paste0("Uncertainty of ", markers_data$name),
                       fillOpacity = 0.2, 
                       fillColor = "grey",
                       group = uncert_layer
            ) %>% 
            addEasyButton(easyButton(
              icon="fa-list", title="Zoom to Candidate Localities",
              onClick=JS("function(btn, map){ map.fitBounds([", markers_geom_bounds, "]);}"))
            ) #%>% 
        }
        
      }else{
        #Candidate is polygon
        
        print(the_feature)
        longitude <- the_feature$longitude
        latitude <- the_feature$latitude
        the_geom <- the_feature$the_geom
        the_geom_extent <- the_feature$the_geom_extent
        cand_coords <- SpatialPoints(coords = data.frame(lng = as.numeric(the_feature$longitude), lat = as.numeric(the_feature$latitude)), proj4string = CRS("+proj=longlat +datum=WGS84"))
        
        candidate_popup <- paste0("Centroid of: ", candidate_data$name, "<br>Located at: ", candidate_data$located_at, "<br>Source: ", candidate_data$data_source, "<br>Uncertainty (m): ", prettyNum(the_feature$min_bound_radius_m, big.mark = ",", scientific = FALSE), "<br>Score: ", candidate_data$score)
        
        sel_candidate_buf <- "Candidate Uncert"
        sel_candidate <- "Candidate Polygon"
        
        res <- res %>% 
          addGeoJSONv2(spp_geom, popupProperty='Species', color = "#36e265", opacity = 0.8, group = species_geom_layer, fill = FALSE) %>%
          addLayersControl(
            baseGroups = c("OSM (default)", "Topo", "ESRI", "ESRI Sat"),
            overlayGroups = c(species_geom_layer, uncert_layer, sel_candidate, sel_candidate_buf),
            options = layersControlOptions(collapsed = FALSE)
          ) %>%
          addAwesomeMarkers(data = cand_coords, popup = candidate_popup, options = marker_options) %>% 
          addGeoJSONv2(geojson = the_geom, color = "blue", opacity = 0.8, fill = TRUE, group = sel_candidate) %>%
          addCircles(lng = the_feature$longitude, lat = the_feature$latitude, weight = 1,
                     radius = the_feature$min_bound_radius_m, popup = paste0("Uncertainty of ", the_feature$name, "<br>(based on the area of the polygon)"),
                     fillOpacity = 0.2, 
                     fillColor = "yellow",
                     group = sel_candidate_buf
          ) %>% 
          addAwesomeMarkers(data = coords, popup = markers_data$link, icon = icons, options = candidates_options) %>%
          fitBounds(min(as.numeric(candidate_data$longitude)) - 0.05, min(as.numeric(candidate_data$latitude)) - 0.05, max(as.numeric(candidate_data$longitude)) + 0.05, max(as.numeric(candidate_data$latitude)) + 0.05) %>% 
          addEasyButton(easyButton(
            icon="fa-list", title="Zoom to Candidate Localities",
            onClick=JS("function(btn, map){ map.fitBounds([", markers_geom_bounds, "]);}"))
          ) %>% 
          addCircles(lng = markers_data$longitude, lat = markers_data$latitude, weight = 1,
                     radius = markers_data$uncertainty_m, popup = paste0("Uncertainty of ", markers_data$name),
                     fillOpacity = 0.2, 
                     fillColor = "grey",
                     group = uncert_layer
          )
      }
      
      
    }
  
  return(res)
}