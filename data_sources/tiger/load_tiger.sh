#!/bin/bash
#
#Get the OSM extracts from geofabrik.de and refresh the PostGIS database
# using osm2pgsql (https://wiki.openstreetmap.org/wiki/Osm2pgsql)
# 


#Today's date
script_date=$(date +'%Y-%m-%d')


#Tiger folders





#Turn datasource offline
psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 'f' WHERE datasource_id = 'tiger';"



# AREALM
#2019 TIGER/Line Shapefile Area Landmark State-based Shapefile
cd AREALM

#Empty table
psql -U gisuser -h localhost gis -c "TRUNCATE tiger_arealm;"
psql -U gisuser -h localhost gis -c "VACUUM tiger_arealm;"

#Download each file and load it to psql using osm2pgsql
for zipfile in *.zip; do
    echo ""
    echo "Working on file $zipfile..."
    echo ""
    
    unzip $zipfile

    shp2pgsql -a -g the_geom -D ${zipfile%.zip}.shp tiger_arealm > tiger_arealm.sql

    psql -U gisuser -h localhost gis < tiger_arealm.sql

    rm tiger_arealm.sql
    rm ${zipfile%.zip}.cpg
    rm ${zipfile%.zip}.dbf
    rm ${zipfile%.zip}.prj
    rm ${zipfile%.zip}*.xml
    rm ${zipfile%.zip}.shx

done

psql -U gisuser -h localhost gis -c "DELETE FROM tiger_arealm WHERE fullname IS NULL;"








# AREAWATER
#2019 TIGER/Line Shapefile Area Hydrography County-based Shapefile
cd AREAWATER

#Empty table
psql -U gisuser -h localhost gis -c "TRUNCATE tiger_areawater;"
psql -U gisuser -h localhost gis -c "VACUUM tiger_areawater;"


#unzip files
for zipfile in *.zip; do
    echo ""
    echo "Working on file $zipfile..."
    echo ""
    
    unzip -o $zipfile
    rm $zipfile
done


#nested zips
for zipfile in *.zip; do
    echo ""
    echo "Working on file $zipfile..."
    echo ""
    
    unzip -o $zipfile
    rm $zipfile
done



for shapefile in *.shp; do
    echo ""
    echo "Working on file $shapefile..."
    echo ""
    
    shp2pgsql -a -g the_geom -D $shapefile tiger_areawater > tiger_areawater.sql

    psql -U gisuser -h localhost gis < tiger_areawater.sql

    rm tiger_areawater.sql

done

psql -U gisuser -h localhost gis -c "DELETE FROM tiger_areawater WHERE fullname IS NULL;"












# COUNTY
#2019 TIGER Current County and Equivalent National Shapefile
cd AREALM

#Empty table
psql -U gisuser -h localhost gis -c "TRUNCATE tiger_counties;"
psql -U gisuser -h localhost gis -c "VACUUM tiger_counties;"

#Download each file and load it to psql using osm2pgsql
unzip tl_2019_us_county.zip

shp2pgsql -a -g the_geom -D tl_2019_us_county.shp tiger_counties > tiger_counties.sql

psql -U gisuser -h localhost gis < tiger_counties.sql






# ROADS
#2019 TIGER All Roads County-based Shapefile
cd ROADS

#Empty table
psql -U gisuser -h localhost gis -c "TRUNCATE tiger_roads;"
psql -U gisuser -h localhost gis -c "VACUUM tiger_roads;"


#unzip files
for zipfile in *.zip; do
    echo ""
    echo "Working on file $zipfile..."
    echo ""
    
    unzip -o $zipfile
    rm $zipfile
done


for shapefile in *.shp; do
    echo ""
    echo "Working on file $shapefile..."
    echo ""
    
    shp2pgsql -a -g the_geom -D $shapefile tiger_roads > tiger_roads.sql

    psql -U gisuser -h localhost gis < tiger_roads.sql

    rm tiger_roads.sql

done

psql -U gisuser -h localhost gis -c "DELETE FROM tiger_roads WHERE fullname IS NULL;"

psql -U gisuser -h localhost gis < post_insert.sql




#Turn datasource online
psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 't', source_date = '$script_date', no_features = w1.no_feats FROM (SELECT sum(w.no_feats) AS no_feats FROM (select count(*) as no_feats from tiger_roads UNION select count(*) as no_feats from tiger_counties UNION select count(*) as no_feats from tiger_areawater UNION select count(*) as no_feats from tiger_arealm) w) w1 WHERE datasource_id = 'tiger';"

