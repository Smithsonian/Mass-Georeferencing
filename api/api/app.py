#!flask/bin/python
#
# Spatial API. Each route queries the PostGIS database.
#
from flask import Flask, jsonify, request
from flask import Response
from flask import render_template
from flask import send_file
from flask import redirect, request, current_app
import simplejson as json
import psycopg2, os, logging, sys, math, locale
import psycopg2.extras
from uuid import UUID
#For parallel
import multiprocessing as mp
from functools import partial
from functools import wraps
import re
from PIL import Image


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



def apikey(admin = False):
    headers = request.headers
    #Temp for dev
    if request.access_route[0] == settings.allow_ip:
        logging.info("Allowing IP " + request.access_route[0])
        return True
    if request.method == 'POST':
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
        conn = psycopg2.connect(host = settings.host, database = settings.database, user = settings.user, password = settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code = 500)
    cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
    #Query
    with open('queries/apikeys.sql') as f:
        query_template = f.read()
    #Build query
    logging.info(auth)
    cur.execute(query_template, {'apikey': auth})
    logging.debug(cur.query)
    if cur.rowcount != 1:
        #Could not find key or is no longer valid
        return False
    else:
        data = cur.fetchone()
        #Add counter
        referrer = headers.get("Referer")
        cur.execute("INSERT INTO apikeys_usage (key, referrer) VALUES (%(apikey)s, %(referrer)s)", {'apikey': auth, 'referrer': referrer})
        logging.debug(cur.query)
        conn.commit()
        cur.close()
        conn.close()
        logging.info(headers)
        if admin == True:
            if data['admin_user'] == True:
                return True
            else:
                return False
        else:
            if (data['rate_limit'] - data['no_queries']) < 0:
                raise InvalidUsage('Rate limit exceeded. Wait an hour or contact us to raise your limit', status_code = 429)
            else:
                return True



@app.route('/api/routes', methods = ['GET', 'POST'])
def routes_list():
    """Print available routes"""
    #Adapted from https://stackoverflow.com/a/17250154
    func_list = {}
    for rule in app.url_map.iter_rules():
        if rule.endpoint != 'static' and rule.rule != '/api/' and rule.rule != '/mdpp/previewimage' and rule.rule[0:4] != '/mg/' and rule.rule[0:4] != '/dl/':
            func_list[rule.rule] = app.view_functions[rule.endpoint].__doc__
    return jsonify(func_list)



@app.route('/api/', methods = ['GET', 'POST'])
@app.route('/api', methods = ['GET', 'POST'])
def index():
    """Welcome message and API versions available"""
    data = json.dumps({'current_version': api_ver, 'reference_url': "https://sinet.sharepoint.com/sites/DPO/SitePages/Spatial-Database.aspx", 'api_title': "OCIO DPO PostGIS API"})
    return Response(data, mimetype='application/json')



@app.route('/', methods = ['GET', 'POST'])
def home():
    """Homepage in HTML format"""
    return render_template('home.html')



@app.route('/help', methods = ['GET', 'POST'])
def help():
    """Help page in HTML format"""
    return render_template('help.html')



@app.route('/data_sources', methods = ['GET', 'POST'])
def get_sources_html():
    """Get the details of the data sources in HTML format."""
    #API Key not needed
    try:
        conn = psycopg2.connect(host = settings.host, database = settings.database, user = settings.user, password = settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code = 500)
    cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
    #Check inputs
    datasource_id = request.values.get('datasource_id')
    logging.debug(datasource_id)
    if datasource_id == None:
        #Build query
        cur.execute("SELECT *, TO_CHAR(no_features, '999,999,999,999') as no_feat, TO_CHAR(source_date::date, 'dd Mon yyyy') as date_f FROM data_sources WHERE is_online = 't' ORDER BY datasource_id ASC")
        logging.debug(cur.query)
        data = cur.fetchall()
        summary = sum(row['no_features'] for row in data)
        summary = locale.format("%d", summary, grouping=True)
    else:
        cur.execute("SELECT *, TO_CHAR(no_features, '999,999,999,999') as no_feat, TO_CHAR(source_date::date, 'dd Mon yyyy') as date_f FROM data_sources WHERE is_online = 't' AND datasource_id = %(datasource_id)s", {'datasource_id': datasource_id})
        logging.debug(cur.query)
        data = cur.fetchall()
        summary = None
    cur.close()
    conn.close()
    results = {}
    results = data
    return render_template('data_sources.html', data = results, summary = summary)




