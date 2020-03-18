SELECT 
    name_%(level)s as name,
    uid
FROM
    gadm%(level)s
WHERE
    name_%(parentlevel)s = %(parent)s
