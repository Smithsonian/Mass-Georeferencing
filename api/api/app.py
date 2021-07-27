#!flask/bin/python
#
# Spatial and OpenRefine Reconciliation API.
#

import simplejson as json
import psycopg2
import os
import logging
import locale
import psycopg2.extras
from uuid import UUID
# Flask
from flask import Flask, jsonify, request
from flask import Response
from flask import render_template
from flask import send_file

import numpy as np
import re

from PIL import Image

import aat_reconcile as recon
from aat_reconcile.reconciliation import SPARQLQuery
from skosprovider_getty.providers import AATProvider

# Import queries
import queries

# Import metadata
import metadata

# Import settings
import settings

api_ver = "0.1"

# logging.basicConfig(stream=sys.stderr)
logging.basicConfig(filename='api.log',
                    level=logging.DEBUG,
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

# Set locale for number format
locale.setlocale(locale.LC_ALL, 'en_US.UTF-8')

app = Flask(__name__)


# Query the GIS database
def query_database(query, parameters="", server="gis"):
    try:
        if server == "gis":
            conn = psycopg2.connect(host=settings.host,
                                    database=settings.database,
                                    user=settings.user,
                                    password=settings.password)
        elif server == "osprey":
            conn = psycopg2.connect(host=settings.osprey_host,
                                    database=settings.osprey_database,
                                    user=settings.osprey_user,
                                    password=settings.osprey_password)
        else:
            # Unknown
            return None
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code=500)
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    # Run query
    cur.execute(query, parameters)
    logging.debug(cur.query)
    data = cur.fetchall()
    cur.close()
    conn.close()
    return data


# From http://flask.pocoo.org/docs/1.0/patterns/apierrors/
class InvalidUsage(Exception):
    status_code = 400

    def __init__(self, message, status_code=None, payload=None):
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


def apikey(admin=False):
    headers = request.headers
    # Temp for dev
    if request.access_route[0] == settings.allow_ip:
        logging.info("Allowing IP " + request.access_route[0])
        return True
    if request.method == 'POST':
        auth = headers.get("X-Api-Key")
    else:
        auth = None
    if auth is None:
        return False
    try:
        auth = UUID(auth, version=4)
    except:
        raise InvalidUsage('Invalid key, it must be a valid UUID.', status_code=400)
    # Query
    with open('queries/apikeys.sql') as f:
        query_template = f.read()
    # Build query
    logging.info(auth)
    data = query_database(query_template, {'apikey': auth})
    # cur.execute(query_template, {'apikey': auth})
    # logging.debug(cur.query)
    if len(data) != 1:
        # Could not find key or is no longer valid
        return False
    else:
        # data = cur.fetchone()
        data = data[0]
        # Add counter
        referrer = headers.get("Referer")
        data = query_database("INSERT INTO apikeys_usage (key, referrer) VALUES (%(apikey)s, %(referrer)s)",
                              {'apikey': auth, 'referrer': referrer})
        data = data[0]
        logging.info(headers)
        if admin:
            if data['admin_user']:
                return True
            else:
                return False
        else:
            if (data['rate_limit'] - data['no_queries']) < 0:
                raise InvalidUsage('Rate limit exceeded. Wait an hour or contact us to raise your limit',
                                   status_code=429)
            else:
                return True


@app.route('/api/routes', methods=['GET', 'POST'])
def routes_list():
    """Print available routes"""
    # Adapted from https://stackoverflow.com/a/17250154
    func_list = {}
    for rule in app.url_map.iter_rules():
        if rule.endpoint != 'static' and\
                rule.rule != '/api/' and\
                rule.rule != '/mdpp/previewimage' and\
                rule.rule[0:4] != '/mg/' and\
                rule.rule[0:4] != '/dl/' and\
                rule.rule[0:9] != '/reconcile/':
            func_list[rule.rule] = app.view_functions[rule.endpoint].__doc__
    return jsonify(func_list)


@app.route('/api/', methods=['GET', 'POST'])
@app.route('/api', methods=['GET', 'POST'])
def index():
    """Welcome message and API versions available"""
    data = json.dumps({'current_version': api_ver,
                       'reference_url': "https://sinet.sharepoint.com/sites/DPO/SitePages/Spatial-Database.aspx",
                       'api_title': "OCIO DPO PostGIS API"})
    return Response(data, mimetype='application/json')


@app.route('/', methods=['GET', 'POST'])
def home():
    """Homepage in HTML format"""
    return render_template('home.html')


@app.route('/help', methods=['GET', 'POST'])
def help():
    """Help page in HTML format"""
    return render_template('help.html')


########################
# AAT                  #
########################
# Needed for OpenRefine
# Based on https://github.com/mphilli/AAT-reconcile
def jsonpify(obj):
    """
    Like jsonify but wraps result in a JSONP callback if a 'callback'
    query param is supplied.
    """
    try:
        callback = request.args['callback']
        response = app.make_response("%s(%s)" % (callback, json.dumps(obj)))
        response.mimetype = "text/javascript"
        return response
    except KeyError:
        return jsonify(obj)


def preprocess(token):
    tokens = token.split(" ")
    for i, t in enumerate(tokens):
        if ")" in t or "(" in t:
            tokens[i] = ''
    token = " ".join(tokens)
    if token.endswith("."):
        token = token[:-1]
    return token.lower().lstrip().rstrip()


