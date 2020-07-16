#!/usr/bin/env python3
#
# Match SI GBIF records without coordinates to other GBIF records for the species/genus
#
import psycopg2, psycopg2.extras

#Import settings
import settings


conn = psycopg2.connect(host = settings.pg_host, database = settings.pg_db, user = settings.pg_user, connect_timeout = 60)

conn.autocommit = True
cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)


cur.execute("SET statement_timeout to '5s'")

cur.execute("SELECT wdpaid FROM wdpa_polygons where gadm2 is null")
ids = cur.fetchall()
for id in ids:
    print(id)
    #cur.execute("show statement_timeout;")
    #print(cur.fetchone())
    try:
        cur.execute("UPDATE wdpa_polygons geo SET gadm2 = g.name_2 || ', ' || g.name_1 || ', ' || g.name_0 FROM gadm2 g WHERE ST_INTERSECTS(geo.the_geom, g.the_geom) and geo.gadm2 is null AND geo.wdpaid = %(id)s", {'id': id['wdpaid']})
    except:
        continue



cur.execute("SET statement_timeout to '45s'")

cur.execute("SELECT wdpaid FROM wdpa_polygons where gadm2 is null")
ids = cur.fetchall()
for id in ids:
    print(id)
    #cur.execute("show statement_timeout;")
    #print(cur.fetchone())
    try:
        cur.execute("UPDATE wdpa_polygons geo SET gadm2 = g.name_2 || ', ' || g.name_1 || ', ' || g.name_0 FROM gadm2 g WHERE ST_INTERSECTS(geo.the_geom, g.the_geom) and geo.gadm2 is null AND geo.wdpaid = %(id)s", {'id': id['wdpaid']})
    except:
        continue
