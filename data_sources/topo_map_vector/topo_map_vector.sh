#!/bin/bash
#
# Download USGS Topo Map Vector Data from https://viewer.nationalmap.gov/
#
# Due to the number of files, several lists of links were downloaded to
#  then download each one using wget

#All txt files have links to the zip files
for i in *.txt; do 
    #Remove GDB files
    sed -i '/GDB/d' $i
    wget -nc -np -c -i $i
done


#Today's date
script_date=$(date +'%Y-%m-%d')

####################
#First import
####################
unzip VECTOR_Zion_IL_7_5_Min_Shape.zip
cd Shape
shp2pgsql -g the_geom -s 4269:4326 Elev_Contour.shp topo_map_vector_elev > ../sql/elev.sql
#shp2pgsql -g the_geom -s 4269:4326 NHDPoint.shp topo_map_vector_nhdpoint > ../sql/nhdpoint.sql
shp2pgsql -g the_geom -s 4269:4326 GU_CountyOrEquivalent.shp topo_map_vector_county > ../sql/county.sql
shp2pgsql -g the_geom -s 4269:4326 GU_PLSSFirstDivision.shp topo_map_vector_firstdiv > ../sql/firstdiv.sql
shp2pgsql -g the_geom -s 4269:4326 NHDWaterbody.shp topo_map_vector_waterbody > ../sql/waterbody.sql
shp2pgsql -g the_geom -s 4269:4326 TNMDerivedNames.shp topo_map_vector_derivednames > ../sql/derivednames.sql

cd ../
rm -r Shape
cd sql
psql -U gisuser -h localhost gis < elev.sql
#psql -U gisuser -h localhost gis < nhdpoint.sql
psql -U gisuser -h localhost gis < county.sql
psql -U gisuser -h localhost gis < firstdiv.sql
psql -U gisuser -h localhost gis < waterbody.sql
psql -U gisuser -h localhost gis < derivednames.sql



#Move tables to HDD space
#As postgres user
alter table topo_map_vector_elev set tablespace slowdisk;
#alter table topo_map_vector_nhdpoint set tablespace slowdisk;
alter table topo_map_vector_county set tablespace slowdisk;
alter table topo_map_vector_firstdiv set tablespace slowdisk;
alter table topo_map_vector_waterbody set tablespace slowdisk;
alter table topo_map_vector_derivednames set tablespace slowdisk;

#Rename cols
psql -U gisuser -h localhost gis -c "ALTER TABLE topo_map_vector_county RENAME column source_d_1 TO source_des;"
psql -U gisuser -h localhost gis -c "ALTER TABLE topo_map_vector_derivednames ADD column globalid text;"
psql -U gisuser -h localhost gis -c "ALTER TABLE topo_map_vector_firstdiv RENAME column source_d_1 TO source_des;"
psql -U gisuser -h localhost gis -c "ALTER TABLE topo_map_vector_firstdiv ADD column globalid text;"
psql -U gisuser -h localhost gis -c "ALTER TABLE topo_map_vector_elev RENAME column source_d_1 TO source_des;"
psql -U gisuser -h localhost gis -c "ALTER TABLE topo_map_vector_waterbody DROP column the_geom;"
psql -U gisuser -h localhost gis -c "ALTER TABLE topo_map_vector_waterbody ADD column the_geom geometry(MultiPolygon, 4326);"

####################




#Turn datasource offline
psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 'f' WHERE datasource_id = 'topo_map_vector';"

mkdir bad_zips
mkdir sql
mkdir sql/elev
#mkdir sql/nhdpoint
mkdir sql/county
mkdir sql/firstdiv
mkdir sql/waterbody
mkdir sql/derived


for i in *.zip; do
    #unzip file
    unzip $i
    if [ $? -ne 0 ]; then
        mv $i bad_zips/
        rm -r Shape
        continue
    fi

    cd Shape
    #Create sql file, project to 4326
    shp2pgsql -g the_geom -a -s 4269:4326 Elev_Contour.shp topo_map_vector_elev > ../sql/elev/${i%.zip}_elev.sql
    
    #shp2pgsql -g the_geom -a -s 4269:4326 NHDPoint.shp topo_map_vector_nhdpoint > ../sql/nhdpoint/${i%.zip}_nhdpoint.sql

    shp2pgsql -g the_geom -a -s 4269:4326 GU_CountyOrEquivalent.shp topo_map_vector_county > ../sql/county/${i%.zip}_county.sql
    
    shp2pgsql -g the_geom -a -s 4269:4326 GU_PLSSFirstDivision.shp topo_map_vector_firstdiv > ../sql/firstdiv/${i%.zip}_firstdiv.sql

    shp2pgsql -g the_geom -a -s 4269:4326 NHDWaterbody.shp topo_map_vector_waterbody > ../sql/waterbody/${i%.zip}_waterbody.sql

    shp2pgsql -g the_geom -a -s 4269:4326 TNMDerivedNames.shp topo_map_vector_derivednames > ../sql/derived/${i%.zip}_derivednames.sql
    cd ..
    rm -r Shape