@app.route('/details', methods = ['GET', 'POST'])
def get_details_html():
    """Get the details of the row from a data source in HTML format."""
    #API Key not needed
    try:
        conn = psycopg2.connect(host = settings.host, database = settings.database, user = settings.user, password = settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code = 500)
    cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
    #Check inputs
    datasource_id = request.values.get('datasource_id')
    speciessource = request.values.get('speciessource')
    if datasource_id == None and speciessource == None:
        raise InvalidUsage('datasource_id and speciessource missing', status_code = 400)
    uid = request.values.get('id')
    if uid == None:
        raise InvalidUsage('id missing', status_code = 400)
    if datasource_id != None:
        logging.debug(datasource_id)
        cur.execute("SELECT * FROM data_sources WHERE datasource_id = %(datasource_id)s", {'datasource_id': datasource_id})
        logging.debug(cur.query)
        datasource = cur.fetchone()
        cur.execute("SELECT %(datasource)s as data_source, * FROM {} WHERE uid = %(uid)s".format(datasource_id), {'uid': uid, 'datasource': "{} ({})".format(datasource['source_title'], datasource['source_url'])})
        data = cur.fetchone()
    elif speciessource != None:
        logging.debug(speciessource)
        if speciessource == "gbiftaxonomy":
            cur.execute("SELECT * FROM gbif_vernacularnames WHERE taxonID = %(uid)s", {'uid': uid})
            logging.debug(cur.query)
            data = cur.fetchone()
    logging.info(cur.query)
    cur.close()
    conn.close()
    return render_template('details.html', data = data)




@app.route('/api/geom', methods = ['POST'])
def get_geom():
    """Returns the geometry of a feature."""
    #Check for valid API Key
    if apikey() == False:
        raise InvalidUsage('Unauthorized', status_code = 401)
    #Check inputs
    uid = request.values.get('uid')
    if uid == None:
        raise InvalidUsage('uid missing', status_code = 400)
    layer = request.values.get('layer')
    if layer == None:
        raise InvalidUsage('layer missing', status_code = 400)
    if layer[:4] != "gbif":
        try:
            uid = UUID(uid, version = 4)
        except:
            raise InvalidUsage('uid is not a valid UUID', status_code = 400)
    else:
        species = request.values.get('species')
        if species == None:
            raise InvalidUsage('species missing', status_code = 400)
    #Connect to the database
    try:
        conn = psycopg2.connect(host = settings.host, database = settings.database, user = settings.user, password = settings.password)
    except psycopg2.Error as e:
        logging.error(e)
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
    if layer[:4] == "gbif":
        with open('queries/get_geom/gbif.sql') as f:
            query_template = f.read()
        #Build query
        cur.execute(query_template.format(uid = uid, species = species, genus = species.split(' ')[0]))
    else:
        with open('queries/get_geom/{}.sql'.format(layer)) as f:
            query_template = f.read()
        #Build query
        cur.execute(query_template.format(uid = uid))
    logging.debug(cur.query)
    if cur.rowcount == 0:
        cur.close()
        conn.close()
        raise InvalidUsage('An area with this uid was not found', status_code = 400)
    else:
        data = cur.fetchone()
        cur.close()
        conn.close()
        return jsonify(data)



@app.route('/api/feature', methods = ['POST'])
def get_feat_info():
    """Returns the attributes of a feature."""
    #Check for valid API Key
    if apikey() == False:
        raise InvalidUsage('Unauthorized', status_code = 401)
    #Check inputs
    uid = request.values.get('uid')
    if uid == None:
        raise InvalidUsage('uid missing', status_code = 400)
    try:
        uid = UUID(uid, version = 4)
    except:
        raise InvalidUsage('uid is not a valid UUID', status_code = 400)
    layer = request.values.get('layer')
    if layer == None:
        raise InvalidUsage('layer missing', status_code = 400)
    #Connect to the database
    try:
        conn = psycopg2.connect(host = settings.host, database = settings.database, user = settings.user, password = settings.password)
    except psycopg2.Error as e:
        logging.error(e)
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
    with open('queries/get_feature/{}.sql'.format(layer)) as f:
        query_template = f.read()
    #Build query
    cur.execute(query_template.format(uid = uid))
    logging.debug(cur.query)
    if cur.rowcount == 0:
        cur.close()
        conn.close()
        raise InvalidUsage('An area with this uid was not found', status_code = 400)
    else:
        data = cur.fetchone()
        cur.close()
        conn.close()
        return jsonify(data)




