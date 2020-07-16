#!/bin/bash
#
# Load the GBIF Backbone Taxonomy
#

#Today's date
script_date=$(date +'%Y-%m-%d')

#Download current taxonomy
wget http://rs.gbif.org/datasets/backbone/backbone-current.zip

unzip backbone-current.zip

#psql -U gisuser -h localhost gis -c "UPDATE data_sources SET is_online = 'f' WHERE datasource_id = 'gbif_taxonomy';"

#Setup tables
psql -U gisuser -h localhost gis < gbif_taxo_tables.sql


sed -i '1d' Description.tsv
sed -i 's.\\./.g' Description.tsv
psql -U gisuser -h localhost gis -c "\copy gbif_taxonomy_description FROM 'Description.tsv';"

sed -i '1d' Distribution.tsv
sed -i 's.\\./.g' Distribution.tsv
psql -U gisuser -h localhost gis -c "\copy gbif_taxonomy_distribution FROM 'Distribution.tsv';"

sed -i '1d' Multimedia.tsv
sed -i 's.\\./.g' Multimedia.tsv
psql -U gisuser -h localhost gis -c "\copy gbif_taxonomy_multimedia FROM 'Multimedia.tsv';"

sed -i '1d' Reference.tsv
sed -i 's.\\./.g' Reference.tsv
psql -U gisuser -h localhost gis -c "\copy gbif_taxonomy_reference FROM 'Reference.tsv';"

sed -i '1d' Taxon.tsv
sed -i 's.\\./.g' Taxon.tsv
psql -U gisuser -h localhost gis -c "\copy gbif_taxonomy_taxon FROM 'Taxon.tsv';"
psql -U gisuser -h localhost gis -c "ALTER TABLE gbif_taxonomy_taxon ADD COLUMN datasetID uuid DEFAULT NULL;"
psql -U gisuser -h localhost gis -c "UPDATE gbif_taxonomy_taxon SET datasetID = datasetID1::uuid WHERE datasetID1 != '';"
psql -U gisuser -h localhost gis -c "CREATE INDEX gbif_taxonomy_taxon_did_idx ON gbif_taxonomy_taxon USING BTREE(datasetID);"
psql -U gisuser -h localhost gis -c "ALTER TABLE gbif_taxonomy_taxon DROP COLUMN datasetID1;"


sed -i '1d' TypesAndSpecimen.tsv
sed -i 's.\\./.g' TypesAndSpecimen.tsv
psql -U gisuser -h localhost gis -c "\copy gbif_taxonomy_typesspecimens FROM 'TypesAndSpecimen.tsv';"

sed -i '1d' VernacularName.tsv
sed -i 's.\\./.g' VernacularName.tsv
psql -U gisuser -h localhost gis -c "\copy gbif_taxonomy_vernacularname FROM 'VernacularName.tsv';"



#Extract dataset info
cp gbifdatasets.py dataset/
cd dataset/
python3 gbifdatasets.py
mv gbifdatasets.csv ../
cd ../
psql -U gisuser -h localhost gis -c "\COPY gbif_taxonomy_datasets FROM 'gbifdatasets.csv' CSV HEADER DELIMITER '|';"
rm gbifdatasets.csv
rm -r dataset

