import sys, os
sys.path.insert(0, '/var/www/api')

os.chdir('/var/www/api')

from app import app as application
