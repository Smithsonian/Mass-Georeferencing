#!/bin/bash

python3 -m pip install -r requirements.txt

export FLASK_ENV=development

flask run
