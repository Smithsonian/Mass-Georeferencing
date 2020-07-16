DROP TABLE IF EXISTS gbif_datasets CASCADE;

--Datasets table
CREATE TABLE gbif_datasets (
    datasetKey uuid,
    title text,
    organizationName text,
    rights text,
    doi text,
    date text,
    citation text, 
    license text,
    pubDate text
    );

CREATE INDEX gbif_datasets_dataskey_idx on gbif_datasets USING BTREE(datasetKey);

\COPY gbif_datasets FROM 'gbifdatasets.csv' CSV HEADER DELIMITER '|';