@app.route('/api/species_range', methods = ['POST'])
def get_spprange():
    """Returns the range of a species. If there is no range, return the convex poly of GBIF points"""
    #Check for valid API Key
    if apikey() == False:
        raise InvalidUsage('Unauthorized', status_code = 401)
    #Check inputs
    species = request.values.get('scientificname')
    if species == None:
        raise InvalidUsage('scientificname missing', status_code = 400)
    range_type = request.values.get('type')
    if range_type == None:
        range_type = "all"
    #Connect to the database
    try:
        conn = psycopg2.connect(host = settings.host, database = settings.database, user = settings.user, password = settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code = 500)
    cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
    #Query file
    #Get range
    if range_type == "any":
        with open('queries/get_speciesrange.sql') as f:
            query_template = f.read()
        #Build query
        cur.execute(query_template, {'species': species,})
        logging.debug(cur.query)
        if cur.rowcount == 0:
            with open('queries/get_convexhull.sql') as f:
                query_template = f.read()
            #Build query
            cur.execute(query_template, {'species': species,})
            logging.debug(cur.query)
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
        logging.debug(cur.query)
        if cur.rowcount == 0:
            cur.close()
            conn.close()
            raise InvalidUsage('No data was found', status_code = 400)
        else:
            data = cur.fetchone()
            cur.close()
            conn.close()
            return jsonify(data)



@app.route('/api/species_range_dist', methods = ['POST'])
def get_spprange_dist():
    """Returns the distance to the edge the range of a species. If there is no range, use the convex poly of GBIF points"""
    #Check for valid API Key
    if apikey() == False:
        raise InvalidUsage('Unauthorized', status_code = 401)
    #Check inputs
    species = request.values.get('scientificname')
    if species == None:
        raise InvalidUsage('scientificname missing', status_code = 400)
    lat = request.values.get('lat')
    try:
        lat = float(lat)
    except:
        raise InvalidUsage('invalid lat value', status_code = 400)
    lng = request.values.get('lng')
    try:
        lng = float(lng)
    except:
        raise InvalidUsage('invalid lng value', status_code = 400)
    #Connect to the database
    try:
        conn = psycopg2.connect(host = settings.host, database = settings.database, user = settings.user, password = settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code = 500)
    cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
    #Query file
    with open('queries/get_convexhull_dist.sql') as f:
        query_template = f.read()
    #Build query
    cur.execute(query_template, {'species': species, 'lng': lng, 'lat': lat})
    logging.debug(cur.query)
    if cur.rowcount == 0:
        cur.close()
        conn.close()
        raise InvalidUsage('No data was found', status_code = 400)
    else:
        data = cur.fetchone()
        cur.close()
        conn.close()
        return jsonify(data)



@app.route('/api/intersection', methods = ['POST'])
def get_wdpa():
    """Returns the uid of the feature that intersects the lat and lon given."""
    #Check for valid API Key
    if apikey() == False:
        raise InvalidUsage('Unauthorized', status_code = 401)
    #Check inputs
    lat = request.values.get('lat')
    try:
        lat = float(lat)
    except:
        raise InvalidUsage('invalid lat value', status_code = 400)
    lng = request.values.get('lng')
    try:
        lng = float(lng)
    except:
        raise InvalidUsage('invalid lng value', status_code = 400)
    radius = request.values.get('radius')
    if radius != None:
        try:
            radius = int(radius)
        except:
            raise InvalidUsage('invalid radius value', status_code = 400)
    layer = request.values.get('layer')
    if layer == None:
        raise InvalidUsage('layer missing', status_code = 400)
    #Connect to the database
    try:
        conn = psycopg2.connect(host = settings.host, database = settings.database, user = settings.user, password = settings.password)
    except psycopg2.Error as e:
        logging.error(e)
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
            logging.debug(cur.query)
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
            cur.execute(query_template, {'lat': lat, 'lng': lng, 'layer': layer})
            logging.debug(cur.query)
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




