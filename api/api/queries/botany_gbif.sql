SELECT
    scientificName,
    species,
    locality,
    decimalLatitude,
    decimalLongitude,
    countryCode,
    stateProvince,
    county,
    municipality
FROM 
    gbif_plants_museums
WHERE 
    (scientificName ILIKE '%{sciname}%' OR species ILIKE '%{sciname}%')
    {country}    
LIMIT 1000
