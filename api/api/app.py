#!flask/bin/python
#
# Spatial API. Each route queries the PostGIS database.
#
from flask import Flask, jsonify, request
from flask import Response
from flask import render_template
from flask import send_file
import io
import simplejson as json
import psycopg2, os, operator, logging, sys, math, edan, locale
import psycopg2.extras
#import collections
from uuid import UUID
import numpy as np
import pandas as pd
#For parallel
import multiprocessing as mp
from functools import partial
from fuzzywuzzy import fuzz
from fuzzywuzzy import process


api_ver = "0.1"


#Log errors to apache error log
#logging.basicConfig(stream=sys.stderr)
logging.basicConfig(filename = 'api.log',
                level = logging.DEBUG,
                filemode='a',
                format='%(asctime)s %(name)-12s %(levelname)-8s %(message)s',
                datefmt='%y-%m-%d %H:%M:%S'
                )
# define a Handler which writes INFO messages or higher to the sys.stderr
console = logging.StreamHandler()
console.setLevel(logging.INFO)
# set a format which is simpler for console use
formatter = logging.Formatter('%(name)-12s: %(levelname)-8s %(message)s')
# tell the handler to use this format
console.setFormatter(formatter)
# add the handler to the root logger
logging.getLogger('').addHandler(console)


#Set locale for number format
locale.setlocale(locale.LC_ALL, 'en_US.UTF-8')


#Import settings
import settings


app = Flask(__name__)



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



#From http://flask.pocoo.org/docs/1.0/patterns/apierrors/
class InvalidUsage(Exception):
    status_code = 400
    def __init__(self, message, status_code = None, payload=None):
        Exception.__init__(self)
        self.message = message
        if status_code is not None:
            self.status_code = status_code
        self.payload = payload
    def to_dict(self):
        rv = dict(self.payload or ())
        rv['error'] = self.message
        return rv



@app.errorhandler(InvalidUsage)
def handle_invalid_usage(error):
    response = jsonify(error.to_dict())
    response.status_code = error.status_code
    return response



def apikey():
    headers = request.headers
    #Temp for dev
    if request.access_route[0] == settings.allow_ip:
        logging.info("Allowing IP " + request.access_route[0])
        return True
    if request.method == 'GET':
        auth = headers.get("X-Api-Key")
    else:
       auth = None 
    if auth == None:
        return False
    try:
        uid = UUID(auth, version=4)
    except: 
        raise InvalidUsage('Invalid key, it must be a valid UUID.', status_code = 400)
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
    #Query
    with open('queries/apikeys.sql') as f:
        query_template = f.read()
    #Build query
    logging.info(auth)
    cur.execute(query_template, {'apikey': auth})
    logging.info(cur.query)
    data = cur.fetchone()
    #Add counter
    referrer = headers.get("Referer")
    cur.execute("INSERT INTO apikeys_usage (key, referrer) VALUES (%(apikey)s, %(referrer)s)", {'apikey': auth, 'referrer': referrer})
    logging.info(cur.query)
    conn.commit()
    cur.close()
    conn.close()
    logging.info(headers)
    if data['no_keys'] == 1:
        if (data['rate_limit'] - data['no_queries']) < 0:
            raise InvalidUsage('Rate limit exceeded. Wait an hour or contact us to raise your limit', status_code = 429)
        else:
            return True
    else:
        return False



@app.route('/api/routes')
def routes_list():
    """Print available routes"""
    #Adapted from https://stackoverflow.com/a/17250154
    func_list = {}
    for rule in app.url_map.iter_rules():
        if rule.endpoint != 'static' and rule.rule != '/api/' and rule.rule != '/mdpp/previewimage':
            func_list[rule.rule] = app.view_functions[rule.endpoint].__doc__
    return jsonify(func_list)



@app.route('/api/')
@app.route('/api')
def index():
    """Welcome message and API versions available"""
    data = json.dumps({'current_version': api_ver, 'reference_url': "https://confluence.si.edu/display/DPOI/Spatial+database+and+API", 'api_title': "OCIO DPO PostGIS API"})
    return Response(data, mimetype='application/json')



