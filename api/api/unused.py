
#Parallel query edan
def query_edan(i, scientificname):
    df = []
    res = edan.searchEDAN(edan_query = scientificname, AppID = settings.AppID, AppKey = settings.AppKey, rows = 100, start = (i * 100))
    if len(res['rows']) > 0:
        for j in range(0, len(res['rows'])):
            try:
                for k in range(0, len(res['rows'][j]['content']['freetext']['place'])):
                    locality = res['rows'][j]['content']['freetext']['place'][k]['content'].encode('UTF-8')
                    if locality == "" or locality == None:
                        continue
                    else:
                        for s in range(0, len(res['rows'][j]['content']['indexedStructured']['scientific_name'])):
                            sciname = res['rows'][j]['content']['indexedStructured']['scientific_name'][s].encode('UTF-8')
                            if sciname == "" or sciname == None:
                                continue
                            else:
                                df.append((sciname, locality))
                                logging.info(cur.query)
                                conn.commit()
            except:
                continue
    return df




@app.route('/api/0.1/features_near')
def get_feat_near():
    """Returns the feature in layer that is closest to the coordinates provided."""
    #Check for valid API Key
    if apikey() == False:
        raise InvalidUsage('Unauthorized', status_code = 401)
    #Check inputs
    lat = request.args.get('lat')
    try:
        lat = float(lat)
    except:
        raise InvalidUsage('invalid lat value', status_code = 400)
    lng = request.args.get('lng')
    try:
        lng = float(lng)
    except:
        raise InvalidUsage('invalid lng value', status_code = 400)
    layer = request.args.get('layer')
    if layer == None:
        raise InvalidUsage('layer missing', status_code = 400)
    rows = request.args.get('rows')
    if rows != None:
        try:
            rows = int(rows)
        except:
            raise InvalidUsage('invalid rows value', status_code = 400)
    else:
        rows = 5
    #Connect to the database
    try:
        conn = psycopg2.connect(
                    host = settings.host,
                    database = settings.database,
                    user = settings.user,
                    password = settings.password)
    except psycopg2.Error as e:
        raise InvalidUsage('System error', status_code = 500)
    cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
    cur.execute("SELECT count(*) FROM data_sources WHERE datasource_id = %(layer)s", layer)
    valid_layer = cur.fetchone()[0]
    if valid_layer == 0:
        raise InvalidUsage('layer does not exists', status_code = 400)
    cur.execute("SELECT is_online FROM data_sources WHERE datasource_id = %(layer)s", layer)
    is_online = cur.fetchone()[0]
    if is_online == False:
        raise InvalidUsage('layer is offline for maintenance, please try again later', status_code = 503)
    #Query file
    with open('queries/feature_nearest.sql') as f:
        query_template = f.read()
    #Build query
    try:
        cur.execute(query_template, {'lat': lat, 'lng': lng, 'rows': rows, 'layer': layer})
    except:
        cur.execute("ROLLBACK")
        conn.commit()
    logging.info(cur.query)
    if cur.rowcount > 0:
        data = cur.fetchall()
    else:
        data = None
    cur.close()
    conn.close()
    results = {}
    results['results'] = data
    return jsonify(results)


@app.route('/api/0.1/fuzzysearch')
def search_fuzzy():
    """Search localities in the databases for matches using fuzzywuzzy."""
    #Check for valid API Key
    if apikey() == False:
        raise InvalidUsage('Unauthorized', status_code = 401)
    #Check inputs
    locality = request.args.get('locality')
    if locality == None:
        raise InvalidUsage('locality missing', status_code = 400)
    scientificname = request.args.get('scientificname')
    if scientificname == None:
        raise InvalidUsage('scientificname missing', status_code = 400)
    db = request.args.get('database')
    if db == None:
        raise InvalidUsage('database missing', status_code = 400)
    #check threshold and that it is an integer
    threshold = request.args.get('threshold')
    if threshold == None:
        threshold = 80
    try:
        int(threshold)
    except:
        raise InvalidUsage('invalid threshold value', status_code = 400)
    #How to match
    method = request.args.get('method')
    if method == None:
        method = "partial"
    countrycode = request.args.get('countrycode')
    if countrycode == None:
        raise InvalidUsage('countrycode missing', status_code = 400)
    #Connect to the database
    try:
        conn = psycopg2.connect(
                    host = settings.host,
                    database = settings.database,
                    user = settings.user,
                    password = settings.password)
    except psycopg2.Error as e:
        raise InvalidUsage('System error', status_code = 500)
    cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
    #Query file
    results = {}
    if db == 'gbif':
        with open('queries/fuzzy_gbif.sql') as f:
            query_template = f.read()
        #Build query
        cur.execute(query_template, {'species': scientificname, 'countrycode': countrycode})
    # elif db == '':
    #     with open('queries/fuzzy_gbif.sql') as f:
    #         query_template = f.read()
    #     #Build query
    #     cur.execute(query_template, {'species': scientificname, 'countrycode': countrycode})
    # elif db == '':
    #     with open('queries/fuzzy_gbif.sql') as f:
    #         query_template = f.read()
    #     #Build query
    #     cur.execute(query_template, {'species': scientificname, 'countrycode': countrycode})
    # elif db == '':
    #     with open('queries/fuzzy_gbif.sql') as f:
    #         query_template = f.read()
    #     #Build query
    #     cur.execute(query_template, {'species': scientificname, 'countrycode': countrycode})
    else:
        raise InvalidUsage('invalid database', status_code = 400)
    #Build query
    logging.info(cur.query)
    if cur.rowcount > 0:
        data = pd.DataFrame(cur.fetchall())
        for index, row in data.iterrows():
            if method == "ratio":
                data['score'][index] = fuzz.ratio(locality, row['locality'])
            elif method == "partial":
                data['score'][index] = fuzz.partial_ratio(locality, row['locality'])
            elif method == "set":
                data['score'][index] = fuzz.token_set_ratio(locality, row['locality'])
        data = data[data.score > threshold].to_json(orient='records')
    else:
        data = "[]"
    cur.close()
    conn.close()
    #return jsonify(data)
    return app.response_class(
        response=data,
        mimetype='application/json'
    )




