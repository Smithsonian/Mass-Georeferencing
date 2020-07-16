
UPDATE iucn SET kingdom = UPPER(left(kingdom, 1)) || LOWER(right(kingdom, -1));
UPDATE iucn SET phylum = UPPER(left(phylum, 1)) || LOWER(right(phylum, -1));        
UPDATE iucn SET class = UPPER(left(class, 1)) || LOWER(right(class, -1));
UPDATE iucn SET order_ = UPPER(left(order_, 1)) || LOWER(right(order_, -1));
UPDATE iucn SET family = UPPER(left(family, 1)) || LOWER(right(family, -1));
UPDATE iucn SET genus = UPPER(left(genus, 1)) || LOWER(right(genus, -1));

CREATE INDEX iucn_sciname_idx ON iucn USING gin (sciname gin_trgm_ops);
CREATE INDEX iucn_redlist_cat_idx ON iucn USING BTREE(redlist_cat);
CREATE INDEX iucn_kingdom_idx ON iucn USING BTREE(kingdom);
CREATE INDEX iucn_phylum_idx ON iucn USING BTREE(phylum);
CREATE INDEX iucn_class_idx ON iucn USING BTREE(class);
CREATE INDEX iucn_order_idx ON iucn USING BTREE(order_);
CREATE INDEX iucn_family_idx ON iucn USING BTREE(family);
CREATE INDEX iucn_genus_idx ON iucn USING BTREE(genus);
CREATE INDEX iucn_the_geom_idx ON iucn USING GIST(the_geom);


ALTER TABLE iucn ADD COLUMN the_geom_webmercator geometry;
UPDATE iucn SET the_geom_webmercator = ST_transform(the_geom, 3857);
CREATE INDEX iucn_the_geomw_idx ON iucn USING GIST(the_geom_webmercator);