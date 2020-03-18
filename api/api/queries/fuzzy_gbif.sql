SELECT 
    max(gbifid::bigint) as gbifid, 
    count(*) as no_records, 
    countrycode, 
    locality, 
    trim(leading ', ' from replace(municipality || ', ' || county || ', ' || stateprovince || ', ' || countrycode, ', , ', '')) as located_at, 
    stateprovince, 
    recordedBy,
    null as score
FROM 
    gbif 
WHERE 
    species = %(species)s AND
    countrycode = %(countrycode)s AND
    lower(locality) != 'unknown' 
GROUP BY 
    countrycode, 
    locality, 
    municipality, 
    county, 
    stateprovince, 
    recordedBy