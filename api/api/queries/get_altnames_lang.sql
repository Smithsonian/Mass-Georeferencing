SELECT 
    name
FROM
    wikidata_names
WHERE
    id IN (
        SELECT 
            id 
        FROM 
            wikidata_names
        WHERE 
            name = %(location_name)s
        ) AND
    language = %(lang)s