@app.route('/')
def home():
    """Homepage in HTML format"""
    return render_template('home.html')



@app.route('/help')
def help():
    """Help page in HTML format"""
    return render_template('help.html')



@app.route('/api/0.1/feature')
def get_feat_info():
    """Returns the attributes of a feature."""
    #Check for valid API Key
    if apikey() == False:
        raise InvalidUsage('Unauthorized', status_code = 401)
    #Check inputs
    uid = request.args.get('uid')
    if uid == None:
        raise InvalidUsage('uid missing', status_code = 400)
    try:
        uid = UUID(uid, version = 4)
    except:
        raise InvalidUsage('uid is not a valid UUID', status_code = 400)
    layer = request.args.get('layer')
    if layer == None:
        raise InvalidUsage('layer missing', status_code = 400)
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
    #Check that layer is online
    cur.execute("SELECT count(*) FROM data_sources WHERE datasource_id = %(layer)s", {'layer': layer})
    valid_layer = cur.fetchone()
    if valid_layer == 0:
        raise InvalidUsage('layer does not exists', status_code = 400)
    cur.execute("SELECT is_online FROM data_sources WHERE datasource_id = %(layer)s", {'layer': layer})
    is_online = cur.fetchone()
    if is_online == False:
        raise InvalidUsage('layer is offline for maintenance, please try again later', status_code = 503)
    #Query file
    with open('queries/get_feature.sql') as f:
        query_template = f.read()
    #Build query
    #cur.execute(query_template.format(uid = uid, layer = layer, get_geometry = get_geometry))
    cur.execute(query_template.format(uid = uid, layer = layer))
    logging.info(cur.query)
    if cur.rowcount == 0:
        cur.close()
        conn.close()
        raise InvalidUsage('An area with this uid was not found', status_code = 400)
    else:
        data = cur.fetchone()
        cur.close()
        conn.close()
        return jsonify(data)




@app.route('/api/0.1/geom')
def get_geom():
    """Returns the geometry of a feature."""
    #Check for valid API Key
    if apikey() == False:
        raise InvalidUsage('Unauthorized', status_code = 401)
    #Check inputs
    uid = request.args.get('uid')
    if uid == None:
        raise InvalidUsage('uid missing', status_code = 400)
    try:
        uid = UUID(uid, version = 4)
    except:
        raise InvalidUsage('uid is not a valid UUID', status_code = 400)
    layer = request.args.get('layer')
    if layer == None:
        raise InvalidUsage('layer missing', status_code = 400)
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
    #Check that layer is online
    cur.execute("SELECT count(*) FROM data_sources WHERE datasource_id = %(layer)s", {'layer': layer})
    valid_layer = cur.fetchone()
    if valid_layer == 0:
        raise InvalidUsage('layer does not exists', status_code = 400)
    cur.execute("SELECT is_online FROM data_sources WHERE datasource_id = %(layer)s", {'layer': layer})
    is_online = cur.fetchone()
    if is_online == False:
        raise InvalidUsage('layer is offline for maintenance, please try again later', status_code = 503)
    #Query file
    #--using World Equidistant Cylindrical
    #   round((ST_MinimumBoundingRadius(st_transform(the_geom, '+proj=eqc +lat_ts=60 +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs '))).radius) as min_bound_radius_m
    with open('queries/get_geom.sql') as f:
        query_template = f.read()
    #Build query
    cur.execute(query_template.format(uid = uid, layer = layer))
    logging.info(cur.query)
    if cur.rowcount == 0:
        cur.close()
        conn.close()
        raise InvalidUsage('An area with this uid was not found', status_code = 400)
    else:
        data = cur.fetchone()
        cur.close()
        conn.close()
        return jsonify(data)