def searchaat(search_in, limit=3, properties=None):
    # http://vocab.getty.edu/queries#Stop-Word_Removal
    stop_words = ["a", "an", "and", "are", "as", "at", "be", "but", "by", "for", "if", "in", "into", "is", "it", "no",
                  "not", "of", "on", "or", "such", "that", "the", "their", "then", "there", "these", "they", "this",
                  "to", "was", "will", "with"]
    scores = []
    search_token = preprocess(search_in).lower()
    logging.info(search_token)
    search_token = re.sub(r'[^a-zA-Z0-9]+', ' ', search_token)
    # Remove whitespaces
    search_token_list = search_token.split()
    # Remove stop words
    for word in stop_words:
        if word in search_token_list:
            search_token_list.remove(word)
    # Remove repeated words with numpy
    search_token_np = np.array(search_token_list)
    search_token = np.unique(search_token_np)
    # Join and format search query
    search_token = "* AND ".join(search_token)
    logging.info(search_token)
    query_result = SPARQLQuery(search_term=search_token).results
    if search_in.endswith("."):
        search_in = search_in[:-1]
    # print(search_in, search_token)
    recon_ = recon.reconcile(search_in, query_result, sort=True, limit=limit)
    for r in recon_:
        match = False
        recon_result = recon.Recon(r)
        # logging.info("Recon object: " + str(recon_result))
        if recon_result.score == "1.0":
            match = True
        scores.append({
            "id": str(recon_result.uri),
            "name": recon_result.term,
            "score": recon_result.score,
            "match": match,
            "type": metadata.metadata_aat['defaultTypes'],
        })
    results = scores
    scores = []
    # Query with added words
    if properties is not None:
        for i in range(len(properties)):
            # Split on spaces
            p_text = re.sub(r'[^a-zA-Z0-9]+', ' ', properties[i]['v']).lower().split()
            search_token_list.extend(p_text)
    # Remove stop words
    for word in stop_words:
        if word in search_token_list:
            search_token_list.remove(word)
    # Remove repeated words with numpy
    search_token_np = np.array(search_token_list)
    search_token = np.unique(search_token_np)
    # Join and format search query
    search_token = "* AND ".join(search_token)
    logging.info('search_token joined')
    logging.info(search_token)
    query_result = SPARQLQuery(search_term=search_token).results
    if search_in.endswith("."):
        search_in = search_in[:-1]
    # print(search_in, search_token)
    recon_ = recon.reconcile(search_in, query_result, sort=True, limit=limit)
    for r in recon_:
        match = False
        recon_result = recon.Recon(r)
        # logging.info("Recon object: " + str(recon_result))
        if recon_result.score == "1.0":
            match = True
        scores.append({
            "id": str(recon_result.uri),
            "name": recon_result.term,
            "score": recon_result.score,
            "match": match,
            "type": metadata.metadata_aat['defaultTypes'],
        })
    results.extend(scores)
    # Remove repeated results
    results = [x for i, x in enumerate(results) if i == results.index(x)]
    return results


@app.route("/reconcile/AAT", methods=['POST', 'GET'])
def reconcile():
    queries = request.form.get('queries')
    if queries:
        queries = json.loads(queries)
        results = {}
        for (key, query) in queries.items():
            qtype = query.get('type')
            if qtype is None:
                return jsonpify(metadata.metadata_aat)
            limit = 3
            properties = None
            if 'limit' in query:
                limit = int(query['limit'])
            if 'properties' in query:
                properties = query['properties']
            # performance testing reveals that querying the SPARQL endpoint is superior
            results[key] = {"result": searchaat(query['query'],
                                                properties=properties,
                                                limit=limit
                                                )}
        print(results)
        return jsonpify(results)
    return jsonpify(metadata.metadata_aat)


@app.route("/AAT", methods=['POST', 'GET'])
def showaat():
    aat = request.values.get('aat')
    if aat:
        aat_data = AATProvider(metadata={'id': 'AAT'})
        pref_label = None
        alt_labels = []
        note = None
        data = aat_data.get_by_id(aat)
        for label in data.labels:
            if label.type == 'prefLabel' and (label.language == 'en' or label.language == 'English'):
                pref_label = label.label
            alt_labels.append("{} ({})".format(label.label, label.language))
        for n in data.notes:
            if n.language == 'en':
                note = n.note
        return render_template('aat.html', pref_label=pref_label, alt_labels=alt_labels, note=note, id=aat)


######################


@app.route('/data_sources', methods=['GET', 'POST'])
def get_sources_html():
    """Get the details of the data sources in HTML format."""
    # API Key not needed
    # Check inputs
    datasource_id = request.values.get('datasource_id')
    # logging.debug(datasource_id)
    if datasource_id is None:
        # Build query
        data = query_database(queries.get_datasources)
        summary = sum(row['no_features'] for row in data)
        summary = locale.format_string("%d", summary, grouping=True)
    else:
        data = query_database(queries.get_onedatasource, {'datasource_id': datasource_id})
        summary = None
    results = data
    return render_template('data_sources.html', data=results, summary=summary)


