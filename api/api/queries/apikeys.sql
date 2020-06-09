WITH keys AS (
      SELECT
        key,
        rate_limit,
        admin_user        
      FROM
        apikeys
      where
        key = %(apikey)s AND
        valid_key = 't'
    ),
    usage AS (
      SELECT
        key,
        COUNT(*) as no_queries
      FROM
        apikeys_usage
      WHERE
        key = %(apikey)s AND
        timestamp >= NOW() - INTERVAL '1 HOURS'
      GROUP BY key
    )
    SELECT
      k.rate_limit,
      k.admin_user,
      u.no_queries
    FROM
      keys k LEFT JOIN usage u ON (k.key = u.key)