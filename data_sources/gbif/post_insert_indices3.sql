
CREATE INDEX gbif_10_species_trgm_idx ON gbif_10 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_10_species_idx ON gbif_10 USING BTREE(species);
CREATE INDEX gbif_10_genus_idx ON gbif_10 USING BTREE(genus);
CREATE INDEX gbif_10_locality_trgm_idx ON gbif_10 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_10_thegeom_idx ON gbif_10 USING gist (the_geom);
CREATE INDEX gbif_10_thegeomw_idx ON gbif_10 USING gist (the_geom_webmercator);
CREATE INDEX gbif_10_lon_idx ON gbif_10 USING btree(decimalLongitude);
CREATE INDEX gbif_10_lat_idx ON gbif_10 USING btree(decimalLatitude);
CLUSTER gbif_10 USING gbif_10_species_idx;

CREATE INDEX gbif_11_species_trgm_idx ON gbif_11 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_11_species_idx ON gbif_11 USING BTREE(species);
CREATE INDEX gbif_11_genus_idx ON gbif_11 USING BTREE(genus);
CREATE INDEX gbif_11_locality_trgm_idx ON gbif_11 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_11_thegeom_idx ON gbif_11 USING gist (the_geom);
CREATE INDEX gbif_11_thegeomw_idx ON gbif_11 USING gist (the_geom_webmercator);
CREATE INDEX gbif_11_lon_idx ON gbif_11 USING btree(decimalLongitude);
CREATE INDEX gbif_11_lat_idx ON gbif_11 USING btree(decimalLatitude);
CLUSTER gbif_11 USING gbif_11_species_idx;

CREATE INDEX gbif_12_species_trgm_idx ON gbif_12 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_12_species_idx ON gbif_12 USING BTREE(species);
CREATE INDEX gbif_12_genus_idx ON gbif_12 USING BTREE(genus);
CREATE INDEX gbif_12_locality_trgm_idx ON gbif_12 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_12_thegeom_idx ON gbif_12 USING gist (the_geom);
CREATE INDEX gbif_12_thegeomw_idx ON gbif_12 USING gist (the_geom_webmercator);
CREATE INDEX gbif_12_lon_idx ON gbif_12 USING btree(decimalLongitude);
CREATE INDEX gbif_12_lat_idx ON gbif_12 USING btree(decimalLatitude);
CLUSTER gbif_12 USING gbif_12_species_idx;

CREATE INDEX gbif_13_species_trgm_idx ON gbif_13 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_13_species_idx ON gbif_13 USING BTREE(species);
CREATE INDEX gbif_13_genus_idx ON gbif_13 USING BTREE(genus);
CREATE INDEX gbif_13_locality_trgm_idx ON gbif_13 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_13_thegeom_idx ON gbif_13 USING gist (the_geom);
CREATE INDEX gbif_13_thegeomw_idx ON gbif_13 USING gist (the_geom_webmercator);
CREATE INDEX gbif_13_lon_idx ON gbif_13 USING btree(decimalLongitude);
CREATE INDEX gbif_13_lat_idx ON gbif_13 USING btree(decimalLatitude);
CLUSTER gbif_13 USING gbif_13_species_idx;

CREATE INDEX gbif_14_species_trgm_idx ON gbif_14 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_14_species_idx ON gbif_14 USING BTREE(species);
CREATE INDEX gbif_14_genus_idx ON gbif_14 USING BTREE(genus);
CREATE INDEX gbif_14_locality_trgm_idx ON gbif_14 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_14_thegeom_idx ON gbif_14 USING gist (the_geom);
CREATE INDEX gbif_14_thegeomw_idx ON gbif_14 USING gist (the_geom_webmercator);
CREATE INDEX gbif_14_lon_idx ON gbif_14 USING btree(decimalLongitude);
CREATE INDEX gbif_14_lat_idx ON gbif_14 USING btree(decimalLatitude);
CLUSTER gbif_14 USING gbif_14_species_idx;



CREATE INDEX gbif_10_taxokin_idx ON gbif_10 USING btree(kingdom);
CREATE INDEX gbif_10_taxophy_idx ON gbif_10 USING btree(phylum);
CREATE INDEX gbif_10_taxocla_idx ON gbif_10 USING btree(class);
CREATE INDEX gbif_10_taxoord_idx ON gbif_10 USING btree(_order);
CREATE INDEX gbif_10_taxofam_idx ON gbif_10 USING btree(family);
CREATE INDEX gbif_10_basisrec_idx ON gbif_10 USING btree(basisOfRecord);

CREATE INDEX gbif_11_taxokin_idx ON gbif_11 USING btree(kingdom);
CREATE INDEX gbif_11_taxophy_idx ON gbif_11 USING btree(phylum);
CREATE INDEX gbif_11_taxocla_idx ON gbif_11 USING btree(class);
CREATE INDEX gbif_11_taxoord_idx ON gbif_11 USING btree(_order);
CREATE INDEX gbif_11_taxofam_idx ON gbif_11 USING btree(family);
CREATE INDEX gbif_11_basisrec_idx ON gbif_11 USING btree(basisOfRecord);

CREATE INDEX gbif_12_taxokin_idx ON gbif_12 USING btree(kingdom);
CREATE INDEX gbif_12_taxophy_idx ON gbif_12 USING btree(phylum);
CREATE INDEX gbif_12_taxocla_idx ON gbif_12 USING btree(class);
CREATE INDEX gbif_12_taxoord_idx ON gbif_12 USING btree(_order);
CREATE INDEX gbif_12_taxofam_idx ON gbif_12 USING btree(family);
CREATE INDEX gbif_12_basisrec_idx ON gbif_12 USING btree(basisOfRecord);

CREATE INDEX gbif_13_taxokin_idx ON gbif_13 USING btree(kingdom);
CREATE INDEX gbif_13_taxophy_idx ON gbif_13 USING btree(phylum);
CREATE INDEX gbif_13_taxocla_idx ON gbif_13 USING btree(class);
CREATE INDEX gbif_13_taxoord_idx ON gbif_13 USING btree(_order);
CREATE INDEX gbif_13_taxofam_idx ON gbif_13 USING btree(family);
CREATE INDEX gbif_13_basisrec_idx ON gbif_13 USING btree(basisOfRecord);

CREATE INDEX gbif_14_taxokin_idx ON gbif_14 USING btree(kingdom);
CREATE INDEX gbif_14_taxophy_idx ON gbif_14 USING btree(phylum);
CREATE INDEX gbif_14_taxocla_idx ON gbif_14 USING btree(class);
CREATE INDEX gbif_14_taxoord_idx ON gbif_14 USING btree(_order);
CREATE INDEX gbif_14_taxofam_idx ON gbif_14 USING btree(family);
CREATE INDEX gbif_14_basisrec_idx ON gbif_14 USING btree(basisOfRecord);




VACUUM ANALYZE gbif_10;
VACUUM ANALYZE gbif_11;
VACUUM ANALYZE gbif_12;
VACUUM ANALYZE gbif_13;
VACUUM ANALYZE gbif_14;