@app.route('/details', methods=['GET', 'POST'])
def get_details_html():
    """Get the details of the row from a data source in HTML format."""
    # API Key not needed
    # Check inputs
    datasource_id = request.values.get('datasource_id')
    speciessource = request.values.get('speciessource')
    if datasource_id is None and speciessource is None:
        raise InvalidUsage('datasource_id and speciessource missing', status_code=400)
    uid = request.values.get('id')
    if uid is None:
        raise InvalidUsage('id missing', status_code=400)
    if datasource_id is not None:
        logging.debug(datasource_id)
        data = query_database("SELECT * FROM data_sources WHERE datasource_id = %(datasource_id)s",
                              {'datasource_id': datasource_id})
        datasource = data[0]
        data = query_database(
            "SELECT %(datasource)s as data_source, * FROM {} WHERE uid = %(uid)s".format(datasource_id),
            {'uid': uid, 'datasource': "{} ({})".format(datasource['source_title'], datasource['source_url'])})
        data = data[0]
    elif speciessource is not None:
        logging.debug(speciessource)
        if speciessource == "gbiftaxonomy":
            data = query_database("SELECT * FROM gbif_vernacularnames WHERE taxonID = %(uid)s", {'uid': uid})
            data = data[0]
    return render_template('details.html', data=data)


@app.route('/api/geom', methods=['POST'])
def get_geom():
    """Returns the geometry of a feature."""
    # Check for valid API Key
    if not apikey():
        raise InvalidUsage('Unauthorized', status_code=401)
    # Check inputs
    uid = request.values.get('uid')
    if uid is None:
        raise InvalidUsage('uid missing', status_code=400)
    layer = request.values.get('layer')
    if layer is None:
        raise InvalidUsage('layer missing', status_code=400)
    if layer[:4] != "gbif":
        try:
            uid = UUID(uid, version=4)
        except:
            raise InvalidUsage('uid is not a valid UUID', status_code=400)
    else:
        species = request.values.get('species')
        if species is None:
            raise InvalidUsage('species missing', status_code=400)
    # Connect to the database
    try:
        conn = psycopg2.connect(host=settings.host, database=settings.database, user=settings.user,
                                password=settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code=500)
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    # Check that layer is online
    cur.execute("SELECT count(*) FROM data_sources WHERE datasource_id = %(layer)s", {'layer': layer})
    valid_layer = cur.fetchone()
    if valid_layer == 0:
        raise InvalidUsage('layer does not exists', status_code=400)
    cur.execute("SELECT is_online FROM data_sources WHERE datasource_id = %(layer)s", {'layer': layer})
    is_online = cur.fetchone()
    if not is_online:
        raise InvalidUsage('layer is offline for maintenance, please try again later', status_code=503)
    # Query file
    if layer[:4] == "gbif":
        with open('queries/get_geom/gbif.sql') as f:
            query_template = f.read()
        # Build query
        cur.execute(query_template.format(uid=uid, species=species, genus=species.split(' ')[0]))
    else:
        with open('queries/get_geom/{}.sql'.format(layer)) as f:
            query_template = f.read()
        # Build query
        cur.execute(query_template.format(uid=uid))
    logging.debug(cur.query)
    if cur.rowcount == 0:
        cur.close()
        conn.close()
        raise InvalidUsage('An area with this uid was not found', status_code=400)
    else:
        data = cur.fetchone()
        cur.close()
        conn.close()
        return jsonify(data)


@app.route('/api/feature', methods=['POST'])
def get_feat_info():
    """Returns the attributes of a feature."""
    # Check for valid API Key
    if not apikey():
        raise InvalidUsage('Unauthorized', status_code=401)
    # Check inputs
    uid = request.values.get('uid')
    if uid is None:
        raise InvalidUsage('uid missing', status_code=400)
    try:
        uid = UUID(uid, version=4)
    except:
        raise InvalidUsage('uid is not a valid UUID', status_code=400)
    layer = request.values.get('layer')
    if layer is None:
        raise InvalidUsage('layer missing', status_code=400)
    valid_layer = query_database("SELECT count(*) FROM data_sources WHERE datasource_id = %(layer)s", {'layer': layer})
    valid_layer = valid_layer[0]
    if valid_layer == 0:
        raise InvalidUsage('layer does not exists', status_code=400)
    is_online = query_database("SELECT is_online FROM data_sources WHERE datasource_id = %(layer)s", {'layer': layer})
    is_online = is_online[0]
    if not is_online:
        raise InvalidUsage('layer is offline for maintenance, please try again later', status_code=503)
    # Query file
    with open('queries/get_feature/{}.sql'.format(layer)) as f:
        query_template = f.read()
    data = query_database(query_template.format(uid=uid))
    if len(data) == 0:
        raise InvalidUsage('An area with this uid was not found', status_code=400)
    else:
        return jsonify(data[0])


