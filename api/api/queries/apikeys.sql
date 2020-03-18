WITH keys AS (
      SELECT
        COUNT(*) as no_keys,
        max(rate_limit) as rate_limit
      FROM
        apikeys
      where
        key = %(apikey)s
    ),
    usage AS (
      SELECT
        COUNT(*) as no_queries
      FROM
        apikeys_usage
      WHERE
        key = %(apikey)s AND
        timestamp >= NOW() - INTERVAL '1 HOURS'
    )
    SELECT
      k.no_keys,
      k.rate_limit,
      u.no_queries
    FROM
      keys k,
      usage u