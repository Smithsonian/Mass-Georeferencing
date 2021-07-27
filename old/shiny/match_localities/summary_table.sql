CREATE TABLE gbif_si_summary
(
    species text,
    kingdom text, 
    phylum text, 
    class text, 
    _order text, 
    family text, 
    genus text, 
    no_records int);


CREATE INDEX gbif_si_summary_sci_idx ON gbif_si_summary USING BTREE(species);
CREATE INDEX gbif_si_summary_kingdom_idx ON gbif_si_summary USING BTREE(kingdom);
CREATE INDEX gbif_si_summary_phylum_idx ON gbif_si_summary USING BTREE(phylum);
CREATE INDEX gbif_si_summary_class_idx ON gbif_si_summary USING BTREE(class);
CREATE INDEX gbif_si_summary_order_idx ON gbif_si_summary USING BTREE(_order);
CREATE INDEX gbif_si_summary_family_idx ON gbif_si_summary USING BTREE(family);
CREATE INDEX gbif_si_summary_genus_idx ON gbif_si_summary USING BTREE(genus);