@app.route('/api/historical_int', methods = ['POST'])
def get_history():
    """Returns the historical locality that matches the coords and the year."""
    #Check for valid API Key
    if apikey() == False:
        raise InvalidUsage('Unauthorized', status_code = 401)
    #Check inputs
    lat = request.values.get('lat')
    try:
        lat = float(lat)
    except:
        raise InvalidUsage('invalid lat value', status_code = 400)
    lng = request.values.get('lng')
    try:
        lng = float(lng)
    except:
        raise InvalidUsage('invalid lng value', status_code = 400)
    year = request.values.get('year')
    if year == None:
        raise InvalidUsage('year missing', status_code = 400)
    try:
        year = int(year)
    except:
        raise InvalidUsage('invalid year value', status_code = 400)
    radius = request.values.get('radius')
    if radius == None:
        radius = 2500
    else:
        try:
            radius = int(radius)
        except:
            raise InvalidUsage('invalid radius value', status_code = 400)
    layer = request.values.get('layer')
    if layer == None:
        raise InvalidUsage('layer missing', status_code = 400)
    #Connect to the database
    try:
        conn = psycopg2.connect(host = settings.host, database = settings.database, user = settings.user, password = settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code = 500)
    cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
    cur.execute("SELECT count(*) FROM data_sources WHERE datasource_id = %(layer)s", {'layer': layer})
    valid_layer = cur.fetchone()
    logging.info(cur.query)
    if valid_layer['count'] == 0:
        raise InvalidUsage('layer does not exists', status_code = 400)
    cur.execute("SELECT is_online FROM data_sources WHERE datasource_id = %(layer)s", {'layer': layer})
    is_online = cur.fetchone()
    logging.info(cur.query)
    if is_online['is_online'] == False:
        raise InvalidUsage('layer is offline for maintenance, please try again later', status_code = 503)
    #Query file
    with open('queries/hist_intersection_radius.sql') as f:
        query_template = f.read()
    #Build query
    try:
        cur.execute(query_template, {'lat': lat, 'lng': lng, 'layer': layer, 'radius': radius, 'year': year})
        logging.debug(cur.query)
    except:
        vals = {'lat': lat, 'lng': lng, 'layer': layer, 'radius': radius, 'year': year}
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



@app.route('/api/all_names', methods = ['POST'])
def get_gadm_names():
    """Returns all names from the specified layer."""
    #Check for valid API Key
    if apikey() == False:
        raise InvalidUsage('Unauthorized', status_code = 401)
    #Check inputs
    layer = request.values.get('layer')
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
        logging.error(e)
        raise InvalidUsage('System error', status_code = 500)
    cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
    results = {}
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
    if layer in ['gadm0', 'gadm1', 'gadm2', 'gadm3', 'gadm4', 'gadm5']:
        with open('queries/gadm_list_names.sql') as f:
            query_template = f.read()
        #Build query
        cur.execute(query_template.format(level = layer.replace('gadm', '')))
    if layer in ['wdpa_polygons', 'wdpa_points']:
        with open('queries/wdpa_list_names.sql') as f:
            query_template = f.read()
        #Build query
        cur.execute(query_template.format(layer = layer))
    logging.debug(cur.query)
    if cur.rowcount > 0:
        data = cur.fetchall()
    else:
        data = None
    cur.close()
    conn.close()
    results['results'] = data
    return jsonify(results)



@app.route('/api/search', methods = ['POST'])
def search_names():
    """Search names in the databases for matches. Search is case insensitive."""
    #Check for valid API Key
    if apikey() == False:
        raise InvalidUsage('Unauthorized', status_code = 401)
    #Check inputs
    string = request.values.get('string')
    if string == None:
        raise InvalidUsage('string missing', status_code = 400)
    #Connect to the database
    try:
        conn = psycopg2.connect(host = settings.host, database = settings.database, user = settings.user, password = settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code = 500)
    cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
    results = {}
    #Query file
    with open('queries/search.sql') as f:
        query_template = f.read()
    #Build query
    cur.execute(query_template, {'string': string})
    logging.debug(cur.query)
    if cur.rowcount > 0:
        data = cur.fetchall()
    else:
        data = None
    cur.close()
    conn.close()
    results['results'] = data
    return jsonify(results)



@app.route('/api/data_sources', methods = ['GET', 'POST'])
def get_sources():
    """Get the details of the data sources in JSON."""
    #API Key not needed
    try:
        conn = psycopg2.connect(host = settings.host, database = settings.database, user = settings.user, password = settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code = 500)
    cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
    #Build query
    cur.execute("SELECT * FROM data_sources")
    logging.debug(cur.query)
    data = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(data)


#################################
# MassDigi-specific routes
#################################
@app.route('/mdpp/previewimage', methods = ['GET'])
def get_preview():
    """Return image previews from Mass Digi Projects."""
    file_id = request.args.get('file_id')
    if file_id == None:
        raise InvalidUsage('file_id missing', status_code = 400)
    try:
        file_id = int(file_id)
    except:
        raise InvalidUsage('invalid file_id value', status_code = 400)
    filefolder = str(file_id)[0:2]
    filename = "static/mdpp_previews/{}/{}.jpg".format(filefolder, file_id)
    if os.path.isfile(filename) == False:
        filename = "static/na.jpg"
    return send_file(filename, mimetype='image/jpeg')



