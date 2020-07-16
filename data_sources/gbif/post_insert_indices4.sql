
CREATE INDEX gbif_15_species_trgm_idx ON gbif_15 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_15_species_idx ON gbif_15 USING BTREE(species);
CREATE INDEX gbif_15_genus_idx ON gbif_15 USING BTREE(genus);
CREATE INDEX gbif_15_locality_trgm_idx ON gbif_15 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_15_thegeom_idx ON gbif_15 USING gist (the_geom);
CREATE INDEX gbif_15_thegeomw_idx ON gbif_15 USING gist (the_geom_webmercator);
CREATE INDEX gbif_15_lon_idx ON gbif_15 USING btree(decimalLongitude);
CREATE INDEX gbif_15_lat_idx ON gbif_15 USING btree(decimalLatitude);
CLUSTER gbif_15 USING gbif_15_species_idx;

CREATE INDEX gbif_16_species_trgm_idx ON gbif_16 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_16_species_idx ON gbif_16 USING BTREE(species);
CREATE INDEX gbif_16_genus_idx ON gbif_16 USING BTREE(genus);
CREATE INDEX gbif_16_locality_trgm_idx ON gbif_16 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_16_thegeom_idx ON gbif_16 USING gist (the_geom);
CREATE INDEX gbif_16_thegeomw_idx ON gbif_16 USING gist (the_geom_webmercator);
CREATE INDEX gbif_16_lon_idx ON gbif_16 USING btree(decimalLongitude);
CREATE INDEX gbif_16_lat_idx ON gbif_16 USING btree(decimalLatitude);
CLUSTER gbif_16 USING gbif_16_species_idx;

CREATE INDEX gbif_17_species_trgm_idx ON gbif_17 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_17_species_idx ON gbif_17 USING BTREE(species);
CREATE INDEX gbif_17_genus_idx ON gbif_17 USING BTREE(genus);
CREATE INDEX gbif_17_locality_trgm_idx ON gbif_17 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_17_thegeom_idx ON gbif_17 USING gist (the_geom);
CREATE INDEX gbif_17_thegeomw_idx ON gbif_17 USING gist (the_geom_webmercator);
CREATE INDEX gbif_17_lon_idx ON gbif_17 USING btree(decimalLongitude);
CREATE INDEX gbif_17_lat_idx ON gbif_17 USING btree(decimalLatitude);
CLUSTER gbif_17 USING gbif_17_species_idx;

CREATE INDEX gbif_18_species_trgm_idx ON gbif_18 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_18_species_idx ON gbif_18 USING BTREE(species);
CREATE INDEX gbif_18_genus_idx ON gbif_18 USING BTREE(genus);
CREATE INDEX gbif_18_locality_trgm_idx ON gbif_18 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_18_thegeom_idx ON gbif_18 USING gist (the_geom);
CREATE INDEX gbif_18_thegeomw_idx ON gbif_18 USING gist (the_geom_webmercator);
CREATE INDEX gbif_18_lon_idx ON gbif_18 USING btree(decimalLongitude);
CREATE INDEX gbif_18_lat_idx ON gbif_18 USING btree(decimalLatitude);
CLUSTER gbif_18 USING gbif_18_species_idx;

CREATE INDEX gbif_19_species_trgm_idx ON gbif_19 USING gin (species gin_trgm_ops);
CREATE INDEX gbif_19_species_idx ON gbif_19 USING BTREE(species);
CREATE INDEX gbif_19_genus_idx ON gbif_19 USING BTREE(genus);
CREATE INDEX gbif_19_locality_trgm_idx ON gbif_19 USING gin (locality gin_trgm_ops);
CREATE INDEX gbif_19_thegeom_idx ON gbif_19 USING gist (the_geom);
CREATE INDEX gbif_19_thegeomw_idx ON gbif_19 USING gist (the_geom_webmercator);
CREATE INDEX gbif_19_lon_idx ON gbif_19 USING btree(decimalLongitude);
CREATE INDEX gbif_19_lat_idx ON gbif_19 USING btree(decimalLatitude);
CLUSTER gbif_19 USING gbif_19_species_idx;



CREATE INDEX gbif_15_taxokin_idx ON gbif_15 USING btree(kingdom);
CREATE INDEX gbif_15_taxophy_idx ON gbif_15 USING btree(phylum);
CREATE INDEX gbif_15_taxocla_idx ON gbif_15 USING btree(class);
CREATE INDEX gbif_15_taxoord_idx ON gbif_15 USING btree(_order);
CREATE INDEX gbif_15_taxofam_idx ON gbif_15 USING btree(family);
CREATE INDEX gbif_15_basisrec_idx ON gbif_15 USING btree(basisOfRecord);

CREATE INDEX gbif_16_taxokin_idx ON gbif_16 USING btree(kingdom);
CREATE INDEX gbif_16_taxophy_idx ON gbif_16 USING btree(phylum);
CREATE INDEX gbif_16_taxocla_idx ON gbif_16 USING btree(class);
CREATE INDEX gbif_16_taxoord_idx ON gbif_16 USING btree(_order);
CREATE INDEX gbif_16_taxofam_idx ON gbif_16 USING btree(family);
CREATE INDEX gbif_16_basisrec_idx ON gbif_16 USING btree(basisOfRecord);

CREATE INDEX gbif_17_taxokin_idx ON gbif_17 USING btree(kingdom);
CREATE INDEX gbif_17_taxophy_idx ON gbif_17 USING btree(phylum);
CREATE INDEX gbif_17_taxocla_idx ON gbif_17 USING btree(class);
CREATE INDEX gbif_17_taxoord_idx ON gbif_17 USING btree(_order);
CREATE INDEX gbif_17_taxofam_idx ON gbif_17 USING btree(family);
CREATE INDEX gbif_17_basisrec_idx ON gbif_17 USING btree(basisOfRecord);

CREATE INDEX gbif_18_taxokin_idx ON gbif_18 USING btree(kingdom);
CREATE INDEX gbif_18_taxophy_idx ON gbif_18 USING btree(phylum);
CREATE INDEX gbif_18_taxocla_idx ON gbif_18 USING btree(class);
CREATE INDEX gbif_18_taxoord_idx ON gbif_18 USING btree(_order);
CREATE INDEX gbif_18_taxofam_idx ON gbif_18 USING btree(family);
CREATE INDEX gbif_18_basisrec_idx ON gbif_18 USING btree(basisOfRecord);

CREATE INDEX gbif_19_taxokin_idx ON gbif_19 USING btree(kingdom);
CREATE INDEX gbif_19_taxophy_idx ON gbif_19 USING btree(phylum);
CREATE INDEX gbif_19_taxocla_idx ON gbif_19 USING btree(class);
CREATE INDEX gbif_19_taxoord_idx ON gbif_19 USING btree(_order);
CREATE INDEX gbif_19_taxofam_idx ON gbif_19 USING btree(family);
CREATE INDEX gbif_19_basisrec_idx ON gbif_19 USING btree(basisOfRecord);



VACUUM ANALYZE gbif_15;
VACUUM ANALYZE gbif_16;
VACUUM ANALYZE gbif_17;
VACUUM ANALYZE gbif_18;
VACUUM ANALYZE gbif_19;

