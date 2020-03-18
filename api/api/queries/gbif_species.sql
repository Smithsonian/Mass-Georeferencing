SELECT 
    max(gbifid) as gbifid,
    count(*) as no_records,
    decimallatitude, 
    decimallongitude, 
    countrycode, 
    locality,
    NULL as score
FROM 
    gbif 
WHERE 
    species = %(species)s
GROUP BY 
    decimallatitude, 
    decimallongitude, 
    countrycode, 
    locality
