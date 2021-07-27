# Metadata in JSON for OpenRefine

# For administrative areas
metadata_admin = {
    "name": "DPO Reconciliation - Admin Areas",
    "defaultTypes": [
        {"id": "/admin/country",
         "name": "Countries"},
        {"id": "/admin/stateprovince",
         "name": "State or Province"},
        {"id": "/admin/other",
         "name": "Other political areas under state or province"},
        {"id": "/admin/historic_counties",
         "name": "Historical counties in the USA"},
        {"id": "/admin/country_iso2",
         "name": "ISO2 code of the country"},
        {"id": "/admin/country_iso3",
         "name": "ISO3 code of the country"}
    ],
    "view": {
        "url": "{{id}}"
    },
    "preview": {
        "height": 600,
        "url": "{{id}}",
        "width": 550
    }
}

# For scientific names
metadata_species = {
    "name": "DPO Reconciliation - Species",
    "defaultTypes": [
        {"id": "/species/gbif",
         "name": "GBIF Backbone Taxonomy flattened"}
    ],
    "view": {
        "url": "{{id}}"
    },
    "preview": {
        "height": 600,
        "url": "{{id}}",
        "width": 550
    }
}

metadata_aat = {
    "name": "DPO Reconciliation - AAT",
    "defaultTypes": [{"id": "/vocabularies/aat",
                      "name": "Thesaurus Terms"}],
    "view": {
        "url": "http://vocab.getty.edu/page/aat/{{id}}"
    },
    "preview": {
        "height": 400,
        "url": "https://dpogis.si.edu/AAT?aat={{id}}",
        "width": 500
    }
}
