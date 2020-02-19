


countrycheck <- function(id, latitude, longitude, country, countryformat = "iso2c"){
  #Check if the coordinates match the country
  # country is in the format countryformat, using ?codelist from package countrycode
  # latitude and longitude are in decimal degrees
  
  if (is.na(latitude) || is.na(longitude) || is.na(country)){
    country_match <- NA
    latitude_match <- NA
    longitude_match <- NA
    note <- NA
  }else if (latitude == "" || longitude == "" || country == ""){
    country_match <- NA
    latitude_match <- NA
    longitude_match <- NA
    note <- NA
  }else if (latitude == 0 && longitude == 0){
    country_match <- NA
    latitude_match <- NA
    longitude_match <- NA
    note <- "Error: Latitude and Longitude are zero. This is, most probably, an error."
  }else{
    lng_dd <- longitude
    lat_dd <- latitude
    if (countryformat != "iso3c"){
      country_check <- countrycode(country, origin = countryformat, destination = "iso3c") 
    }
    
    country_query <- fromJSON(paste0('http://', api_host, '/api/', api_ver, '/gadm?lat=', lat_dd, '&lng=', lng_dd))
    if (!is.null(country_query$intersection$gadm0$name)){
      country_match <- countrycode(country_query$intersection$gadm0$name, origin = "country.name", destination = "iso3c") 
    }else{
      country_match <- NA
    }
    
    if (!is.na(country_match)){
      if (country_check == country_match){
        latitude_match <- lat_dd
        longitude_match <- lng_dd
        note <- 'Coordinates match'
      }else{
        country_match <- NA
      }
    }
    
    if (!exists("note")){
      country_query1 <- fromJSON(paste0('http://', api_host, '/api/', api_ver, '/gadm?lat=', -lat_dd, '&lng=', lng_dd))
      if (!is.null(country_query1$intersection)){
        country_match <- countrycode(country_query1$intersection$gadm0$name, origin = "country.name", destination = "iso3c") 
        if (!is.na(country_match)){
          if (country_check == country_match){
            note <- paste0('Latitude has the wrong sign, should be ', -lat_dd)
            latitude_match <- -lat_dd
            longitude_match <- lng_dd
          }
        }
      }
      
      if (!exists("note")){
        country_query1 <- fromJSON(paste0('http://', api_host, '/api/', api_ver, '/gadm?lat=', lat_dd, '&lng=', -lng_dd))
        if (!is.null(country_query1$intersection)){
          country_match <- countrycode(country_query1$intersection$gadm0$name, origin = "country.name", destination = "iso3c") 
          if (!is.na(country_match)){
            if (country_check == country_match){
              note <- paste0('Longitude has the wrong sign, should be ', -lng_dd)
              latitude_match <- lat_dd
              longitude_match <- lng_dd
            }
          }
        }
      }
      
      if (!exists("note")){
        country_query1 <- fromJSON(paste0('http://', api_host, '/api/', api_ver, '/gadm?lat=', -lat_dd, '&lng=', -lng_dd))
        if (!is.null(country_query1$intersection)){
          country_match <- countrycode(country_query1$intersection$gadm0$name, origin = "country.name", destination = "iso3c") 
          if (!is.na(country_match)){
            if (country_check == country_match){
              note <- paste0('Latitude and longitude have the wrong sign, Latitude should be ', -lat_dd, ' and Longitude should be ', -lng_dd)
              latitude_match <- -lat_dd
              longitude_match <- -lng_dd
            }
          }
        }
      }
      
      if (!exists("note")){
        country_query1 <- fromJSON(paste0('http://', api_host, '/api/', api_ver, '/country_nearest?rows=5&lat=', lat_dd, '&lng=', lng_dd))
        if (!is.null(country_query1$results)){
          
          w <- which(countrycode(country_query1$results$name, origin = "country.name", destination = "iso3c") == country_check)
          
          country_match <- countrycode(country_query1$results$name[w], origin = "country.name", destination = "iso3c")
          
          if (length(country_match) > 0){
            if (country_check == country_match){
              note <- paste0('Spatial error, distance from ', country, ': ', round(country_query1$results$distance_km[w], 2), 'km')
              latitude_match <- lat_dd
              longitude_match <- lng_dd
            }
          }
        }
      }
      
      if (!exists("note")){
        country_query <- fromJSON(paste0('http://', api_host, '/api/', api_ver, '/gadm?lat=', lat_dd, '&lng=', lng_dd))
        if (!is.null(country_query$intersection$gadm0$name)){
          country_match <- countrycode(country_query$intersection$gadm0$name, origin = "country.name", destination = "iso3c") 
          latitude_match <- lat_dd
          longitude_match <- lng_dd
          note <- paste0('Coordinates do not match ', country, ', they match ', country_match, ' (', countrycode(country_match, origin = "iso3c", destination = "country.name"), ')')
        }else{
          #nothing found
          country_match <- NA
          latitude_match <- NA
          longitude_match <- NA
          note <- paste('Coordinates do not match ', country)
        }
      }
    }
  }
  return(list(id = id, latitude = latitude, longitude = longitude, country = country, country_match = country_match, latitude_match = latitude_match, longitude_match = longitude_match, note = note))
}







wikidata_geo <- function(country, stateprovince, instance = NA){
  
  countries_query <- "SELECT ?item ?itemLabel 
                        WHERE {
                          ?item wdt:P31 wd:Q6256.
                          SERVICE wikibase:label { bd:serviceParam wikibase:language \"[AUTO_LANGUAGE],en\". }
                        }"
  
  countries_wikidata <- WikidataQueryServiceR::query_wikidata(countries_query)
  
  country_code <- str_replace(countries_wikidata[countries_wikidata$itemLabel == "United States of America",]$item, "http://www.wikidata.org/entity/", "")
  
  
    
  limit <- 10
  
  if (instance == "river"){
    instance_of_query <- "?item wdt:P31 wd:Q4022"
  }else{
    instance_of_query <- ""
  }
  
  query <- paste0("select ?item ?coords_ ?lon ?lat ?itemLabel where {
            ?item wdt:P17 wd:", country_code, " .
            ?item p:P625/psv:P625 ?coords .
            ?coords wikibase:geoLatitude ?lat ;
            wikibase:geoLongitude ?lon .
            
            SERVICE wikibase:label { bd:serviceParam wikibase:language
            \"[AUTO_LANGUAGE],en\". }",
            instance_of_query,
            "} limit ", limit)
  
  locations <- WikidataQueryServiceR::query_wikidata(query)
  
}


