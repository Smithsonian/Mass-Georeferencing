-----------------------------
--Post insert indexing
-----------------------------

CREATE INDEX gbif_00_species_trgm_idx ON gbif_00 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_00_species_idx ON gbif_00 USING BTREE(species);
CREATE INDEX gbif_00_genus_idx ON gbif_00 USING BTREE(genus);
CREATE INDEX gbif_00_locality_trgm_idx ON gbif_00 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_00_thegeom_idx ON gbif_00 USING gist (the_geom);
CREATE INDEX gbif_00_thegeomw_idx ON gbif_00 USING gist (the_geom_webmercator);
CREATE INDEX gbif_00_lon_idx ON gbif_00 USING btree(decimalLongitude);
CREATE INDEX gbif_00_lat_idx ON gbif_00 USING btree(decimalLatitude);
CLUSTER gbif_00 USING gbif_00_species_idx;

CREATE INDEX gbif_01_species_trgm_idx ON gbif_01 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_01_species_idx ON gbif_01 USING BTREE(species);
CREATE INDEX gbif_01_genus_idx ON gbif_01 USING BTREE(genus);
CREATE INDEX gbif_01_locality_trgm_idx ON gbif_01 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_01_thegeom_idx ON gbif_01 USING gist (the_geom);
CREATE INDEX gbif_01_thegeomw_idx ON gbif_01 USING gist (the_geom_webmercator);
CREATE INDEX gbif_01_lon_idx ON gbif_01 USING btree(decimalLongitude);
CREATE INDEX gbif_01_lat_idx ON gbif_01 USING btree(decimalLatitude);
CLUSTER gbif_01 USING gbif_01_species_idx;

CREATE INDEX gbif_02_species_trgm_idx ON gbif_02 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_02_species_idx ON gbif_02 USING BTREE(species);
CREATE INDEX gbif_02_genus_idx ON gbif_02 USING BTREE(genus);
CREATE INDEX gbif_02_locality_trgm_idx ON gbif_02 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_02_thegeom_idx ON gbif_02 USING gist (the_geom);
CREATE INDEX gbif_02_thegeomw_idx ON gbif_02 USING gist (the_geom_webmercator);
CREATE INDEX gbif_02_lon_idx ON gbif_02 USING btree(decimalLongitude);
CREATE INDEX gbif_02_lat_idx ON gbif_02 USING btree(decimalLatitude);
CLUSTER gbif_02 USING gbif_02_species_idx;

CREATE INDEX gbif_03_species_trgm_idx ON gbif_03 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_03_species_idx ON gbif_03 USING BTREE(species);
CREATE INDEX gbif_03_genus_idx ON gbif_03 USING BTREE(genus);
CREATE INDEX gbif_03_locality_trgm_idx ON gbif_03 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_03_thegeom_idx ON gbif_03 USING gist (the_geom);
CREATE INDEX gbif_03_thegeomw_idx ON gbif_03 USING gist (the_geom_webmercator);
CREATE INDEX gbif_03_lon_idx ON gbif_03 USING btree(decimalLongitude);
CREATE INDEX gbif_03_lat_idx ON gbif_03 USING btree(decimalLatitude);
CLUSTER gbif_03 USING gbif_03_species_idx;

CREATE INDEX gbif_04_species_trgm_idx ON gbif_04 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_04_species_idx ON gbif_04 USING BTREE(species);
CREATE INDEX gbif_04_genus_idx ON gbif_04 USING BTREE(genus);
CREATE INDEX gbif_04_locality_trgm_idx ON gbif_04 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_04_thegeom_idx ON gbif_04 USING gist (the_geom);
CREATE INDEX gbif_04_thegeomw_idx ON gbif_04 USING gist (the_geom_webmercator);
CREATE INDEX gbif_04_lon_idx ON gbif_04 USING btree(decimalLongitude);
CREATE INDEX gbif_04_lat_idx ON gbif_04 USING btree(decimalLatitude);
CLUSTER gbif_04 USING gbif_04_species_idx;




--More indices, taxonomy and basis of record
CREATE INDEX gbif_00_taxokin_idx ON gbif_00 USING btree(kingdom);
CREATE INDEX gbif_00_taxophy_idx ON gbif_00 USING btree(phylum);
CREATE INDEX gbif_00_taxocla_idx ON gbif_00 USING btree(class);
CREATE INDEX gbif_00_taxoord_idx ON gbif_00 USING btree(_order);
CREATE INDEX gbif_00_taxofam_idx ON gbif_00 USING btree(family);
CREATE INDEX gbif_00_basisrec_idx ON gbif_00 USING btree(basisOfRecord);

CREATE INDEX gbif_01_taxokin_idx ON gbif_01 USING btree(kingdom);
CREATE INDEX gbif_01_taxophy_idx ON gbif_01 USING btree(phylum);
CREATE INDEX gbif_01_taxocla_idx ON gbif_01 USING btree(class);
CREATE INDEX gbif_01_taxoord_idx ON gbif_01 USING btree(_order);
CREATE INDEX gbif_01_taxofam_idx ON gbif_01 USING btree(family);
CREATE INDEX gbif_01_basisrec_idx ON gbif_01 USING btree(basisOfRecord);

CREATE INDEX gbif_02_taxokin_idx ON gbif_02 USING btree(kingdom);
CREATE INDEX gbif_02_taxophy_idx ON gbif_02 USING btree(phylum);
CREATE INDEX gbif_02_taxocla_idx ON gbif_02 USING btree(class);
CREATE INDEX gbif_02_taxoord_idx ON gbif_02 USING btree(_order);
CREATE INDEX gbif_02_taxofam_idx ON gbif_02 USING btree(family);
CREATE INDEX gbif_02_basisrec_idx ON gbif_02 USING btree(basisOfRecord);

CREATE INDEX gbif_03_taxokin_idx ON gbif_03 USING btree(kingdom);
CREATE INDEX gbif_03_taxophy_idx ON gbif_03 USING btree(phylum);
CREATE INDEX gbif_03_taxocla_idx ON gbif_03 USING btree(class);
CREATE INDEX gbif_03_taxoord_idx ON gbif_03 USING btree(_order);
CREATE INDEX gbif_03_taxofam_idx ON gbif_03 USING btree(family);
CREATE INDEX gbif_03_basisrec_idx ON gbif_03 USING btree(basisOfRecord);

CREATE INDEX gbif_04_taxokin_idx ON gbif_04 USING btree(kingdom);
CREATE INDEX gbif_04_taxophy_idx ON gbif_04 USING btree(phylum);
CREATE INDEX gbif_04_taxocla_idx ON gbif_04 USING btree(class);
CREATE INDEX gbif_04_taxoord_idx ON gbif_04 USING btree(_order);
CREATE INDEX gbif_04_taxofam_idx ON gbif_04 USING btree(family);
CREATE INDEX gbif_04_basisrec_idx ON gbif_04 USING btree(basisOfRecord);



--VACUUM
VACUUM ANALYZE gbif_00;
VACUUM ANALYZE gbif_01;
VACUUM ANALYZE gbif_02;
VACUUM ANALYZE gbif_03;
VACUUM ANALYZE gbif_04;