@app.route('/mdpp/ocr/image', methods = ['GET'])
def get_ocr_image():
    """Return image previews from Mass Digi Projects."""
    file = request.args.get('file')
    if file == None:
        raise InvalidUsage('file missing', status_code = 400)
    project = request.args.get('project')
    if project == None:
        raise InvalidUsage('project missing', status_code = 400)
    try:
        project = UUID(project, version=4)
    except:
        raise InvalidUsage('Invalid project, it must be a valid UUID.', status_code = 400)
    version = request.args.get('version')
    if version == None:
        version = "default"
    section = request.args.get('section')
    if section == None:
        section = "default"
    filename = "ocr/{}/{}/{}/images_original/{}".format(project, version, section, file)
    if os.path.isfile(filename) == False:
        filename = "static/na.jpg"
    return send_file(filename, mimetype='image/jpeg')



@app.route('/mdpp/ocr/image_annotated', methods = ['GET'])
def get_ocr_annotated():
    """Return image previews from Mass Digi Projects."""
    file = request.args.get('file')
    if file == None:
        raise InvalidUsage('file missing', status_code = 400)
    project = request.args.get('project')
    if project == None:
        raise InvalidUsage('project missing', status_code = 400)
    try:
        project = UUID(project, version=4)
    except:
        raise InvalidUsage('Invalid project, it must be a valid UUID.', status_code = 400)
    width = request.args.get('width')
    if width == None:
        raise InvalidUsage('width missing', status_code = 400)
    try:
        width = int(width)
    except:
        raise InvalidUsage('Invalid value for width.', status_code = 400)
    version = request.args.get('version')
    if version == None:
        version = 'default'
    section = request.args.get('section')
    if section == None:
        section = 'default'
    #filename = "ocr/images_annotated/{}/{}/{}".format(project, version, file)
    filename = "ocr/{}/{}/{}/images_annotated/{}".format(project, version, section, file)
    logging.debug(filename)
    if os.path.isfile(filename) == False:
        filename = "static/na.jpg"
    else:
        img = Image.open(filename)
        wpercent = (int(width)/float(img.size[0]))
        hsize = int((float(img.size[1])*float(wpercent)))
        img = img.resize((width,hsize), Image.ANTIALIAS)
        filename = "tmp/{}.jpg".format(file)
        img.save(filename)
    return send_file(filename, mimetype='image/jpeg')







##################################
# Mass Georeferencing routes
##################################

@app.route('/mg/all_collex', methods = ['POST'])
def get_collex():
    """Get all collex available for MG."""
    #Check for valid API Key
    if apikey() == False:
        raise InvalidUsage('Unauthorized', status_code = 401)
    user_id = request.values.get('user_id')
    if user_id == None:
        raise InvalidUsage('Missing user_id', status_code = 400)
    try:
        conn = psycopg2.connect(host = settings.host, database = settings.database, user = settings.user, password = settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code = 500)
    cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
    #Build query
    cur.execute("SELECT c.* FROM mg_collex c, mg_users_collex u WHERE c.collex_id = u.collex_id AND u.user_id = '{user_id}'::UUID".format(user_id = user_id))
    logging.debug(cur.query)
    data = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(data)



@app.route('/mg/collex_dl', methods = ['POST'])
def get_collex_dl():
    """Get all collex available for MG."""
    #Check for valid API Key
    if apikey() == False:
        raise InvalidUsage('Unauthorized', status_code = 401)
    #Check inputs
    collex_id = request.values.get('collex_id')
    if collex_id == None:
        raise InvalidUsage('Missing collex_id', status_code = 400)
    try:
        collex_id = UUID(collex_id, version=4)
    except:
        raise InvalidUsage('Invalid collex key, it must be a valid UUID.', status_code = 400)
    try:
        conn = psycopg2.connect(host = settings.host, database = settings.database, user = settings.user, password = settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code = 500)
    cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
    #Build query
    cur.execute("SELECT collex_id, 'https://dpogis.si.edu/dl/' || UPPER(dl_file_path::text) AS dl_file_path, dl_recipe, dl_norecords, ready, updated_at FROM mg_collex_dl WHERE collex_id = '{collex_id}'::UUID".format(collex_id = collex_id))
    logging.debug(cur.query)
    data = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(data)



