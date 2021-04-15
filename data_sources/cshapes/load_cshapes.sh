#!/bin/bash
#
# Load the CShapes Dataset of Historical Country Boundaries
#
# v 2021-04-01
#

script_date=$(date +'%Y-%m-%d')

#http://nils.weidmann.ws/projects/cshapes

shp2pgsql -g the_geom -s 4326 -D cshapes.shp cshapes > cshapes.sql


#Turn datasource offline
psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 'f' WHERE datasource_id = 'cshapes';"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS cshapes CASCADE;"

#Create table
psql -U gisuser -h localhost gis < cshapes.sql

psql -U gisuser -h localhost gis -c "UPDATE cshapes SET the_geom = ST_MAKEVALID(the_geom) WHERE ST_ISVALID(the_geom) = 'f';"

psql -U gisuser -h localhost gis -c "ALTER TABLE cshapes ADD COLUMN uid uuid DEFAULT uuid_generate_v4();"

psql -U gisuser -h localhost gis -c "ALTER TABLE cshapes ADD COLUMN start_date date;"
psql -U gisuser -h localhost gis -c "ALTER TABLE cshapes ADD COLUMN end_date date;"

psql -U gisuser -h localhost gis -c "UPDATE cshapes SET start_date = CONCAT(cowsyear, '-', cowsmonth, '-', cowsday)::date WHERE cowsyear != -1;"
psql -U gisuser -h localhost gis -c "UPDATE cshapes SET end_date = CONCAT(coweyear, '-', cowemonth, '-', coweday)::date WHERE cowsyear != -1;"

psql -U gisuser -h localhost gis -c "
                CREATE INDEX cshapes_cname_idx ON cshapes USING btree(cntry_name);
                CREATE INDEX cshapes_isoname_idx ON cshapes USING btree(isoname);
                CREATE INDEX cshapes_uid_idx ON cshapes USING btree(uid);
                CREATE INDEX cshapes_date1_idx ON cshapes USING btree(start_date);
                CREATE INDEX cshapes_date2_idx ON cshapes USING btree(end_date);
                CREATE INDEX cshapes_the_geom_idx ON cshapes USING gist (the_geom);"


psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 't', source_date = '$script_date', no_features = w.no_feats FROM (select count(*) as no_feats from cshapes) w WHERE datasource_id = 'cshapes';"
