#!/bin/bash
#
# Contours of the Conterminous United States


#Today's date
script_date=$(date +'%Y-%m-%d')


# --
# INSERT INTO data_sources (
#     datasource_id,
#     source_title,
#     source_url,
#     source_notes,
#     source_date,
#     source_refresh
# )
# VALUES
#     (
#         'usa_contours',
#         'Contours of the Conterminous United States',
#         'http://nationalatlas.gov/atlasftp-1m.html',
#         'This map layer shows elevation contour lines for the conterminous United States.  The map layer was derived from the 100-meter resolution elevation data set which is published by the National Atlas of the United States.',
#         '2020-07-08',
#         'NA'
#     );



#Turn datasource offline
psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 'f' WHERE datasource_id = 'usa_contours';"



shp2pgsql -D -g the_geom contours_wgs84.shp usa_contours > usa_contours.sql

psql -U gisuser -h localhost gis < usa_contours.sql






psql -U gisuser -h localhost gis < post_insert.sql 

psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 't', source_date = '$script_date', no_features = w.no_feats FROM (select count(*) as no_feats from usa_contours) w WHERE datasource_id = 'usa_contours';"
