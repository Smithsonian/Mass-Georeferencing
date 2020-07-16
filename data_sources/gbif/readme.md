# Load GBIF DarwinCore data dump

The script `gbif_load.sh` loads the GBIF occurrence records with locality and coordinates to a PostGIS database. The script ends up with 3 tables:

 * gbif: a partitioned table (20 partitions), by species name
 * gbif_datasets: table with the details of the dataset (institution, title, citation, etc)
 * gbif_plants_museums: a table with museum records of plant specimens