@app.route('/api/0.1/nmnh/botany_localities_edan')
def get_localities_edan():
    """Get localities from GBIF for a species."""
    #Check for valid API Key
    if apikey() == False:
       raise InvalidUsage('Unauthorized', status_code = 401)
    #Check inputs
    scientificname = request.args.get('scientificname')
    if scientificname == None:
        raise InvalidUsage('scientificname missing', status_code = 400)
    try:
        conn = psycopg2.connect(
                    host = settings.host,
                    database = settings.database,
                    user = settings.user,
                    password = settings.password)
    except psycopg2.Error as e:
        raise InvalidUsage('System error', status_code = 500)
    cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
    #Delete rows older than 2 weeks
    cur.execute("DELETE FROM edan_localities WHERE updated_at < NOW() - interval '2 week'")
    logging.info(cur.query)
    conn.commit()
    #Check for results in the db already
    cur.execute("SELECT count(*) as no_rows FROM edan_localities WHERE sciname ILIKE '%%{}%%'".format(scientificname))
    logging.info(cur.query)
    no_rows = cur.fetchone()['no_rows']
    if no_rows == 0:
        #Check for how many results EDAN has
        logging.info("Checking EDAN")
        results = edan.searchEDAN(edan_query = scientificname, AppID = settings.AppID, AppKey = settings.AppKey, rows = 1)
        no_results = results['rowCount']
        results_steps = math.ceil(no_results / 100)
        pool = mp.Pool(settings.no_workers)
        result = pool.map(partial(query_edan, scientificname=scientificname), range(0, results_steps))
        #results = []
        for i in range(0, results_steps):
            for j in range(0, len(result[i])):
                #results.append(result[i][j])
                cur.execute("INSERT INTO edan_localities (sciname, locality) VALUES ('{}', '{}') ON CONFLICT (sciname, locality) DO UPDATE SET updated_at = NOW()".format(result[i][j][0].decode('UTF-8').replace("'", "''"), result[i][j][1].decode('UTF-8').replace("'", "''")))
                logging.info(cur.query)
                conn.commit()
        #return results.to_json(force_ascii = False, lines=False, orient='values')
    else:
        logging.info("Returning rows from database")
    cur.execute("SELECT sciname, locality FROM edan_localities WHERE sciname ILIKE '%%{}%%'".format(scientificname))
    logging.info(cur.query)
    results = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(results)




@app.route('/api/0.1/alt_names')
def get_altnames():
    """Check alternative names for a location."""
    #Check for valid API Key
    if apikey() == False:
        raise InvalidUsage('Unauthorized', status_code = 401)
    #Check inputs
    location_name = request.args.get('location_name')
    lang = request.args.get('lang')
    if location_name == None:
        raise InvalidUsage('location_name can not be empty.', status_code = 400)
    try:
        conn = psycopg2.connect(
                    host = settings.host,
                    database = settings.database,
                    user = settings.user,
                    password = settings.password)
    except psycopg2.Error as e:
        raise InvalidUsage('System error', status_code = 500)
    cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
    if lang == None:
        with open('queries/get_altnames.sql') as f:
            query_template = f.read()
        #Build query
        cur.execute(query_template, {'location_name': location_name})
    else:
        with open('queries/get_altnames_lang.sql') as f:
            query_template = f.read()
        #Build query
        cur.execute(query_template, {'location_name': location_name, 'lang': lang})
    logging.info(cur.query)
    data = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(data)



@app.route('/api/0.1/nmnh/botany_localities_gbif')
def get_localities_gbif():
    """Search localities in EDAN for a species."""
    #Check for valid API Key
    if apikey() == False:
       raise InvalidUsage('Unauthorized', status_code = 401)
    #Check inputs
    sciname = request.args.get('scientificname')
    country_code = request.args.get('country')
    if sciname == None:
        raise InvalidUsage('scientificname missing', status_code = 400)
    if country_code == None:
        country = ""
    else:
        country = "countryCode = '{}' AND".format(country_code)
    try:
        conn = psycopg2.connect(
                    host = settings.host,
                    database = settings.database,
                    user = settings.user,
                    password = settings.password)
    except psycopg2.Error as e:
        raise InvalidUsage('System error', status_code = 500)
    cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
    with open('queries/botany_gbif.sql') as f:
        query_template = f.read()
    #Build query
    cur.execute(query_template.format(sciname = sciname, country = country))
    logging.info(cur.query)
    data = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(data)