@app.route('/mg/collex_info', methods = ['POST'])
def get_collexinfo():
    """Get all collex available for MG."""
    #Check for valid API Key
    if apikey() == False:
        raise InvalidUsage('Unauthorized', status_code = 401)
    #Check inputs
    collex_id = request.values.get('collex_id')
    if collex_id == None:
        raise InvalidUsage('Missing collex_id', status_code = 400)
    try:
        collex_id = UUID(collex_id, version=4)
    except:
        raise InvalidUsage('Invalid collex key, it must be a valid UUID.', status_code = 400)
    try:
        conn = psycopg2.connect(host = settings.host, database = settings.database, user = settings.user, password = settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code = 500)
    cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
    #Build query
    cur.execute("SELECT m.*, COUNT(DISTINCT r.species) as no_species, count(r.*) as no_recordgroups, sum(r.no_records) as no_records, count(s.*) AS no_selected_matches FROM mg_collex m LEFT JOIN mg_recordgroups r ON (m.collex_id = r.collex_id) LEFT JOIN mg_selected_candidates s ON (r.recgroup_id = s.recgroup_id) WHERE m.collex_id = '{collex_id}'::UUID GROUP BY m.collex_id".format(collex_id = collex_id))
    logging.debug(cur.query)
    data = cur.fetchone()
    cur.close()
    conn.close()
    return jsonify(data)



@app.route('/mg/collex_species', methods = ['POST'])
def get_collex_spp():
    """Get all species available for a collex for MG."""
    #Check for valid API Key
    if apikey() == False:
        raise InvalidUsage('Unauthorized', status_code = 401)
    #Check inputs
    collex_id = request.values.get('collex_id')
    if collex_id == None:
        raise InvalidUsage('Missing collex_id', status_code = 400)
    try:
        collex_id = UUID(collex_id, version=4)
    except:
        raise InvalidUsage('Invalid collex key, it must be a valid UUID.', status_code = 400)
    try:
        conn = psycopg2.connect(host = settings.host, database = settings.database, user = settings.user, password = settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code = 500)
    cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
    #Build query
    cur.execute("SELECT DISTINCT species FROM mg_recordgroups WHERE collex_id = '{collex_id}'::uuid AND no_candidates > 0 AND recgroup_id NOT IN (SELECT recgroup_id FROM mg_selected_candidates WHERE collex_id = '{collex_id}'::uuid)".format(collex_id = collex_id))
    logging.debug(cur.query)
    data = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(data)



@app.route('/mg/species_recgroups', methods = ['POST'])
def get_spp_recgroups():
    """Get all record groups for a species."""
    #Check for valid API Key
    if apikey() == False:
        raise InvalidUsage('Unauthorized', status_code = 401)
    #Check inputs
    species = request.values.get('species')
    if species == None:
        raise InvalidUsage('species missing', status_code = 400)
    collex_id = request.values.get('collex_id')
    if collex_id == None:
        raise InvalidUsage('Missing collex_id', status_code = 400)
    try:
        collex_id = UUID(collex_id, version=4)
    except:
        raise InvalidUsage('Invalid collex key, it must be a valid UUID.', status_code = 400)
    try:
        conn = psycopg2.connect(host = settings.host, database = settings.database, user = settings.user, password = settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code = 500)
    cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
    #Build query
    cur.execute("SELECT * FROM mg_recordgroups WHERE species = '{species}' AND collex_id = '{collex_id}'::uuid AND no_candidates > 0 AND recgroup_id NOT IN (SELECT recgroup_id FROM mg_selected_candidates WHERE collex_id = '{collex_id}'::uuid) ORDER BY locality ASC, no_records DESC".format(species = species, collex_id = collex_id))
    logging.debug(cur.query)
    data = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(data)



@app.route('/mg/recgroups_records', methods = ['POST'])
def get_recgroups_records():
    """Get all record groups for a species."""
    #Check for valid API Key
    if apikey() == False:
        raise InvalidUsage('Unauthorized', status_code = 401)
    #Check inputs
    recgroup_id = request.values.get('recgroup_id')
    if recgroup_id == None:
        raise InvalidUsage('Missing recgroup_id', status_code = 400)
    try:
        recgroup_id = UUID(recgroup_id, version=4)
    except:
        raise InvalidUsage('Invalid recgroup_id key, it must be a valid UUID.', status_code = 400)
    try:
        conn = psycopg2.connect(host = settings.host, database = settings.database, user = settings.user, password = settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code = 500)
    cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
    #Build query
    cur.execute("SELECT mg_occurrenceid, occurrenceid, eventdate, locality, countrycode, higherclassification, recordedby FROM mg_occurrences WHERE mg_occurrenceid IN (SELECT mg_occurrenceid FROM mg_records WHERE recgroup_id = '{recgroup_id}'::uuid)".format(recgroup_id = recgroup_id))
    logging.debug(cur.query)
    data = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(data)



