CREATE INDEX gbif_taxonomy_description_tid_idx ON gbif_taxonomy_description USING BTREE(taxonID);
CREATE INDEX gbif_taxonomy_distribution_tid_idx ON gbif_taxonomy_distribution USING BTREE(taxonID);

CREATE INDEX gbif_taxonomy_multimedia_tid_idx ON gbif_taxonomy_multimedia USING BTREE(taxonID);

CREATE INDEX gbif_taxonomy_reference_tid_idx ON gbif_taxonomy_reference USING BTREE(taxonID);
CREATE INDEX gbif_taxonomy_taxon_tid_idx ON gbif_taxonomy_taxon USING BTREE(taxonID);
CREATE INDEX gbif_taxonomy_typesspecimens_tid_idx ON gbif_taxonomy_typesspecimens USING BTREE(taxonID);
CREATE INDEX gbif_taxonomy_vernacularname_tid_idx ON gbif_taxonomy_vernacularname USING BTREE(taxonID);
CREATE INDEX gbif_taxonomy_vernacularname_vname_idx ON gbif_taxonomy_vernacularname USING gin (vernacularName gin_trgm_ops);
CREATE INDEX gbif_taxonomy_datasets_idx on gbif_taxonomy_datasets USING BTREE(datasetKey);
CREATE INDEX gbif_vernacularnames_taxonid_idx ON gbif_vernacularnames USING BTREE(taxonID);
CREATE INDEX gbif_vernacularnames_sciname_idx ON gbif_vernacularnames USING BTREE(scientificName);
CREATE INDEX gbif_vernacularnames_generic_idx ON gbif_vernacularnames USING BTREE(genericName);
CREATE INDEX gbif_vernacularnames_taxonRank_idx ON gbif_vernacularnames USING BTREE(taxonRank);
CREATE INDEX gbif_vernacularnames_kingdom_idx ON gbif_vernacularnames USING BTREE(kingdom);
CREATE INDEX gbif_vernacularnames_phylum_idx ON gbif_vernacularnames USING BTREE(phylum);
CREATE INDEX gbif_vernacularnames_class_idx ON gbif_vernacularnames USING BTREE(class);
CREATE INDEX gbif_vernacularnames_order_idx ON gbif_vernacularnames USING BTREE(_order);
CREATE INDEX gbif_vernacularnames_family_idx ON gbif_vernacularnames USING BTREE(family);
CREATE INDEX gbif_vernacularnames_genus_idx ON gbif_vernacularnames USING BTREE(genus);
CREATE INDEX gbif_vernacularnames_vname_idx ON gbif_vernacularnames USING BTREE(vernacularName);
CREATE INDEX gbif_vernacularnames_lang_idx ON gbif_vernacularnames USING BTREE(language);
CREATE INDEX gbif_vernacularnames_ccode_idx ON gbif_vernacularnames USING BTREE(countryCode);
CREATE INDEX gbif_vernacularnames_source_idx ON gbif_vernacularnames USING BTREE(source);

CREATE INDEX gbif_taxonomy_taxon_rank_idx ON gbif_taxonomy_taxon USING BTREE(taxonrank);
CREATE INDEX gbif_taxonomy_taxon_canonname_idx ON gbif_taxonomy_taxon USING gin(canonicalname gin_trgm_ops);
CREATE INDEX gbif_taxonomy_taxon_sciname_idx ON gbif_taxonomy_taxon USING gin(scientificname gin_trgm_ops);
ALTER TABLE gbif_taxonomy_taxon ADD COLUMN uid uuid DEFAULT uuid_generate_v4();
CREATE INDEX gbif_taxonomy_taxon_uid_idx ON gbif_taxonomy_taxon USING btree (uid);
