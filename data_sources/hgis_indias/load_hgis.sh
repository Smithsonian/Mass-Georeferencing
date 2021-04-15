#!/bin/bash
#
# Load the Places gazetteer of Spanish America, 1701-1808
#
# v 2021-04-01
#

script_date=$(date +'%Y-%m-%d')

shp2pgsql -g the_geom -s 4326 -D gazetteer-2019-03-28.shp hgis_indias > hgis_indias.sql


#Turn datasource offline
psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 'f' WHERE datasource_id = 'hgis_indias';"
psql -U gisuser -h localhost gis -c "DROP TABLE IF EXISTS hgis_indias CASCADE;"

#Create table
psql -U gisuser -h localhost gis < hgis_indias.sql

psql -U gisuser -h localhost gis -c "UPDATE hgis_indias SET the_geom = ST_MAKEVALID(the_geom) WHERE ST_ISVALID(the_geom) = 'f';"

psql -U gisuser -h localhost gis -c "ALTER TABLE hgis_indias ADD COLUMN uid uuid DEFAULT uuid_generate_v4();"

psql -U gisuser -h localhost gis -c "ALTER TABLE hgis_indias ADD COLUMN start_date date;"
psql -U gisuser -h localhost gis -c "ALTER TABLE hgis_indias ADD COLUMN end_date date;"

psql -U gisuser -h localhost gis -c "UPDATE hgis_indias SET start_date = CONCAT(start, '-01-01')::date;"
psql -U gisuser -h localhost gis -c "UPDATE hgis_indias SET end_date = CONCAT(end_, '-12-31')::date;"

psql -U gisuser -h localhost gis -c "
                CREATE INDEX hgis_indias_cname_idx ON hgis_indias USING btree(nombre);
                CREATE INDEX hgis_indias_uid_idx ON hgis_indias USING btree(uid);
                CREATE INDEX hgis_indias_date1_idx ON hgis_indias USING btree(start_date);
                CREATE INDEX hgis_indias_date2_idx ON hgis_indias USING btree(end_date);
                CREATE INDEX hgis_indias_the_geom_idx ON hgis_indias USING gist (the_geom);"


psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 't', source_date = '$script_date', no_features = w.no_feats FROM (select count(*) as no_feats from hgis_indias) w WHERE datasource_id = 'hgis_indias';"