@app.route('/api/species_range', methods=['POST'])
def get_spprange():
    """Returns the range of a species. If there is no range, return the convex poly of GBIF points"""
    # Check for valid API Key
    if not apikey():
        raise InvalidUsage('Unauthorized', status_code=401)
    # Check inputs
    species = request.values.get('scientificname')
    if species is None:
        raise InvalidUsage('scientificname missing', status_code=400)
    range_type = request.values.get('type')
    if range_type is None:
        range_type = "all"
    # Connect to the database
    try:
        conn = psycopg2.connect(host=settings.host, database=settings.database, user=settings.user,
                                password=settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code=500)
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    # Query file
    # Get range
    if range_type == "any":
        with open('queries/get_speciesrange.sql') as f:
            query_template = f.read()
        # Build query
        cur.execute(query_template, {'species': species, })
        logging.debug(cur.query)
        if cur.rowcount == 0:
            with open('queries/get_convexhull.sql') as f:
                query_template = f.read()
            # Build query
            cur.execute(query_template, {'species': species, })
            logging.debug(cur.query)
            if cur.rowcount == 0:
                cur.close()
                conn.close()
                raise InvalidUsage('No data was found', status_code=400)
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
        # Build query
        cur.execute(query_template, {'species': species, })
        logging.debug(cur.query)
        if cur.rowcount == 0:
            cur.close()
            conn.close()
            raise InvalidUsage('No data was found', status_code=400)
        else:
            data = cur.fetchone()
            cur.close()
            conn.close()
            return jsonify(data)


@app.route('/api/species_range_dist', methods=['POST'])
def get_spprange_dist():
    """
        Returns the distance to the edge the range of a
        species. If there is no range, use the convex
        poly of GBIF points
    """
    # Check for valid API Key
    if not apikey():
        raise InvalidUsage('Unauthorized', status_code=401)
    # Check inputs
    species = request.values.get('scientificname')
    if species is None:
        raise InvalidUsage('scientificname missing', status_code=400)
    lat = request.values.get('lat')
    try:
        lat = float(lat)
    except:
        raise InvalidUsage('invalid lat value', status_code=400)
    lng = request.values.get('lng')
    try:
        lng = float(lng)
    except:
        raise InvalidUsage('invalid lng value', status_code=400)
    # Connect to the database
    try:
        conn = psycopg2.connect(host=settings.host, database=settings.database, user=settings.user,
                                password=settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code=500)
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    # Query file
    with open('queries/get_convexhull_dist.sql') as f:
        query_template = f.read()
    # Build query
    cur.execute(query_template, {'species': species, 'lng': lng, 'lat': lat})
    logging.debug(cur.query)
    if cur.rowcount == 0:
        cur.close()
        conn.close()
        raise InvalidUsage('No data was found', status_code=400)
    else:
        data = cur.fetchone()
        cur.close()
        conn.close()
        return jsonify(data)


@app.route('/api/intersection', methods=['POST'])
def get_wdpa():
    """Returns the uid of the feature that intersects the lat and lon given."""
    # Check for valid API Key
    if not apikey():
        raise InvalidUsage('Unauthorized', status_code=401)
    # Check inputs
    lat = request.values.get('lat')
    try:
        lat = float(lat)
    except:
        raise InvalidUsage('invalid lat value', status_code=400)
    lng = request.values.get('lng')
    try:
        lng = float(lng)
    except:
        raise InvalidUsage('invalid lng value', status_code=400)
    radius = request.values.get('radius')
    if radius is not None:
        try:
            radius = int(radius)
        except:
            raise InvalidUsage('invalid radius value', status_code=400)
    layer = request.values.get('layer')
    if layer is None:
        raise InvalidUsage('layer missing', status_code=400)
    # Connect to the database
    try:
        conn = psycopg2.connect(host=settings.host, database=settings.database, user=settings.user,
                                password=settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code=500)
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur.execute("SELECT count(*) FROM data_sources WHERE datasource_id = %(layer)s", {'layer': layer})
    valid_layer = cur.fetchone()
    if valid_layer['count'] == 0:
        raise InvalidUsage('layer does not exists', status_code=400)
    cur.execute("SELECT is_online FROM data_sources WHERE datasource_id = %(layer)s", {'layer': layer})
    is_online = cur.fetchone()
    if not is_online['is_online']:
        raise InvalidUsage('layer is offline for maintenance, please try again later', status_code=503)
    # Query file
    if radius is None:
        with open('queries/intersection.sql') as f:
            query_template = f.read()
        # Build query
        try:
            cur.execute(query_template, {'lat': lat, 'lng': lng, 'layer': layer})
            logging.debug(cur.query)
        except:
            vals = {'lat': lat, 'lng': lng, 'layer': layer}
            logging.error(query_template, extra=vals)
            cur.execute("ROLLBACK")
            conn.commit()
    else:
        with open('queries/intersection_radius.sql') as f:
            query_template = f.read()
        # Build query
        try:
            cur.execute(query_template, {'lat': lat, 'lng': lng, 'layer': layer})
            logging.debug(cur.query)
        except:
            vals = {'lat': lat, 'lng': lng, 'layer': layer, 'radius': radius}
            logging.error(query_template, extra=vals)
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


