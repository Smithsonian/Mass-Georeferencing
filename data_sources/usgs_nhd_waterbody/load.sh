#!/bin/bash
#
# USGS National Hydrography in FileGDB 10.1 format (published 20200627)
# usgs_hydro
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
#         'usgs_nhd_waterbody',
#         'USGS National Hydrography (published 2020-06-27)',
#         'https://www.usgs.gov/core-science-systems/ngp/national-hydrography',
#         'The National Hydrography Dataset (NHD) is a feature-based database that interconnects and uniquely identifies the stream segments or reaches that make up the nation''s surface water drainage system.',
#         '2020-07-08',
#         'Every 12 months'
#     );

#Today's date
script_date=$(date +'%Y-%m-%d')

#Turn datasource offline
psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 'f' WHERE datasource_id = 'usgs_nhd_waterbody';"


cd wget
wget -nc -c -i list.txt



psql -U gisuser -h localhost gis -c "DELETE FROM usgs_nhd_waterbody;"
psql -U gisuser -h localhost gis -c "VACUUM usgs_nhd_waterbody;"
#/home/villanueval/H/Data/SpatialData/NHD_H_National_GDB/wget
for i in /home/villanueval/H/Data/SpatialData/NHD_H_National_GDB/wget/*.zip; do
    unzip $i Shape/NHDWaterbody*
    for j in Shape/NHDWaterbody*; do
        shp2pgsql -g the_geom -s 4269:4326 -a $j usgs_nhd_waterbody > usgs_nhd_waterbody.sql
        sed -i 's/,ST_Transform(/,ST_Force2D(ST_Transform(/g' usgs_nhd_waterbody.sql
        sed -i 's/ 4326));/ 4326)));/g' usgs_nhd_waterbody.sql    
        psql -U gisuser -h localhost gis < usgs_nhd_waterbody.sql
        rm usgs_nhd_waterbody.sql
    done
    rm -r Shape
done



#psql -U gisuser -h localhost gis -c "WITH data AS (SELECT gid, ST_Force2D(ST_TRANSFORM(geom, 4269, 4326)) as geom from usgs_nhd_waterbody) UPDATE usgs_nhd_waterbody u SET the_geom = d.geom FROM data d where u.gid = d.gid;"
#-s 4269:4326
#psql -U gisuser -h localhost gis -c "UPDATE nhd_waterbody SET the_geom = ST_Force2D(geom);"


#indices and new columns
psql -U gisuser -h localhost gis < post.sql

psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 't', source_date = '$script_date', no_features = w.no_feats FROM (select count(*) as no_feats from usgs_nhd_waterbody) w WHERE datasource_id = 'usgs_nhd_waterbody';"

