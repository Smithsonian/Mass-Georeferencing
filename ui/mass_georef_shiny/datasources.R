#Countries from Wikidata
library(WikidataQueryServiceR)
library(dplyr)
library(stringr)

countries_query <- "SELECT ?item ?itemLabel 
                        WHERE {
                          ?item wdt:P31 wd:Q6256.
                          SERVICE wikibase:label { bd:serviceParam wikibase:language \"[AUTO_LANGUAGE],en\". }
                        }"

countries_wikidata <- WikidataQueryServiceR::query_wikidata(countries_query)

countries_wikidata <- countries_wikidata %>%
  mutate(code = str_replace(item, "http://www.wikidata.org/entity/", ""))

names(countries_wikidata) <- c('url', 'name', 'code')

save(file = "data/countries_wikidata.Rd", countries_wikidata)