@app.route('/api/historical_int', methods=['POST'])
def get_history():
    """Returns the historical locality that matches the coords and the year."""
    # Check for valid API Key
    if not apikey():
        raise InvalidUsage('Unauthorized', status_code=401)
    # Check inputs
    lat = request.values.get('lat')
    try:
        lat = float(lat)
    except:
        raise InvalidUsage('invalid lat value', status_code=400)
    lng = request.values.get('lng')
    try:
        lng = float(lng)
    except:
        raise InvalidUsage('invalid lng value', status_code=400)
    year = request.values.get('year')
    if year is None:
        raise InvalidUsage('year missing', status_code=400)
    try:
        year = int(year)
    except:
        raise InvalidUsage('invalid year value', status_code=400)
    radius = request.values.get('radius')
    if radius is None:
        radius = 2500
    else:
        try:
            radius = int(radius)
        except:
            raise InvalidUsage('invalid radius value', status_code=400)
    layer = request.values.get('layer')
    if layer is None:
        raise InvalidUsage('layer missing', status_code=400)
    # Connect to the database
    try:
        conn = psycopg2.connect(host=settings.host, database=settings.database, user=settings.user,
                                password=settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code=500)
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur.execute("SELECT count(*) FROM data_sources WHERE datasource_id = %(layer)s", {'layer': layer})
    valid_layer = cur.fetchone()
    logging.info(cur.query)
    if valid_layer['count'] == 0:
        raise InvalidUsage('layer does not exists', status_code=400)
    cur.execute("SELECT is_online FROM data_sources WHERE datasource_id = %(layer)s", {'layer': layer})
    is_online = cur.fetchone()
    logging.info(cur.query)
    if not is_online['is_online']:
        raise InvalidUsage('layer is offline for maintenance, please try again later', status_code=503)
    # Query file
    with open('queries/hist_intersection_radius.sql') as f:
        query_template = f.read()
    # Build query
    try:
        cur.execute(query_template, {'lat': lat, 'lng': lng, 'layer': layer, 'radius': radius, 'year': year})
        logging.debug(cur.query)
    except:
        vals = {'lat': lat, 'lng': lng, 'layer': layer, 'radius': radius, 'year': year}
        logging.error(query_template, extra=vals)
        cur.execute("ROLLBACK")
        conn.commit()
    if cur.rowcount > 0:
        data = cur.fetchall()
    else:
        data = None
    cur.close()
    conn.close()
    results = {'intersection': data}
    return jsonify(results)


@app.route('/api/all_names', methods=['POST'])
def get_gadm_names():
    """Returns all names from the specified layer."""
    # Check for valid API Key
    if not apikey():
        raise InvalidUsage('Unauthorized', status_code=401)
    # Check inputs
    layer = request.values.get('layer')
    if layer is None:
        raise InvalidUsage('layer missing', status_code=400)
    if layer not in ['gadm0', 'gadm1', 'gadm2', 'gadm3', 'gadm4', 'gadm5', 'wdpa_polygons', 'wdpa_points']:
        raise InvalidUsage('layer not availabe for this route', status_code=400)
    # Connect to the database
    try:
        conn = psycopg2.connect(
            host=settings.host,
            database=settings.database,
            user=settings.user,
            password=settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code=500)
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    results = {}
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur.execute("SELECT count(*) FROM data_sources WHERE datasource_id = %(layer)s", {'layer': layer})
    valid_layer = cur.fetchone()
    if valid_layer['count'] == 0:
        raise InvalidUsage('layer does not exists', status_code=400)
    cur.execute("SELECT is_online FROM data_sources WHERE datasource_id = %(layer)s", {'layer': layer})
    is_online = cur.fetchone()
    if not is_online['is_online']:
        raise InvalidUsage('layer is offline for maintenance, please try again later', status_code=503)
    # Query file
    if layer in ['gadm0', 'gadm1', 'gadm2', 'gadm3', 'gadm4', 'gadm5']:
        with open('queries/gadm_list_names.sql') as f:
            query_template = f.read()
        # Build query
        cur.execute(query_template.format(level=layer.replace('gadm', '')))
    if layer in ['wdpa_polygons', 'wdpa_points']:
        with open('queries/wdpa_list_names.sql') as f:
            query_template = f.read()
        # Build query
        cur.execute(query_template.format(layer=layer))
    logging.debug(cur.query)
    if cur.rowcount > 0:
        data = cur.fetchall()
    else:
        data = None
    cur.close()
    conn.close()
    results['results'] = data
    return jsonify(results)


@app.route('/api/search', methods=['POST'])
def search_names():
    """Search names in the databases for matches. Search is case insensitive."""
    # Check for valid API Key
    if not apikey():
        raise InvalidUsage('Unauthorized', status_code=401)
    # Check inputs
    string = request.values.get('string')
    if string is None:
        raise InvalidUsage('string missing', status_code=400)
    # Connect to the database
    try:
        conn = psycopg2.connect(host=settings.host, database=settings.database, user=settings.user,
                                password=settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code=500)
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    results = {}
    # Query file
    with open('queries/search.sql') as f:
        query_template = f.read()
    # Build query
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


@app.route('/api/data_sources', methods=['GET', 'POST'])
def get_sources():
    """Get the details of the data sources in JSON."""
    # API Key not needed
    # Build query
    data = query_database("SELECT * FROM data_sources")
    return jsonify(data)