done

cd sql/



cd county
psql -U gisuser -h localhost gis -c "TRUNCATE topo_map_vector_county"
for i in *.sql; do
    #Load PostGIS files to database
    echo $i
    #Rename col
    sed -i 's/,\"source_d_1\",/,\"source_des\",/g' $i
    sed -i 's/,\"pop_2000\",/,\"population\",/g' $i
    psql -v ON_ERROR_STOP=1 -U gisuser -h localhost gis < $i
    if [ $? -ne 0 ]; then
        break
    fi
done
cd ..


cd derived
psql -U gisuser -h localhost gis -c "TRUNCATE topo_map_vector_derivednames"
for i in *.sql; do
    #Load PostGIS files to database
    echo $i
    #Rename col
    #sed -i 's/,\"source_d_1\",/,\"source_des\",/g' $i
    psql -v ON_ERROR_STOP=1 -U gisuser -h localhost gis < $i
    if [ $? -ne 0 ]; then
        break
    fi
done
cd ..


cd firstdiv
psql -U gisuser -h localhost gis -c "TRUNCATE topo_map_vector_firstdiv"
for i in *.sql; do
    #Load PostGIS files to database
    echo $i
    #Rename col
    sed -i 's/,\"source_d_1\",/,\"source_des\",/g' $i
    psql -v ON_ERROR_STOP=1 -U gisuser -h localhost gis < $i
    if [ $? -ne 0 ]; then
        break
    fi
done
cd ..


# cd nhdpoint
# psql -U gisuser -h localhost gis -c "TRUNCATE topo_map_vector_nhdpoint"
# for i in *.sql; do
#     #Load PostGIS files to database
#     echo $i
#     #Rename col
#     #sed -i 's/,\"source_d_1\",/,\"source_des\",/g' $i
#     psql -v ON_ERROR_STOP=1 -U gisuser -h localhost gis < $i
#     if [ $? -ne 0 ]; then
#         break
#     fi
# done
# cd ..


cd waterbody
psql -U gisuser -h localhost gis -c "TRUNCATE topo_map_vector_waterbody"
for i in *.sql; do
    #Load PostGIS files to database
    echo $i
    #Rename col
    sed -i 's/,\"source_d_1\",/,\"source_des\",/g' $i
    #Force to 2D
    sed -i 's/,ST_Transform(/,ST_Force2D(ST_Transform(/g' $i
    sed -i 's/ 4326));/ 4326)));/g' $i
    psql -v ON_ERROR_STOP=1 -U gisuser -h localhost gis < $i
    if [ $? -ne 0 ]; then
        break
    fi
    psql -v ON_ERROR_STOP=1 -U gisuser -h localhost gis -c "DELETE FROM topo_map_vector_waterbody WHERE gnis_name IS NULL"
    psql -v ON_ERROR_STOP=1 -U gisuser -h localhost gis -c "VACUUM topo_map_vector_waterbody"
done
cd ..


cd elev
psql -U gisuser -h localhost gis -c "TRUNCATE topo_map_vector_elev"
for i in *.sql; do
    #Load PostGIS files to database
    echo $i
    #Rename col
    sed -i 's/,\"source_d_1\",/,\"source_des\",/g' $i
    #Force to 2D
    sed -i 's/,ST_Transform(/,ST_Force2D(ST_Transform(/g' $i
    sed -i 's/ 4326));/ 4326)));/g' $i
    psql -v ON_ERROR_STOP=1 -U gisuser -h localhost gis < $i
    if [ $? -ne 0 ]; then
        break
    fi
done
#
psql -v ON_ERROR_STOP=1 -U gisuser -h localhost gis -c "CREATE INDEX topo_map_vector_elev_elev_idx ON topo_map_vector_elev USING BTREE(contourele);"
psql -v ON_ERROR_STOP=1 -U gisuser -h localhost gis -c "DELETE FROM topo_map_vector_elev WHERE RIGHT(contourele::int::text, 2) != '50' AND RIGHT(contourele::int::text, 2) != '00'"
psql -v ON_ERROR_STOP=1 -U gisuser -h localhost gis -c "VACUUM topo_map_vector_elev"
#
cd ..



psql -U gisuser -h localhost gis < post_insert.sql 

psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 't', source_date = '$script_date', no_features = sum(w.no_feats) FROM (select count(*) as no_feats from topo_map_vector_elev UNION select count(*) as no_feats from topo_map_vector_nhdpoint UNION select count(*) as no_feats from topo_map_vector_county UNION select count(*) as no_feats from topo_map_vector_firstdiv UNION select count(*) as no_feats from topo_map_vector_waterbody UNION select count(*) as no_feats from topo_map_vector_derivednames) w WHERE datasource_id = 'topo_map_vector';"
