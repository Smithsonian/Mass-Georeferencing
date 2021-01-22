#!/usr/bin/env python3
#
# Match SI GBIF records without coordinates to other GBIF records for the species/genus
#
import psycopg2, psycopg2.extras, pycountry

#Import settings
import settings


conn = psycopg2.connect(host = settings.pg_host, database = settings.pg_db, user = settings.pg_user, connect_timeout = 60)

conn.autocommit = True
cur = conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)


cur.execute("SET statement_timeout to '5s'")

cur.execute("SELECT wdpaid FROM wdpa_polygons ORDER BY wdpaid")
ids = cur.fetchall()
for id in ids:
    print(id)
    try:
        cur.execute("UPDATE wdpa_polygons geo SET gadm2 = g.name_2 || ', ' || g.name_1 || ', ' || g.name_0 FROM gadm2 g WHERE ST_INTERSECTS(geo.the_geom, g.the_geom) and geo.gadm2 is null AND geo.wdpaid = %(id)s", {'id': id['wdpaid']})
        cur.execute("UPDATE wdpa_polygons w SET uncertainty_m = round((ST_MinimumBoundingRadius(st_transform(st_simplify(w.the_geom, 0.005), '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs'))).radius) FROM utm_zones u WHERE uncertainty_m is null AND w.wdpaid = %(id)s AND st_intersects(w.the_geom, u.the_geom);", {'id': id['wdpaid']})
    except:
        continue


#Queries that take longer, just in case
cur.execute("SET statement_timeout to '45s'")

cur.execute("SELECT wdpaid FROM wdpa_polygons ORDER BY wdpaid")
ids = cur.fetchall()
for id in ids:
    print(id)
    try:
        cur.execute("UPDATE wdpa_polygons geo SET gadm2 = g.name_2 || ', ' || g.name_1 || ', ' || g.name_0 FROM gadm2 g WHERE ST_INTERSECTS(geo.the_geom, g.the_geom) and geo.gadm2 is null AND geo.wdpaid = %(id)s", {'id': id['wdpaid']})
        cur.execute("UPDATE wdpa_polygons w SET uncertainty_m = round((ST_MinimumBoundingRadius(st_transform(st_simplify(w.the_geom, 0.005), '+proj=utm +zone=' || u.zone || ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs'))).radius) FROM utm_zones u WHERE uncertainty_m is null AND w.wdpaid = %(id)s AND st_intersects(w.the_geom, u.the_geom);", {'id': id['wdpaid']})
    except:
        continue



#Add country by parent_iso
cur.execute("SET statement_timeout to '5s'")

cur.execute("SELECT wdpaid FROM wdpa_polygons WHERE gadm2 IS NULL ORDER BY wdpaid")
ids = cur.fetchall()
for id in ids:
    print(id)
    try:
        cur.execute("SELECT parent_iso FROM wdpa_polygons WHERE wdpaid = %(id)s", {'id': id['wdpaid']})
        isocode = cur.fetchone()
        cur.execute("UPDATE wdpa_polygons SET gadm2 = %(country)s WHERE wdpaid = %(id)s", {'country': pycountry.countries.get(alpha_3 = isocode['parent_iso']).name, 'id': id['wdpaid']})
    except:
        continue

cur.execute("SET statement_timeout to '5s'")

cur.execute("SELECT wdpaid FROM wdpa_points WHERE gadm2 IS NULL ORDER BY wdpaid")
ids = cur.fetchall()
for id in ids:
    print(id)
    try:
        cur.execute("SELECT parent_iso FROM wdpa_points WHERE wdpaid = %(id)s", {'id': id['wdpaid']})
        isocode = cur.fetchone()
        cur.execute("UPDATE wdpa_points SET gadm2 = %(country)s WHERE wdpaid = %(id)s", {'country': pycountry.countries.get(alpha_3 = isocode['parent_iso']).name, 'id': id['wdpaid']})
    except:
        continue


#Indices
cur.execute("CREATE INDEX wdpa_polygons_gadm2_idx ON wdpa_polygons USING gin (gadm2 gin_trgm_ops)")