#################################
# MassDigi-specific routes
#################################
@app.route('/mdpp/previewimage', methods=['GET'])
def get_preview():
    """Return image previews from Mass Digi Projects."""
    file_id = request.args.get('file_id')
    if file_id is None:
        raise InvalidUsage('file_id missing', status_code=400)
    try:
        file_id = int(file_id)
    except:
        raise InvalidUsage('invalid file_id value', status_code=400)
    filefolder = str(file_id)[0:2]
    filename = "static/mdpp_previews/{}/{}.jpg".format(filefolder, file_id)
    if not os.path.isfile(filename):
        # Build query
        data = query_database(queries.get_folder_id, {'file_id': file_id}, server="osprey")
        folder_id = data[0]
        filename = "static/mdpp_previews/folder{}/{}.jpg".format(folder_id['folder_id'], file_id)
        logging.info(filename)
        if not os.path.isfile(filename):
            filename = "static/na.jpg"
    return send_file(filename, mimetype='image/jpeg')


@app.route('/mdpp/ocr/image', methods=['GET'])
def get_ocr_image():
    """Return image previews from Mass Digi Projects."""
    file = request.args.get('file')
    if file is None:
        raise InvalidUsage('file missing', status_code=400)
    project = request.args.get('project')
    if project is None:
        raise InvalidUsage('project missing', status_code=400)
    try:
        project = UUID(project, version=4)
    except:
        raise InvalidUsage('Invalid project, it must be a valid UUID.', status_code=400)
    version = request.args.get('version')
    if version is None:
        version = "default"
    section = request.args.get('section')
    if section is None:
        section = "default"
    filename = "ocr/{}/{}/{}/images_original/{}".format(project, version, section, file)
    if not os.path.isfile(filename):
        filename = "static/na.jpg"
    return send_file(filename, mimetype='image/jpeg')


@app.route('/mdpp/ocr/image_annotated', methods=['GET'])
def get_ocr_annotated():
    """Return image previews from Mass Digi Projects."""
    file = request.args.get('file')
    if file is None:
        raise InvalidUsage('file missing', status_code=400)
    project = request.args.get('project')
    if project is None:
        raise InvalidUsage('project missing', status_code=400)
    try:
        project = UUID(project, version=4)
    except:
        raise InvalidUsage('Invalid project, it must be a valid UUID.', status_code=400)
    width = request.args.get('width')
    if width is None:
        raise InvalidUsage('width missing', status_code=400)
    try:
        width = int(width)
    except:
        raise InvalidUsage('Invalid value for width.', status_code=400)
    version = request.args.get('version')
    if version is None:
        version = 'default'
    section = request.args.get('section')
    if section is None:
        section = 'default'
    # filename = "ocr/images_annotated/{}/{}/{}".format(project, version, file)
    filename = "ocr/{}/{}/{}/images_annotated/{}".format(project, version, section, file)
    logging.debug(filename)
    if not os.path.isfile(filename):
        filename = "static/na.jpg"
    else:
        img = Image.open(filename)
        wpercent = (int(width) / float(img.size[0]))
        hsize = int((float(img.size[1]) * float(wpercent)))
        img = img.resize((width, hsize), Image.ANTIALIAS)
        filename = "tmp/{}.jpg".format(file)
        img.save(filename)
    return send_file(filename, mimetype='image/jpeg')


##################################
# Mass Georeferencing routes
##################################

@app.route('/mg/all_collex', methods=['POST'])
def get_collex():
    """Get all collex available for MG."""
    # Check for valid API Key
    if not apikey():
        raise InvalidUsage('Unauthorized', status_code=401)
    user_id = request.values.get('user_id')
    if user_id is None:
        raise InvalidUsage('Missing user_id', status_code=400)
    try:
        conn = psycopg2.connect(host=settings.host, database=settings.database, user=settings.user,
                                password=settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code=500)
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    # Build query
    cur.execute(queries.get_collex.format(user_id=user_id))
    logging.debug(cur.query)
    data = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(data)


@app.route('/mg/collex_dl', methods=['POST'])
def get_collex_dl():
    """Get all collex available for MG."""
    # Check for valid API Key
    if not apikey():
        raise InvalidUsage('Unauthorized', status_code=401)
    # Check inputs
    collex_id = request.values.get('collex_id')
    if collex_id is None:
        raise InvalidUsage('Missing collex_id', status_code=400)
    try:
        collex_id = UUID(collex_id, version=4)
    except:
        raise InvalidUsage('Invalid collex key, it must be a valid UUID.', status_code=400)
    try:
        conn = psycopg2.connect(host=settings.host, database=settings.database, user=settings.user,
                                password=settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code=500)
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    # Build query
    cur.execute(
        "SELECT collex_id, 'https://dpogis.si.edu/dl/' || UPPER(dl_file_path::text) AS dl_file_path, dl_recipe, dl_norecords, ready, updated_at FROM mg_collex_dl WHERE collex_id = '{collex_id}'::UUID".format(
            collex_id=collex_id))
    logging.debug(cur.query)
    data = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(data)


@app.route('/mg/collex_info', methods=['POST'])
def get_collexinfo():
    """Get all collex available for MG."""
    # Check for valid API Key
    if not apikey():
        raise InvalidUsage('Unauthorized', status_code=401)
    # Check inputs
    collex_id = request.values.get('collex_id')
    if collex_id is None:
        raise InvalidUsage('Missing collex_id', status_code=400)
    try:
        collex_id = UUID(collex_id, version=4)
    except:
        raise InvalidUsage('Invalid collex key, it must be a valid UUID.', status_code=400)
    try:
        conn = psycopg2.connect(host=settings.host, database=settings.database, user=settings.user,
                                password=settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code=500)
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    # Build query
    cur.execute(queries.get_collex_info.format(collex_id=collex_id))
    logging.debug(cur.query)
    data = cur.fetchone()
    cur.close()
    conn.close()
    return jsonify(data)