@app.route('/api/0.1/species_range')
def get_spprange():
    """Returns the range of a species. If there is no range, return the convex poly of GBIF points"""
    #Check for valid API Key
    if apikey() == False:
        raise InvalidUsage('Unauthorized', status_code = 401)
    #Check inputs
    species = request.args.get('scientificname')
    if species == None:
        raise InvalidUsage('scientificname missing', status_code = 400)
    range_type = request.args.get('type')
    if range_type == None:
        range_type = "all"
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
    #Get range
    if range_type == "any":
        with open('queries/get_speciesrange.sql') as f:
            query_template = f.read()
        #Build query
        cur.execute(query_template, {'species': species,})
        logging.info(cur.query)
        if cur.rowcount == 0:
            with open('queries/get_convexhull.sql') as f:
                query_template = f.read()
            #Build query
            cur.execute(query_template, {'species': species,})
            logging.info(cur.query)
            if cur.rowcount == 0:
                cur.close()
                conn.close()
                raise InvalidUsage('No data was found', status_code = 400)
            else:
                data = cur.fetchone()
                cur.close()
                conn.close()
                return jsonify(data)
        else:
            data = cur.fetchone()
            cur.close()
            conn.close()
            return jsonify(data)
    if range_type == "all":
        with open('queries/get_speciesrangeall.sql') as f:
            query_template = f.read()
        #Build query
        cur.execute(query_template, {'species': species,})
        logging.info(cur.query)
        if cur.rowcount == 0:
            cur.close()
            conn.close()
            raise InvalidUsage('No data was found', status_code = 400)
        else:
            data = cur.fetchone()
            cur.close()
            conn.close()
            return jsonify(data)



@app.route('/api/0.1/species_range_dist')
def get_spprange_dist():
    """Returns the distance to the edge the range of a species. If there is no range, use the convex poly of GBIF points"""
    #Check for valid API Key
    if apikey() == False:
        raise InvalidUsage('Unauthorized', status_code = 401)
    #Check inputs
    species = request.args.get('scientificname')
    if species == None:
        raise InvalidUsage('scientificname missing', status_code = 400)
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
    with open('queries/get_convexhull_dist.sql') as f:
        query_template = f.read()
    #Build query
    cur.execute(query_template, {'species': species, 'lng': lng, 'lat': lat})
    logging.info(cur.query)
    if cur.rowcount == 0:
        cur.close()
        conn.close()
        raise InvalidUsage('No data was found', status_code = 400)
    else:
        data = cur.fetchone()
        cur.close()
        conn.close()
        return jsonify(data)



@app.route('/api/0.1/intersection')
def get_wdpa():
    """Returns the uid of the feature that intersects the lat and lon given."""
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
    radius = request.args.get('radius')
    if radius != None:
        try:
            radius = int(radius)
        except:
            raise InvalidUsage('invalid radius value', status_code = 400)
    layer = request.args.get('layer')
    if layer == None:
        raise InvalidUsage('layer missing', status_code = 400)
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
    cur.execute("SELECT count(*) FROM data_sources WHERE datasource_id = %(layer)s", {'layer': layer})
    valid_layer = cur.fetchone()
    if valid_layer['count'] == 0:
        raise InvalidUsage('layer does not exists', status_code = 400)
    cur.execute("SELECT is_online FROM data_sources WHERE datasource_id = %(layer)s", {'layer': layer})
    is_online = cur.fetchone()
    if is_online['is_online'] == False:
        raise InvalidUsage('layer is offline for maintenance, please try again later', status_code = 503)
    #Query file
    if radius == None:
        with open('queries/intersection.sql') as f:
            query_template = f.read()
        #Build query
        try:
            cur.execute(query_template, {'lat': lat, 'lng': lng, 'layer': layer})
            logging.info(cur.query)
        except:
            vals = {'lat': lat, 'lng': lng, 'layer': layer}
            logging.error(query_template, extra = vals)
            cur.execute("ROLLBACK")
            conn.commit()
    else:
        with open('queries/intersection_radius.sql') as f:
            query_template = f.read()
        #Build query
        try:
            cur.execute(query_template, {'lat': lat, 'lng': lng, 'layer': layer, 'radius': radius})
            logging.info(cur.query)
        except:
            vals = {'lat': lat, 'lng': lng, 'layer': layer, 'radius': radius}
            logging.error(query_template, extra = vals)
            cur.execute("ROLLBACK")
            conn.commit()
    if cur.rowcount > 0:
        data = cur.fetchall()
    else:
        data = None
    cur.close()
    conn.close()
    results = {}
    results['intersection'] = data
    return jsonify(results)



