#!/bin/bash
#
# National Register of Historic Places
#
# Source: GDB from https://irma.nps.gov/DataStore/Reference/Profile/2210280
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
#         'usa_histplaces_points',
#         'National Register of Historic Places - points',
#         'https://irma.nps.gov/DataStore/Reference/Profile/2210280',
#         'A current, accurate spatial representation of all historic properties listed on the National Register of Historic Places. Citation: Stutts M. 2014. National Register of Historic Places. National Register properties are located throughout the United States and their associated territories around the globe. Points features.',
#         '2020-07-07',
#         'Every 12 months'
#     );
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
#         'usa_histplaces_poly',
#         'National Register of Historic Places - polygons',
#         'https://irma.nps.gov/DataStore/Reference/Profile/2210280',
#         'A current, accurate spatial representation of all historic properties listed on the National Register of Historic Places. Citation: Stutts M. 2014. National Register of Historic Places. National Register properties are located throughout the United States and their associated territories around the globe. Polygon features.',
#         '2020-07-07',
#         'Every 12 months'
#     );



#Today's date
script_date=$(date +'%Y-%m-%d')

#Turn datasource offline
psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 'f' WHERE datasource_id = 'usa_histplaces_points';"
psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 'f' WHERE datasource_id = 'usa_histplaces_poly';"


#Store old tables
# echo "Backing up usa_histplaces..."
# echo ""
# pg_dump -h localhost -U gisuser -t usa_histplaces gis > usa_histplaces_$script_date.dump.sql
# gzip usa_histplaces_$script_date.dump.sql &

# psql -U gisuser -h localhost gis -c "DROP TABLE usa_histplaces CASCADE;"


#Convert shapefiles to database
shp2pgsql -D -s 4326 -g the_geom Cultural_Resource_Building_Point.shp usa_histplaces_building_point | psql -h localhost -U gisuser -d gis
shp2pgsql -D -s 4326 -g the_geom Cultural_Resource_District_Polygon.shp usa_histplaces_district_poly | psql -h localhost -U gisuser -d gis
shp2pgsql -D -s 4326 -g the_geom Cultural_Resource_Site_Polygon.shp usa_histplaces_site_poly | psql -h localhost -U gisuser -d gis
shp2pgsql -D -s 4326 -g the_geom Cultural_Resource_Site_Point.shp usa_histplaces_site_point | psql -h localhost -U gisuser -d gis
shp2pgsql -D -s 4326 -g the_geom Cultural_Resource_Structure_Point.shp usa_histplaces_structure_point | psql -h localhost -U gisuser -d gis



#indices and new columns
psql -U gisuser -h localhost gis < post.sql


psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 't', source_date = '$script_date', no_features = w.no_feats FROM (select count(*) as no_feats from usa_histplaces_points) w WHERE datasource_id = 'usa_histplaces_points';"

psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 't', source_date = '$script_date', no_features = w.no_feats FROM (select count(*) as no_feats from usa_histplaces_poly) w WHERE datasource_id = 'usa_histplaces_poly';"




#del files
rm *.shp
rm *.dbf
rm *.cpg
rm *.sbx
rm *.shp.xml
rm *.prj
rm *.sbn
rm *.shx
