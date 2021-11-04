#!flask/bin/python
#
# Flask test app
#
from flask import Flask, jsonify, request
from flask import Response
from flask import render_template
import simplejson as json
import logging
import locale


app_ver = "0.1"

# logging.basicConfig(stream=sys.stderr)
logging.basicConfig(filename='app.log',
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



@app.route('/results', methods=['GET', 'POST'])
def get_resultsfile():
    # Instead of hard coding the json data, read from file
    file = request.values.get('file')
    images_path = "static/data/"
    from pathlib import Path
    file_stem = Path(file).stem
    json_file = "{}/{}.json".format(images_path, file_stem)
    # print(file_stem)
    print(json_file)
    with open(json_file) as jsonfile:
        p = json.load(jsonfile)
        print(p)
    from PIL import Image
    im = Image.open("{}/{}.jpg".format(images_path, file_stem))
    # width to display
    image_width = 960
    image_height = (image_width / im.size[0]) * im.size[1]

    data = []
    for object in p["localized_object_annotations"]:
        x = object["bounding_poly"]["normalized_vertices"][0]["x"] * image_width
        y = object["bounding_poly"]["normalized_vertices"][0]["y"] * image_height
        x_1 = object["bounding_poly"]["normalized_vertices"][1]["x"] * image_width
        y_1 = object["bounding_poly"]["normalized_vertices"][1]["y"] * image_height
        x_2 = object["bounding_poly"]["normalized_vertices"][2]["x"] * image_width
        y_2 = object["bounding_poly"]["normalized_vertices"][2]["y"] * image_height
        x_3 = object["bounding_poly"]["normalized_vertices"][3]["x"] * image_width
        y_3 = object["bounding_poly"]["normalized_vertices"][3]["y"] * image_height
        score = object["score"]

        if (score >= 0.9):
            border_color = "green"
        elif (0.8 <= score < 0.9):
            border_color = "yellow"
        else:
            border_color = "red"

        object_data = {
            'x': round(x),
            'y': round(y),
            'x_1': round(x_1),
            'y_1': round(y_1),
            'x_2': round(x_2),
            'y_2': round(y_2),
            'x_3': round(x_3),
            'y_3': round(y_3),
            'name': object["name"],
            'score': object["score"],
            'margin_top': y_1,
            'margin_left': x,
            'border_width': x_1 - x,
            'border_height': y_2 - y_1,
            'border_color': border_color
        }
        data.append(object_data)

    return render_template('results.html', file=file, data=data, image_width=image_width, image_height=image_height)


@app.route('/', methods=['GET', 'POST'])
def get_list():
    return render_template('index.html')









if __name__ == '__main__':
    app.run()
