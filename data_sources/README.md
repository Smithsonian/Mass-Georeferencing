# Data Sources

Scripts to extract, scrub, and insert to the database multiple geographical datasets.

## List of sources

 * [Database of Global Administrative Areas](https://gadm.org) - GADM wants to map the administrative areas of all countries, at all levels of sub-division. It uses high spatial resolution, and of a extensive set of attributes.
 * [Global Biodiversity Information Facility (GBIF)](https://gbif.org) - The Global Biodiversity Information Facility is an international network and research infrastructure funded by the world’s governments and aimed at providing anyone, anywhere, open access to data about all types of life on Earth.
 * [GeoNames](https://www.geonames.org/) - The GeoNames geographical database covers all countries and contains over eleven million placenames that are available for download free of charge.
 * [Global Lakes and Wetlands Database](https://www.worldwildlife.org/pages/global-lakes-and-wetlands-database) - Global database of lakes, reservoirs and wetlands.
 * [Geographic Names Information System](https://www.usgs.gov/core-science-systems/ngp/board-on-geographic-names) - The Geographic Names Information System (GNIS) is the Federal and national standard for geographic nomenclature.
 * [GEOnet Names Server](http://geonames.nga.mil/gns/html/) - The GEOnet Names Server (GNS) is the official repository of standard spellings of all foreign geographic names, sanctioned by the United States Board on Geographic Names (US BGN).
 * [Atlas of Historical County Boundaries](https://publications.newberry.org/ahcbp/) - A project of the William M. Scholl Center for American History and Culture at The Newberry Library in Chicago, the Atlas of Historical County Boundaries is a powerful historical research and reference tool in electronic form. The Atlas presents in maps and text complete data about the creation and all subsequent changes (dated to the day) in the size, shape, and location of every county in the fifty United States and the District of Columbia.
 * [IUCN Red List](https://www.iucnredlist.org/) - The IUCN Red List of Threatened Species.
 * [Bird species distribution maps of the world](http://datazone.birdlife.org/species/requestdis) - Bird species distribution maps of the world.
 * [OpenStreetMap](http://www.openstreetmap.org/) - OpenStreetMap is built by a community of mappers that contribute and maintain data about roads, trails, cafés, railway stations, and much more, all over the world.
 * [TIGER/Line Shapefiles 2019](https://www.census.gov/geographies/mapping-files/time-series/geo/tiger-line-file.html) - The TIGER/Line Shapefiles are the fully supported, core geographic product from the U.S. Census.
 * [USGS Topo Map Vector Data](https://viewer.nationalmap.gov/) - Feature classes from all TNM vector data themes, including Elevation Contours, Government Units (Boundaries), Woodland Tint polygons, Structures, Transportation, Hydrography, TNM Derived Names, and 7.5-minute map cells.
 * [Contours of the Conterminous United States](http://nationalatlas.gov/atlasftp-1m.html) - This map layer shows elevation contour lines for the conterminous United States. The map layer was derived from the 100-meter resolution elevation data set which is published by the National Atlas of the United States. 
 * [National Register of Historic Places](https://irma.nps.gov/DataStore/Reference/Profile/2210280) - A current, accurate spatial representation of all historic properties listed on the National Register of Historic Places. Citation: Stutts M. 2014. National Register of Historic Places. National Register properties are located throughout the United States and their associated territories around the globe.
 * [USA Rivers and Streams](https://hub.arcgis.com/datasets/esri::usa-rivers-and-streams) - This layer presents the linear water features (for example, aqueducts, canals, intracoastal waterways, and streams) of the United States.
 * [Geologic maps of US states](https://mrdata.usgs.gov/geology/state/) - The State Geologic Map Compilation geodatabase of the conterminous United States represents a seamless, spatial database of 48 State geologic maps. A national digital geologic map database is essential in interpreting other datasets that support numerous types of national-scale studies and assessments, such as those that provide geochemistry, remote sensing, or geophysical data. 
 * [USGS National Structures Dataset](http://nationalmap.usgs.gov/) - Features of this dataset are various private and public man-made structures and installations.
 * [USGS National Hydrography - Waterbodies](https://www.usgs.gov/core-science-systems/ngp/national-hydrography) - The National Hydrography Dataset (NHD) is a feature-based database that interconnects and uniquely identifies the stream segments or reaches that make up the nation's surface water drainage system.
 * [World Database on Protected Areas](https://www.protectedplanet.net) - The most up to date and complete source of information on protected areas, updated monthly with submissions from governments, non-governmental organizations, landowners and communities. It is managed by the United Nations Environment World Conservation Monitoring Centre (UNEP-WCMC) with support from IUCN and its World Commission on Protected Areas (WCPA).
 * [WikiData](https://www.wikidata.org) - Wikidata is a free and open knowledge base that can be read and edited by both humans and machines.

## Data loading scripts

These scripts have been tested to load the current dataset to a PostgreSQL 10.10 server with the PostGIS package version 2.4. The server is running on Ubuntu 18.04. 
