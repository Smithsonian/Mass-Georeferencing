--birds
INSERT INTO data_sources (
    datasource_id,
    source_title,
    source_url,
    source_notes,
    source_date,
    source_refresh,
    no_features
)

VALUES
    (
        'iucn_birds',
        'Bird species distribution maps of the world',
        'http://datazone.birdlife.org/species/requestdis',
        'BirdLife International and Handbook of the Birds of the World. 2018. Bird species distribution maps of the world. Version 2018.1. Available at http://datazone.birdlife.org/species/requestdis.',
        '2019-11-10',
        'Every 12 months',
        17464
    );


--amphibians
INSERT INTO data_sources (
    datasource_id,
    source_title,
    source_url,
    source_notes,
    source_date,
    source_refresh,
    no_features
)

VALUES
    (
        'iucn',
        'IUCN Red List',
        'https://www.iucnredlist.org',
        'IUCN. 2019. The IUCN Red List of Threatened Species. https://www.iucnredlist.org. Downloaded on 10-10-2019.',
        '2019-10-10',
        'Every 12 months',
        30585
    );
