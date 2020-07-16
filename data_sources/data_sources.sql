
--Table for data source
CREATE TABLE data_sources (
    datasource_id text,
    source_title text,
    source_url text,
    source_notes text,
    source_date date,
    source_refresh text,
    is_online bool DEFAULT 'T',
    no_features int DEFAULT NULL
);

CREATE INDEX data_sources_datasource_id_idx ON data_sources USING BTREE(datasource_id);



--wdpa_polygons
INSERT INTO data_sources (
    datasource_id,
    source_title,
    source_url,
    source_notes,
    source_refresh
)

VALUES
    (
        'wdpa_polygons',
        'WDPA - World Database on Protected Areas (polygons)',
        'https://www.protectedplanet.net',
        'The most up to date and complete source of information on protected areas, updated monthly with submissions from governments, non-governmental organizations, landowners and communities. It is managed by the United Nations Environment World Conservation Monitoring Centre (UNEP-WCMC) with support from IUCN and its World Commission on Protected Areas (WCPA).',
        'Every 3 months'
    );


--wdpa_points
INSERT INTO data_sources (
    datasource_id,
    source_title,
    source_url,
    source_notes,
    source_refresh
)

VALUES
    (
        'wdpa_points',
        'WDPA - World Database on Protected Areas (points)',
        'https://www.protectedplanet.net',
        'The most up to date and complete source of information on protected areas, updated monthly with submissions from governments, non-governmental organizations, landowners and communities. It is managed by the United Nations Environment World Conservation Monitoring Centre (UNEP-WCMC) with support from IUCN and its World Commission on Protected Areas (WCPA).',
        'Every 3 months'
    );



--gadm
INSERT INTO data_sources (
    datasource_id,
    source_title,
    source_url,
    source_notes,
    source_refresh
)

VALUES
    (
        'gadm',
        'Database of Global Administrative Areas',
        'https://gadm.org',
        'GADM wants to map the administrative areas of all countries, at all levels of sub-division. It uses high spatial resolution, and of a extensive set of attributes.',
        'Every 3 months'
    );


--wikidata
INSERT INTO data_sources (
    datasource_id,
    source_title,
    source_url,
    source_notes,
    source_refresh
)

VALUES
    (
        'wikidata',
        'WikiData',
        'https://www.wikidata.org',
        'Wikidata is a free and open knowledge base that can be read and edited by both humans and machines.',
        'Every month'
    );


--gbif
INSERT INTO data_sources (
    datasource_id,
    source_title,
    source_url,
    source_notes,
    source_refresh
)

VALUES
    (
        'gbif',
        'GBIF Occurrence Download https://doi.org/10.15468/dl.aqxh9w',
        'https://www.gbif.org',
        'GBIF—the Global Biodiversity Information Facility—is an international network and research infrastructure funded by the world’s governments and aimed at providing anyone, anywhere, open access to data about all types of life on Earth.',
        'Every 3 months'
    );


--
INSERT INTO data_sources (
    datasource_id,
    source_title,
    source_url,
    source_notes,
    source_refresh
)

VALUES
    (
        'osm',
        'OpenStreetMap',
        'http://www.openstreetmap.org/',
        'OpenStreetMap is built by a community of mappers that contribute and maintain data about roads, trails, cafés, railway stations, and much more, all over the world.',
        'Every 3 months'
    );


--geonames
INSERT INTO data_sources (
    datasource_id,
    source_title,
    source_url,
    source_notes,
    source_refresh
)

VALUES
    (
        'geonames',
        'GeoNames',
        'https://www.geonames.org/',
        'The GeoNames geographical database covers all countries and contains over eleven million placenames that are available for download free of charge.',
        'Every 3 months'
    );


--gnis
INSERT INTO data_sources (
    datasource_id,
    source_title,
    source_url,
    source_notes,
    source_refresh
)

VALUES
    (
        'gnis',
        'Geographic Names Information System',
        'https://www.usgs.gov/core-science-systems/ngp/board-on-geographic-names',
        'The Geographic Names Information System (GNIS) is the Federal and national standard for geographic nomenclature.',
        'Every 3 months'
    );



--bhl
INSERT INTO data_sources (
    datasource_id,
    source_title,
    source_url,
    source_notes,
    source_refresh
)

VALUES
    (
        'bhl',
        'Biodiversity Heritage Library',
        'https://www.biodiversitylibrary.org/',
        'The Biodiversity Heritage Library improves research methodology by collaboratively making biodiversity literature openly available to the world as part of a global biodiversity community.',
        'Every 3 months'
    );