@app.route('/mg/candidates', methods = ['POST'])
def get_candidates():
    """Get all record groups for a species."""
    #Check for valid API Key
    if apikey() == False:
        raise InvalidUsage('Unauthorized', status_code = 401)
    #Check inputs
    recgroup_id = request.values.get('recgroup_id')
    candidate_id = request.values.get('candidate_id')
    if recgroup_id == None and candidate_id == None:
        raise InvalidUsage('Missing recgroup_id or candidate_id', status_code = 400)
    if recgroup_id != None:
        try:
            recgroup_id = UUID(recgroup_id, version=4)
        except:
            raise InvalidUsage('Invalid recgroup_id key, it must be a valid UUID.', status_code = 400)
    if candidate_id != None:
        try:
            candidate_id = UUID(candidate_id, version=4)
        except:
            raise InvalidUsage('Invalid candidate_id key, it must be a valid UUID.', status_code = 400)
    species = request.values.get('species')
    if species == None:
        raise InvalidUsage('Missing species', status_code = 400)
    try:
        conn = psycopg2.connect(host = settings.host, database = settings.database, user = settings.user, password = settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code = 500)
    cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
    #Query file
    if candidate_id == None:
        with open('queries/get_candidates.sql') as f:
            query_template = f.read()
        cur.execute(query_template.format(genus = species.split(' ')[0], species = species, recgroup_id = recgroup_id))
    else:
        with open('queries/get_candidate.sql') as f:
            query_template = f.read()
        cur.execute(query_template.format(genus = species.split(' ')[0], species = species, candidate_id = candidate_id))
    logging.debug(cur.query)
    data = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(data)



@app.route('/mg/candidate_scores', methods = ['POST'])
def get_candidate_scores():
    """Get all record groups for a species."""
    #Check for valid API Key
    if apikey() == False:
        raise InvalidUsage('Unauthorized', status_code = 401)
    #Check inputs
    candidate_id = request.values.get('candidate_id')
    if candidate_id == None:
        raise InvalidUsage('Missing candidate_id', status_code = 400)
    try:
        candidate_id = UUID(candidate_id, version=4)
    except:
        raise InvalidUsage('Invalid candidate_id key, it must be a valid UUID.', status_code = 400)
    try:
        conn = psycopg2.connect(host = settings.host, database = settings.database, user = settings.user, password = settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code = 500)
    cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
    #Build query
    cur.execute("SELECT s.score_type, s.score, t.score_info FROM mg_candidates_scores s LEFT JOIN mg_scoretypes t ON (s.score_type = t.scoretype) WHERE s.candidate_id = '{candidate_id}'::uuid GROUP BY s.score_type, s.score, t.score_info ORDER BY score_type".format(candidate_id = candidate_id))
    logging.debug(cur.query)
    data = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(data)



@app.route('/mg/candidate_info', methods = ['POST'])
def get_candidate_info():
    """Get all record groups for a species."""
    #Check for valid API Key
    if apikey() == False:
        raise InvalidUsage('Unauthorized', status_code = 401)
    #Check inputs
    candidate_id = request.values.get('candidate_id')
    if candidate_id == None:
        raise InvalidUsage('Missing candidate_id', status_code = 400)
    try:
        candidate_id = UUID(candidate_id, version=4)
    except:
        raise InvalidUsage('Invalid candidate_id key, it must be a valid UUID.', status_code = 400)
    try:
        conn = psycopg2.connect(host = settings.host, database = settings.database, user = settings.user, password = settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code = 500)
    cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
    #Build query
    cur.execute("SELECT * FROM mg_candidates WHERE candidate_id = '{candidate_id}'::uuid".format(candidate_id = candidate_id))
    logging.debug(cur.query)
    data = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(data)



@app.route('/mg/get_gbif_record', methods = ['POST'])
def get_gbif_record():
    """Get single GBIF record."""
    #Check for valid API Key
    if apikey() == False:
        raise InvalidUsage('Unauthorized', status_code = 401)
    #Check inputs
    uid = request.values.get('uid')
    if uid == None:
        raise InvalidUsage('Missing uid', status_code = 400)
    species = request.values.get('species')
    if species == None:
        raise InvalidUsage('Missing species', status_code = 400)
    try:
        conn = psycopg2.connect(host = settings.host, database = settings.database, user = settings.user, password = settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code = 500)
    cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
    #Build query
    with open('queries/get_gbif.sql') as f:
            query_template = f.read()
    cur.execute(query_template.format(genus = species.split(' ')[0], species = species, uid = uid))
    logging.debug(cur.query)
    data = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(data)