@app.route('/mg/collex_species', methods=['POST'])
def get_collex_spp():
    """Get all species available for a collex for MG."""
    # Check for valid API Key
    if not apikey():
        raise InvalidUsage('Unauthorized', status_code=401)
    # Check inputs
    collex_id = request.values.get('collex_id')
    if collex_id is None:
        raise InvalidUsage('Missing collex_id', status_code=400)
    try:
        collex_id = UUID(collex_id, version=4)
    except:
        raise InvalidUsage('Invalid collex key, it must be a valid UUID.', status_code=400)
    try:
        conn = psycopg2.connect(host=settings.host, database=settings.database, user=settings.user,
                                password=settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code=500)
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    # Build query
    cur.execute(queries.get_collex_spp.format(collex_id=collex_id))
    logging.debug(cur.query)
    data = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(data)


@app.route('/mg/species_recgroups', methods=['POST'])
def get_spp_recgroups():
    """Get all record groups for a species."""
    # Check for valid API Key
    if not apikey():
        raise InvalidUsage('Unauthorized', status_code=401)
    # Check inputs
    species = request.values.get('species')
    if species is None:
        raise InvalidUsage('species missing', status_code=400)
    collex_id = request.values.get('collex_id')
    if collex_id is None:
        raise InvalidUsage('Missing collex_id', status_code=400)
    try:
        collex_id = UUID(collex_id, version=4)
    except:
        raise InvalidUsage('Invalid collex key, it must be a valid UUID.', status_code=400)
    try:
        conn = psycopg2.connect(host=settings.host, database=settings.database, user=settings.user,
                                password=settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code=500)
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    # Build query
    cur.execute(queries.get_spp_group.format(species=species, collex_id=collex_id))
    logging.debug(cur.query)
    data = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(data)


@app.route('/mg/recgroups_records', methods=['POST'])
def get_recgroups_records():
    """Get all record groups for a species."""
    # Check for valid API Key
    if not apikey():
        raise InvalidUsage('Unauthorized', status_code=401)
    # Check inputs
    recgroup_id = request.values.get('recgroup_id')
    if recgroup_id is None:
        raise InvalidUsage('Missing recgroup_id', status_code=400)
    try:
        recgroup_id = UUID(recgroup_id, version=4)
    except:
        raise InvalidUsage('Invalid recgroup_id key, it must be a valid UUID.', status_code=400)
    try:
        conn = psycopg2.connect(host=settings.host, database=settings.database, user=settings.user,
                                password=settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code=500)
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    # Build query
    cur.execute(queries.get_recgroups.format(recgroup_id=recgroup_id))
    logging.debug(cur.query)
    data = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(data)


@app.route('/mg/candidates', methods=['POST'])
def get_candidates():
    """Get all record groups for a species."""
    # Check for valid API Key
    if not apikey():
        raise InvalidUsage('Unauthorized', status_code=401)
    # Check inputs
    recgroup_id = request.values.get('recgroup_id')
    candidate_id = request.values.get('candidate_id')
    if recgroup_id is None and candidate_id is None:
        raise InvalidUsage('Missing recgroup_id or candidate_id', status_code=400)
    if recgroup_id is not None:
        try:
            recgroup_id = UUID(recgroup_id, version=4)
        except:
            raise InvalidUsage('Invalid recgroup_id key, it must be a valid UUID.', status_code=400)
    if candidate_id is not None:
        try:
            candidate_id = UUID(candidate_id, version=4)
        except:
            raise InvalidUsage('Invalid candidate_id key, it must be a valid UUID.', status_code=400)
    species = request.values.get('species')
    if species is None:
        raise InvalidUsage('Missing species', status_code=400)
    try:
        conn = psycopg2.connect(host=settings.host, database=settings.database, user=settings.user,
                                password=settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code=500)
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    # Query file
    if candidate_id is None:
        with open('queries/get_candidates.sql') as f:
            query_template = f.read()
        cur.execute(query_template.format(genus=species.split(' ')[0], species=species, recgroup_id=recgroup_id))
    else:
        with open('queries/get_candidate.sql') as f:
            query_template = f.read()
        cur.execute(query_template.format(genus=species.split(' ')[0], species=species, candidate_id=candidate_id))
    logging.debug(cur.query)
    data = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(data)


@app.route('/mg/candidate_scores', methods=['POST'])
def get_candidate_scores():
    """Get all record groups for a species."""
    # Check for valid API Key
    if not apikey():
        raise InvalidUsage('Unauthorized', status_code=401)
    # Check inputs
    candidate_id = request.values.get('candidate_id')
    if candidate_id is None:
        raise InvalidUsage('Missing candidate_id', status_code=400)
    try:
        candidate_id = UUID(candidate_id, version=4)
    except:
        raise InvalidUsage('Invalid candidate_id key, it must be a valid UUID.', status_code=400)
    try:
        conn = psycopg2.connect(host=settings.host, database=settings.database, user=settings.user,
                                password=settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code=500)
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    # Build query
    cur.execute(queries.get_cand_scores.format(candidate_id=candidate_id))
    logging.debug(cur.query)
    data = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(data)


