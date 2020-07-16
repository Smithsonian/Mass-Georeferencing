
CREATE INDEX gbif_05_species_trgm_idx ON gbif_05 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_05_species_idx ON gbif_05 USING BTREE(species);
CREATE INDEX gbif_05_genus_idx ON gbif_05 USING BTREE(genus);
CREATE INDEX gbif_05_locality_trgm_idx ON gbif_05 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_05_thegeom_idx ON gbif_05 USING gist (the_geom);
CREATE INDEX gbif_05_thegeomw_idx ON gbif_05 USING gist (the_geom_webmercator);
CREATE INDEX gbif_05_lon_idx ON gbif_05 USING btree(decimalLongitude);
CREATE INDEX gbif_05_lat_idx ON gbif_05 USING btree(decimalLatitude);
CLUSTER gbif_05 USING gbif_05_species_idx;

CREATE INDEX gbif_06_species_trgm_idx ON gbif_06 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_06_species_idx ON gbif_06 USING BTREE(species);
CREATE INDEX gbif_06_genus_idx ON gbif_06 USING BTREE(genus);
CREATE INDEX gbif_06_locality_trgm_idx ON gbif_06 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_06_thegeom_idx ON gbif_06 USING gist (the_geom);
CREATE INDEX gbif_06_thegeomw_idx ON gbif_06 USING gist (the_geom_webmercator);
CREATE INDEX gbif_06_lon_idx ON gbif_06 USING btree(decimalLongitude);
CREATE INDEX gbif_06_lat_idx ON gbif_06 USING btree(decimalLatitude);
CLUSTER gbif_06 USING gbif_06_species_idx;

CREATE INDEX gbif_07_species_trgm_idx ON gbif_07 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_07_species_idx ON gbif_07 USING BTREE(species);
CREATE INDEX gbif_07_genus_idx ON gbif_07 USING BTREE(genus);
CREATE INDEX gbif_07_locality_trgm_idx ON gbif_07 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_07_thegeom_idx ON gbif_07 USING gist (the_geom);
CREATE INDEX gbif_07_thegeomw_idx ON gbif_07 USING gist (the_geom_webmercator);
CREATE INDEX gbif_07_lon_idx ON gbif_07 USING btree(decimalLongitude);
CREATE INDEX gbif_07_lat_idx ON gbif_07 USING btree(decimalLatitude);
CLUSTER gbif_07 USING gbif_07_species_idx;

CREATE INDEX gbif_08_species_trgm_idx ON gbif_08 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_08_species_idx ON gbif_08 USING BTREE(species);
CREATE INDEX gbif_08_genus_idx ON gbif_08 USING BTREE(genus);
CREATE INDEX gbif_08_locality_trgm_idx ON gbif_08 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_08_thegeom_idx ON gbif_08 USING gist (the_geom);
CREATE INDEX gbif_08_thegeomw_idx ON gbif_08 USING gist (the_geom_webmercator);
CREATE INDEX gbif_08_lon_idx ON gbif_08 USING btree(decimalLongitude);
CREATE INDEX gbif_08_lat_idx ON gbif_08 USING btree(decimalLatitude);
CLUSTER gbif_08 USING gbif_08_species_idx;

CREATE INDEX gbif_09_species_trgm_idx ON gbif_09 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_09_species_idx ON gbif_09 USING BTREE(species);
CREATE INDEX gbif_09_genus_idx ON gbif_09 USING BTREE(genus);
CREATE INDEX gbif_09_locality_trgm_idx ON gbif_09 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_09_thegeom_idx ON gbif_09 USING gist (the_geom);
CREATE INDEX gbif_09_thegeomw_idx ON gbif_09 USING gist (the_geom_webmercator);
CREATE INDEX gbif_09_lon_idx ON gbif_09 USING btree(decimalLongitude);
CREATE INDEX gbif_09_lat_idx ON gbif_09 USING btree(decimalLatitude);
CLUSTER gbif_09 USING gbif_09_species_idx;


CREATE INDEX gbif_05_taxokin_idx ON gbif_05 USING btree(kingdom);
CREATE INDEX gbif_05_taxophy_idx ON gbif_05 USING btree(phylum);
CREATE INDEX gbif_05_taxocla_idx ON gbif_05 USING btree(class);
CREATE INDEX gbif_05_taxoord_idx ON gbif_05 USING btree(_order);
CREATE INDEX gbif_05_taxofam_idx ON gbif_05 USING btree(family);
CREATE INDEX gbif_05_basisrec_idx ON gbif_05 USING btree(basisOfRecord);

CREATE INDEX gbif_06_taxokin_idx ON gbif_06 USING btree(kingdom);
CREATE INDEX gbif_06_taxophy_idx ON gbif_06 USING btree(phylum);
CREATE INDEX gbif_06_taxocla_idx ON gbif_06 USING btree(class);
CREATE INDEX gbif_06_taxoord_idx ON gbif_06 USING btree(_order);
CREATE INDEX gbif_06_taxofam_idx ON gbif_06 USING btree(family);
CREATE INDEX gbif_06_basisrec_idx ON gbif_06 USING btree(basisOfRecord);

CREATE INDEX gbif_07_taxokin_idx ON gbif_07 USING btree(kingdom);
CREATE INDEX gbif_07_taxophy_idx ON gbif_07 USING btree(phylum);
CREATE INDEX gbif_07_taxocla_idx ON gbif_07 USING btree(class);
CREATE INDEX gbif_07_taxoord_idx ON gbif_07 USING btree(_order);
CREATE INDEX gbif_07_taxofam_idx ON gbif_07 USING btree(family);
CREATE INDEX gbif_07_basisrec_idx ON gbif_07 USING btree(basisOfRecord);

CREATE INDEX gbif_08_taxokin_idx ON gbif_08 USING btree(kingdom);
CREATE INDEX gbif_08_taxophy_idx ON gbif_08 USING btree(phylum);
CREATE INDEX gbif_08_taxocla_idx ON gbif_08 USING btree(class);
CREATE INDEX gbif_08_taxoord_idx ON gbif_08 USING btree(_order);
CREATE INDEX gbif_08_taxofam_idx ON gbif_08 USING btree(family);
CREATE INDEX gbif_08_basisrec_idx ON gbif_08 USING btree(basisOfRecord);

CREATE INDEX gbif_09_taxokin_idx ON gbif_09 USING btree(kingdom);
CREATE INDEX gbif_09_taxophy_idx ON gbif_09 USING btree(phylum);
CREATE INDEX gbif_09_taxocla_idx ON gbif_09 USING btree(class);
CREATE INDEX gbif_09_taxoord_idx ON gbif_09 USING btree(_order);
CREATE INDEX gbif_09_taxofam_idx ON gbif_09 USING btree(family);
CREATE INDEX gbif_09_basisrec_idx ON gbif_09 USING btree(basisOfRecord);



VACUUM ANALYZE gbif_05;
VACUUM ANALYZE gbif_06;
VACUUM ANALYZE gbif_07;
VACUUM ANALYZE gbif_08;
VACUUM ANALYZE gbif_09;