# @app.route('/api/0.1/features_near')
# def get_feat_near():
#     """Returns the feature in layer that is closest to the coordinates provided."""
#     #Check for valid API Key
#     if apikey() == False:
#         raise InvalidUsage('Unauthorized', status_code = 401)
#     #Check inputs
#     lat = request.args.get('lat')
#     try:
#         lat = float(lat)
#     except:
#         raise InvalidUsage('invalid lat value', status_code = 400)
#     lng = request.args.get('lng')
#     try:
#         lng = float(lng)
#     except:
#         raise InvalidUsage('invalid lng value', status_code = 400)
#     layer = request.args.get('layer')
#     if layer == None:
#         raise InvalidUsage('layer missing', status_code = 400)
#     rows = request.args.get('rows')
#     if rows != None:
#         try:
#             rows = int(rows)
#         except:
#             raise InvalidUsage('invalid rows value', status_code = 400)
#     else:
#         rows = 5
#     #Connect to the database
#     try:
#         conn = psycopg2.connect(
#                     host = settings.host,
#                     database = settings.database,
#                     user = settings.user,
#                     password = settings.password)
#     except psycopg2.Error as e:
#         raise InvalidUsage('System error', status_code = 500)
#     cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
#     cur.execute("SELECT count(*) FROM data_sources WHERE datasource_id = %(layer)s", layer)
#     valid_layer = cur.fetchone()[0]
#     if valid_layer == 0:
#         raise InvalidUsage('layer does not exists', status_code = 400)
#     cur.execute("SELECT is_online FROM data_sources WHERE datasource_id = %(layer)s", layer)
#     is_online = cur.fetchone()[0]
#     if is_online == False:
#         raise InvalidUsage('layer is offline for maintenance, please try again later', status_code = 503)
#     #Query file
#     with open('queries/feature_nearest.sql') as f:
#         query_template = f.read()
#     #Build query
#     try:
#         cur.execute(query_template, {'lat': lat, 'lng': lng, 'rows': rows, 'layer': layer})
#     except:
#         cur.execute("ROLLBACK")
#         conn.commit()
#     logging.info(cur.query)
#     if cur.rowcount > 0:
#         data = cur.fetchall()
#     else:
#         data = None
#     cur.close()
#     conn.close()
#     results = {}
#     results['results'] = data
#     return jsonify(results)



@app.route('/api/0.1/all_names')
def get_gadm_names():
    """Returns all names from the specified layer."""
    #Check for valid API Key
    if apikey() == False:
        raise InvalidUsage('Unauthorized', status_code = 401)
    #Check inputs
    layer = request.args.get('layer')
    if layer == None:
        raise InvalidUsage('layer missing', status_code = 400)
    if layer not in ['gadm0', 'gadm1', 'gadm2', 'gadm3', 'gadm4', 'gadm5', 'wdpa_polygons', 'wdpa_points']:
        raise InvalidUsage('layer not availabe for this route', status_code = 400)
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
    results = {}
    #Query file
    if layer in ['gadm0', 'gadm1', 'gadm2', 'gadm3', 'gadm4', 'gadm5']:
        cur.execute("SELECT is_online FROM data_sources WHERE datasource_id = 'gadm'")
        is_online = cur.fetchone()
        if is_online == False:
            raise InvalidUsage('layer is offline for maintenance, please try again later', status_code = 503)
        with open('queries/gadm_list_names.sql') as f:
            query_template = f.read()
        #Build query
        cur.execute(query_template.format(level = layer.replace('gadm', '')))
    if layer in ['wdpa_polygons', 'wdpa_points']:
        cur.execute("SELECT is_online FROM data_sources WHERE datasource_id = %(layer_id)s", {'layer_id': layer})
        is_online = cur.fetchone()
        if is_online == False:
            raise InvalidUsage('layer is offline for maintenance, please try again later', status_code = 503)
        with open('queries/wdpa_list_names.sql') as f:
            query_template = f.read()
        #Build query
        cur.execute(query_template.format(layer = layer))        
    logging.info(cur.query)
    if cur.rowcount > 0:
        data = cur.fetchall()
    else:
        data = None
    cur.close()
    conn.close()
    results['results'] = data
    return jsonify(results)



