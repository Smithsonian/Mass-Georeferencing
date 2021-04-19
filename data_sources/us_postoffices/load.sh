#!/bin/bash
#
# Load the US Post Offices dataset (1639-2000)
#
# v 2021-04-19
#

script_date=$(date +'%Y-%m-%d')


psql -U gisuser -h localhost gis < data_tables.sql


psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 't', source_date = '$script_date', no_features = w.no_feats FROM (select count(*) as no_feats from us_postoffices) w WHERE datasource_id = 'us_postoffices';"