@app.route('/mg/candidate_info', methods=['POST'])
def get_candidate_info():
    """Get all record groups for a species."""
    # Check for valid API Key
    if not apikey():
        raise InvalidUsage('Unauthorized', status_code=401)
    # Check inputs
    candidate_id = request.values.get('candidate_id')
    if candidate_id is None:
        raise InvalidUsage('Missing candidate_id', status_code=400)
    try:
        candidate_id = UUID(candidate_id, version=4)
    except:
        raise InvalidUsage('Invalid candidate_id key, it must be a valid UUID.', status_code=400)
    try:
        conn = psycopg2.connect(host=settings.host, database=settings.database, user=settings.user,
                                password=settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code=500)
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    # Build query
    cur.execute(queries.get_candidate.format(candidate_id=candidate_id))
    logging.debug(cur.query)
    data = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(data)


@app.route('/mg/get_gbif_record', methods=['POST'])
def get_gbif_record():
    """Get single GBIF record."""
    # Check for valid API Key
    if not apikey():
        raise InvalidUsage('Unauthorized', status_code=401)
    # Check inputs
    uid = request.values.get('uid')
    if uid is None:
        raise InvalidUsage('Missing uid', status_code=400)
    species = request.values.get('species')
    if species is None:
        raise InvalidUsage('Missing species', status_code=400)
    try:
        conn = psycopg2.connect(host=settings.host, database=settings.database, user=settings.user,
                                password=settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code=500)
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    # Build query
    with open('queries/get_gbif.sql') as f:
        query_template = f.read()
    cur.execute(query_template.format(genus=species.split(' ')[0], species=species, uid=uid))
    logging.debug(cur.query)
    data = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(data)


@app.route('/mg/get_scoretypes', methods=['POST'])
def get_scoretypes():
    """Get score types used in the matching."""
    # Check for valid API Key
    if not apikey():
        raise InvalidUsage('Unauthorized', status_code=401)
    # No inputs, other than api key
    try:
        conn = psycopg2.connect(host=settings.host, database=settings.database, user=settings.user,
                                password=settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code=500)
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    # Build query
    cur.execute(queries.scoretypes)
    logging.debug(cur.query)
    data = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(data)


@app.route('/mg/login', methods=['POST'])
def mg_login():
    """Login user."""
    # Check for valid API Key
    if not apikey(True):
        raise InvalidUsage('Unauthorized', status_code=401)
    user_name = request.values.get('user_name')
    if user_name is None:
        raise InvalidUsage('Missing user_name', status_code=400)
    password = request.values.get('password')
    if password is None:
        raise InvalidUsage('Missing password', status_code=400)
    try:
        conn = psycopg2.connect(host=settings.host, database=settings.database, user=settings.user,
                                password=settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code=500)
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    # Build query
    cur.execute(queries.get_userid.format(user_name=user_name, password=password))
    logging.debug(cur.query)
    data = cur.fetchone()
    cur.close()
    conn.close()
    return jsonify(data)


@app.route('/mg/new_cookie', methods=['POST'])
def new_cookie():
    """Create cookie."""
    # Check for valid API Key
    if not apikey(True):
        raise InvalidUsage('Unauthorized', status_code=401)
    user_id = request.values.get('user_id')
    if user_id is None:
        raise InvalidUsage('Missing user_id', status_code=400)
    cookie = request.values.get('cookie')
    if cookie is None:
        raise InvalidUsage('Missing cookie', status_code=400)
    try:
        conn = psycopg2.connect(host=settings.host, database=settings.database, user=settings.user,
                                password=settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code=500)
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    # Build query
    cur.execute(queries.create_cookie.format(user_id=user_id, cookie=cookie))
    conn.commit()
    logging.debug(cur.query)
    cur.close()
    conn.close()
    return jsonify(None)


@app.route('/mg/check_cookie', methods=['POST'])
def check_cookie():
    """Check if cookie is valid."""
    # Check for valid API Key
    if not apikey(True):
        raise InvalidUsage('Unauthorized', status_code=401)
    cookie = request.values.get('cookie')
    if cookie is None:
        raise InvalidUsage('Missing cookie', status_code=400)
    try:
        conn = psycopg2.connect(host=settings.host, database=settings.database, user=settings.user,
                                password=settings.password)
    except psycopg2.Error as e:
        logging.error(e)
        raise InvalidUsage('System error', status_code=500)
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    # Build query
    cur.execute(queries.check_cookie.format(cookie=cookie))
    logging.debug(cur.query)
    data = cur.fetchone()
    cur.close()
    conn.close()
    return jsonify(data)


# from https://stackoverflow.com/a/23724948
@app.route('/dl/', defaults={'req_path': ''})
@app.route('/dl/<path:req_path>')
def dir_listing(req_path):
    base_dir = '/var/www/api/dl/'
    # Joining the base and the requested path
    abs_path = os.path.join(base_dir, req_path)
    # Return wait message if path doesn't exist
    if not os.path.exists(abs_path):
        return render_template('wait.html')
    # Check if path is a file and serve
    if os.path.isfile(abs_path):
        return send_file(abs_path)
    # Show directory contents
    files = os.listdir(abs_path)
    return render_template('dl.html', files=files)


if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=True)