@app.route('/api/0.1/search')
def search_names():
    """Search names in the databases for matches. Search is case insensitive."""
    #Check for valid API Key
    if apikey() == False:
        raise InvalidUsage('Unauthorized', status_code = 401)
    #Check inputs
    string = request.args.get('string')
    if string == None:
        raise InvalidUsage('string missing', status_code = 400)
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
    results = {}
    #Query file
    with open('queries/search.sql') as f:
        query_template = f.read()
    #Build query
    cur.execute(query_template, {'string': string})
    logging.info(cur.query)
    if cur.rowcount > 0:
        data = cur.fetchall()
    else:
        data = None
    cur.close()
    conn.close()
    results['results'] = data
    return jsonify(results)



# @app.route('/api/0.1/fuzzysearch')
# def search_fuzzy():
#     """Search localities in the databases for matches using fuzzywuzzy."""
#     #Check for valid API Key
#     if apikey() == False:
#         raise InvalidUsage('Unauthorized', status_code = 401)
#     #Check inputs
#     locality = request.args.get('locality')
#     if locality == None:
#         raise InvalidUsage('locality missing', status_code = 400)
#     scientificname = request.args.get('scientificname')
#     if scientificname == None:
#         raise InvalidUsage('scientificname missing', status_code = 400)
#     db = request.args.get('database')
#     if db == None:
#         raise InvalidUsage('database missing', status_code = 400)
#     #check threshold and that it is an integer
#     threshold = request.args.get('threshold')
#     if threshold == None:
#         threshold = 80
#     try:
#         int(threshold)
#     except:
#         raise InvalidUsage('invalid threshold value', status_code = 400)
#     #How to match
#     method = request.args.get('method')
#     if method == None:
#         method = "partial"
#     countrycode = request.args.get('countrycode')
#     if countrycode == None:
#         raise InvalidUsage('countrycode missing', status_code = 400)
#     #Connect to the database
#     try:
#         conn = psycopg2.connect(
#                     host = settings.host,
#                     database = settings.database,
#                     user = settings.user,
#                     password = settings.password)
#     except psycopg2.Error as e:
#         raise InvalidUsage('System error', status_code = 500)
#     cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
#     #Query file
#     results = {}
#     if db == 'gbif':
#         with open('queries/fuzzy_gbif.sql') as f:
#             query_template = f.read()
#         #Build query
#         cur.execute(query_template, {'species': scientificname, 'countrycode': countrycode})
#     # elif db == '':
#     #     with open('queries/fuzzy_gbif.sql') as f:
#     #         query_template = f.read()
#     #     #Build query
#     #     cur.execute(query_template, {'species': scientificname, 'countrycode': countrycode})
#     # elif db == '':
#     #     with open('queries/fuzzy_gbif.sql') as f:
#     #         query_template = f.read()
#     #     #Build query
#     #     cur.execute(query_template, {'species': scientificname, 'countrycode': countrycode})
#     # elif db == '':
#     #     with open('queries/fuzzy_gbif.sql') as f:
#     #         query_template = f.read()
#     #     #Build query
#     #     cur.execute(query_template, {'species': scientificname, 'countrycode': countrycode})
#     else:
#         raise InvalidUsage('invalid database', status_code = 400)
#     #Build query
#     logging.info(cur.query)
#     if cur.rowcount > 0:
#         data = pd.DataFrame(cur.fetchall())
#         for index, row in data.iterrows():
#             if method == "ratio":
#                 data['score'][index] = fuzz.ratio(locality, row['locality'])
#             elif method == "partial":
#                 data['score'][index] = fuzz.partial_ratio(locality, row['locality'])
#             elif method == "set":
#                 data['score'][index] = fuzz.token_set_ratio(locality, row['locality'])
#         data = data[data.score > threshold].to_json(orient='records')
#     else:
#         data = "[]"
#     cur.close()
#     conn.close()
#     #return jsonify(data)
#     return app.response_class(
#         response=data,
#         mimetype='application/json'
#     )



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