@app.route('/mg/get_scoretypes', methods = ['POST'])
def get_scoretypes():
    """Get score types used in the matching."""
    #Check for valid API Key
    if apikey() == False:
        raise InvalidUsage('Unauthorized', status_code = 401)
    #No inputs, other than api key
    try:
        conn = psycopg2.connect(host = settings.host, database = settings.database, user = settings.user, password = settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code = 500)
    cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
    #Build query
    cur.execute("SELECT * FROM mg_scoretypes")
    logging.debug(cur.query)
    data = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(data)



@app.route('/mg/login', methods = ['POST'])
def mg_login():
    """Login user."""
    #Check for valid API Key
    if apikey(True) == False:
        raise InvalidUsage('Unauthorized', status_code = 401)
    user_name = request.values.get('user_name')
    if user_name == None:
        raise InvalidUsage('Missing user_name', status_code = 400)
    password = request.values.get('password')
    if password == None:
        raise InvalidUsage('Missing password', status_code = 400)
    try:
        conn = psycopg2.connect(host = settings.host, database = settings.database, user = settings.user, password = settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code = 500)
    cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
    #Build query
    cur.execute("SELECT user_id FROM mg_users WHERE user_name = '{user_name}' AND user_pass = MD5('{password}')".format(user_name = user_name, password = password))
    logging.debug(cur.query)
    data = cur.fetchone()
    cur.close()
    conn.close()
    return jsonify(data)



@app.route('/mg/new_cookie', methods = ['POST'])
def new_cookie():
    """Create cookie."""
    #Check for valid API Key
    if apikey(True) == False:
        raise InvalidUsage('Unauthorized', status_code = 401)
    user_id = request.values.get('user_id')
    if user_id == None:
        raise InvalidUsage('Missing user_id', status_code = 400)
    cookie = request.values.get('cookie')
    if cookie == None:
        raise InvalidUsage('Missing cookie', status_code = 400)
    try:
        conn = psycopg2.connect(host = settings.host, database = settings.database, user = settings.user, password = settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code = 500)
    cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
    #Build query
    cur.execute("INSERT INTO mg_users_cookies (user_id, cookie) VALUES ('{user_id}', '{cookie}')".format(user_id = user_id, cookie = cookie))
    conn.commit()
    logging.debug(cur.query)
    cur.close()
    conn.close()
    return jsonify(None)



@app.route('/mg/check_cookie', methods = ['POST'])
def check_cookie():
    """Check if cookie is valid."""
    #Check for valid API Key
    if apikey(True) == False:
        raise InvalidUsage('Unauthorized', status_code = 401)
    cookie = request.values.get('cookie')
    if cookie == None:
        raise InvalidUsage('Missing cookie', status_code = 400)
    try:
        conn = psycopg2.connect(host = settings.host, database = settings.database, user = settings.user, password = settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code = 500)
    cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
    #Build query
    cur.execute("SELECT u.user_id, u.user_name FROM mg_users u, mg_users_cookies c WHERE  c.user_id = u.user_id AND c.cookie = '{cookie}'".format(cookie = cookie))
    logging.debug(cur.query)
    data = cur.fetchone()
    cur.close()
    conn.close()
    return jsonify(data)



#from https://stackoverflow.com/a/23724948
@app.route('/dl/', defaults={'req_path': ''})
@app.route('/dl/<path:req_path>')
def dir_listing(req_path):
    BASE_DIR = '/var/www/api/dl/'
    # Joining the base and the requested path
    abs_path = os.path.join(BASE_DIR, req_path)
    # Return 404 if path doesn't exist
    if not os.path.exists(abs_path):
        return render_template('wait.html')
    # Check if path is a file and serve
    if os.path.isfile(abs_path):
        return send_file(abs_path)
    # Show directory contents
    files = os.listdir(abs_path)
    return render_template('dl.html', files=files)







if __name__ == '__main__':
    app.run(host = '0.0.0.0', debug = False)
    # from optparse import OptionParser
    # oparser = OptionParser()
    # oparser.add_option('-d', '--debug', action='store_true', default=False)
    # opts, args = oparser.parse_args()
    # app.debug = opts.debug
    # app.run(debug = True)
