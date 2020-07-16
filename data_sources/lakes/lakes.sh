#!/bin/bash
#
# Download shapefile from https://www.worldwildlife.org/publications/global-lakes-and-wetlands-database-large-lake-polygons-level-1
#
#


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
#         'global_lakes',
#         'Global Lakes and Wetlands Database',
#         'https://www.worldwildlife.org/pages/global-lakes-and-wetlands-database',
#         'Lehner, B. and Döll, P. 2004. Development and validation of a global database of lakes, reservoirs and wetlands. Journal of Hydrology 296: 1-22.',
#         '2020-02-07',
#         'Every 12 months'
#     );

#Today's date
script_date=$(date +'%Y-%m-%d')

#Turn datasource offline
psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 'f' WHERE datasource_id = 'global_lakes';"


#Store old tables
echo "Backing up global_lakes..."
echo ""
pg_dump -h localhost -U gisuser -t global_lakes gis > global_lakes_$script_date.dump.sql
gzip global_lakes_$script_date.dump.sql &

psql -U gisuser -h localhost gis -c "DROP TABLE global_lakes CASCADE;"

#Convert shapefile to database
shp2pgsql -D -s 4326 -g the_geom glwd_1.shp global_lakes | psql -h localhost -U gisuser -d gis

#indices and new columns
psql -U gisuser -h localhost gis < lakes_post.sql

psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 't', source_date = '$script_date', no_features = w.no_feats FROM (select count(*) as no_feats from global_lakes) w WHERE datasource_id = 'global_lakes';"


#del files
rm global_lakes.sql
rm glwd_1.*
rm GLWD_Data_*.pdf