# @app.route('/api/0.1/alt_names')
# def get_altnames():
#     """Check alternative names for a location."""
#     #Check for valid API Key
#     if apikey() == False:
#         raise InvalidUsage('Unauthorized', status_code = 401)
#     #Check inputs
#     location_name = request.args.get('location_name')
#     lang = request.args.get('lang')
#     if location_name == None:
#         raise InvalidUsage('location_name can not be empty.', status_code = 400)
#     try:
#         conn = psycopg2.connect(
#                     host = settings.host,
#                     database = settings.database,
#                     user = settings.user,
#                     password = settings.password)
#     except psycopg2.Error as e:
#         raise InvalidUsage('System error', status_code = 500)
#     cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
#     if lang == None:
#         with open('queries/get_altnames.sql') as f:
#             query_template = f.read()
#         #Build query
#         cur.execute(query_template, {'location_name': location_name})
#     else:
#         with open('queries/get_altnames_lang.sql') as f:
#             query_template = f.read()
#         #Build query
#         cur.execute(query_template, {'location_name': location_name, 'lang': lang})
#     logging.info(cur.query)
#     data = cur.fetchall()
#     cur.close()
#     conn.close()
#     return jsonify(data)



@app.route('/api/0.1/data_sources')
def get_sources():
    """Get the details of the data sources in JSON."""
    #API Key not needed
    try:
        conn = psycopg2.connect(
                    host = settings.host,
                    database = settings.database,
                    user = settings.user,
                    password = settings.password)
    except psycopg2.Error as e:
        raise InvalidUsage('System error', status_code = 500)
    cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
    #Build query
    cur.execute("SELECT * FROM data_sources")
    logging.info(cur.query)
    data = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(data)



@app.route('/data_sources')
def get_sources_html():
    """Get the details of the data sources in HTML format."""
    #API Key not needed
    try:
        conn = psycopg2.connect(
                    host = settings.host,
                    database = settings.database,
                    user = settings.user,
                    password = settings.password)
    except psycopg2.Error as e:
        raise InvalidUsage('System error', status_code = 500)
    cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
    #Build query
    cur.execute("SELECT *, TO_CHAR(no_features, '999,999,999,999') as no_feat, TO_CHAR(source_date::date, 'dd Mon yyyy') as date_f FROM data_sources ORDER BY datasource_id ASC")
    logging.info(cur.query)
    data = cur.fetchall()
    summary = sum(row['no_features'] for row in data)
    summary = locale.format("%d", summary, grouping=True)
    cur.close()
    conn.close()
    results = {}
    results = data
    return render_template('data_sources.html', data = results, summary = summary)



@app.route('/mdpp/previewimage')
def get_preview():
    """Return image previews from Mass Digi Projects."""
    file_id = request.args.get('file_id')
    if file_id == None:
        raise InvalidUsage('file_id missing', status_code = 400)
    filefolder = str(file_id)[0:2]
    filename = "static/mdpp_previews/{}/{}.jpg".format(filefolder, file_id)
    if os.path.isfile(filename) == False:
        filename = "static/na.jpg"
    return send_file(filename, mimetype='image/jpeg')



@app.errorhandler(404)
def page_not_found(e):
    logging.error(e)
    data = json.dumps({'error': "route not found"})
    return Response(data, mimetype='application/json'), 404



@app.errorhandler(500)
def page_not_found(e):
    logging.error(e)
    data = json.dumps({'error': "system error"})
    return Response(data, mimetype='application/json'), 500



if __name__ == '__main__':
    app.run(debug = True)
