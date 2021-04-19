--
-- PostgreSQL database dump
--

-- Dumped from database version 10.16 (Ubuntu 10.16-1.pgdg18.04+1)
-- Dumped by pg_dump version 13.2 (Ubuntu 13.2-1.pgdg18.04+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

--
-- Name: data_sources; Type: TABLE; Schema: public; Owner: gisuser
--

CREATE TABLE public.data_sources (
    datasource_id text,
    source_title text,
    source_url text,
    source_notes text,
    source_date text,
    source_refresh text,
    is_online boolean DEFAULT true,
    no_features integer
);


ALTER TABLE public.data_sources OWNER TO gisuser;

--
-- Data for Name: data_sources; Type: TABLE DATA; Schema: public; Owner: gisuser
--

COPY public.data_sources (datasource_id, source_title, source_url, source_notes, source_date, source_refresh, is_online, no_features) FROM stdin;
wikidata	WikiData	https://www.wikidata.org	Wikidata is a free and open knowledge base that can be read and edited by both humans and machines.	2021-01-07	Every 6 months	t	36507154
iucn	IUCN Red List	https://www.iucnredlist.org	IUCN. 2019. The IUCN Red List of Threatened Species. https://www.iucnredlist.org. Downloaded on 10-10-2019.	2019-10-10	Every 36 months	t	30585
wdpa_points	WDPA - World Database on Protected Areas (points)	https://www.protectedplanet.net	The most up to date and complete source of information on protected areas, updated monthly with submissions from governments, non-governmental organizations, landowners and communities. It is managed by the United Nations Environment World Conservation Monitoring Centre (UNEP-WCMC) with support from IUCN and its World Commission on Protected Areas (WCPA).	2021-01-05	Every 12 months	t	12525
iucn_birds	Bird species distribution maps of the world	http://datazone.birdlife.org/species/requestdis	BirdLife International and Handbook of the Birds of the World. 2018. Bird species distribution maps of the world. Version 2018.1. Available at http://datazone.birdlife.org/species/requestdis.	2019-11-10	Every 36 months	t	17464
wdpa_polygons	WDPA - World Database on Protected Areas (polygons)	https://www.protectedplanet.net	The most up to date and complete source of information on protected areas, updated monthly with submissions from governments, non-governmental organizations, landowners and communities. It is managed by the United Nations Environment World Conservation Monitoring Centre (UNEP-WCMC) with support from IUCN and its World Commission on Protected Areas (WCPA).	2021-01-05	Every 12 months	t	246200
osm	OpenStreetMap - North America	http://www.openstreetmap.org/	OpenStreetMap is built by a community of mappers that contribute and maintain data about roads, trails, cafés, railway stations, and much more, all over the world.	2021-02-11	Every 12 months	t	2940926
gnis	Geographic Names Information System	https://www.usgs.gov/core-science-systems/ngp/board-on-geographic-names	The Geographic Names Information System (GNIS) is the Federal and national standard for geographic nomenclature.	2021-01-08	Every 6 months	t	2290435
gns	GEOnet Names Server	http://geonames.nga.mil/gns/html/	The GEOnet Names Server (GNS) is the official repository of standard spellings of all foreign geographic names, sanctioned by the United States Board on Geographic Names (US BGN).	2021-01-05	Every 6 months	t	13190177
hgis_indias	Places gazetteer of Spanish America, 1701-1808	https://doi.org/10.7910/DVN/FUSJD3	Temporal gazetteer of (populated) places existing in the Spanish American possessions, 1701-1808. 2019-03-28	2021-04-01	NA	t	15263
us_postoffices	US Post Offices (1639-2000)	https://cblevins.github.io/us-post-offices/data-biography/	US Post Offices was created by Cameron Blevins and Richard Helbock. It is a spatial-historical dataset containing records for 166,140 post offices that operated in the United States between 1639 and 2000.	2021-04-19	NA	t	112521
cshapes	CShapes Dataset of Historical Country Boundaries. v 0.6	http://nils.weidmann.ws/projects/cshapes	This is a GIS dataset of country boundaries, incorporating changes in the period 1946-2015. The list of states is compatible with the "Correlates of War" system membership list, version 2011.1, and the Gleditsch and Ward (1999) list of independent states.	2021-04-01	NA	t	255
tiger	TIGER/Line Shapefiles 2019	https://www.census.gov/geographies/mapping-files/time-series/geo/tiger-line-file.html	The TIGER/Line Shapefiles are the fully supported, core geographic product from the U.S. Census.	2020-04-03	Every 12 months	t	9777686
topo_map_vector	USGS Topo Map Vector Data	https://viewer.nationalmap.gov/	They contain feature classes from all TNM vector data themes, including Elevation Contours, Government Units (Boundaries), Woodland Tint polygons, Structures, Transportation, Hydrography, TNM Derived Names, and 7.5-minute map cells.	2020-07-07	Every 12 months	t	978639
usa_rivers	USA Rivers and Streams	https://hub.arcgis.com/datasets/esri::usa-rivers-and-streams	This layer presents the linear water features (for example, aqueducts, canals, intracoastal waterways, and streams) of the United States. Credit: Esri, National Atlas of the United States, United States Geological Survey	2020-07-07	Every 12 months	t	76243
usgs_geology	Geologic maps of US states	https://mrdata.usgs.gov/geology/state/	The State Geologic Map Compilation geodatabase of the conterminous United States represents a seamless, spatial database of 48 State geologic maps. A national digital geologic map database is essential in interpreting other datasets that support numerous types of national-scale studies and assessments, such as those that provide geochemistry, remote sensing, or geophysical data.	2020-04-07	Every 12 months	t	313732
usa_histplaces_points	National Register of Historic Places - points	https://irma.nps.gov/DataStore/Reference/Profile/2210280	A current, accurate spatial representation of all historic properties listed on the National Register of Historic Places. Citation: Stutts M. 2014. National Register of Historic Places. National Register properties are located throughout the United States and their associated territories around the globe. Points features.	2020-07-07	Every 12 months	t	64423
usa_histplaces_poly	National Register of Historic Places - polygons	https://irma.nps.gov/DataStore/Reference/Profile/2210280	A current, accurate spatial representation of all historic properties listed on the National Register of Historic Places. Citation: Stutts M. 2014. National Register of Historic Places. National Register properties are located throughout the United States and their associated territories around the globe. Polygon features.	2020-07-07	Every 12 months	t	13310
usgs_nhd_waterbody	USGS National Hydrography - Waterbodies (published 2020-06-27)	https://www.usgs.gov/core-science-systems/ngp/national-hydrography	The National Hydrography Dataset (NHD) is a feature-based database that interconnects and uniquely identifies the stream segments or reaches that make up the nation''s surface water drainage system.	2020-07-07	Every 12 months	t	1271526
hist_counties	Atlas of Historical County Boundaries	https://publications.newberry.org/ahcbp/	A project of the William M. Scholl Center for American History and Culture at The Newberry Library in Chicago, the Atlas of Historical County Boundaries is a powerful historical research and reference tool in electronic form. The Atlas presents in maps and text complete data about the creation and all subsequent changes (dated to the day) in the size, shape, and location of every county in the fifty United States and the District of Columbia. 	2020-06-16	NA	t	17727
usa_contours	Contours of the Conterminous United States	http://nationalatlas.gov/atlasftp-1m.html	This map layer shows elevation contour lines for the conterminous United States.  The map layer was derived from the 100-meter resolution elevation data set which is published by the National Atlas of the United States.	2020-07-08	NA	t	369202
usgs_nat_struct	USGS National Structures Dataset	http://nationalmap.usgs.gov	Features of this dataset are various private and public man-made structures and installations.	2020-07-08	Every 12 months	t	433402
geonames	GeoNames	https://www.geonames.org/	The GeoNames geographical database covers all countries and contains over eleven million placenames that are available for download free of charge.	2021-01-04	Every 6 months	t	12062960
global_lakes	Global Lakes and Wetlands Database	https://www.worldwildlife.org/pages/global-lakes-and-wetlands-database	Lehner, B. and Döll, P. 2004. Development and validation of a global database of lakes, reservoirs and wetlands. Journal of Hydrology 296: 1-22.	2020-07-10	NA	t	3721
gbif	GBIF Occurrence Download 10.15468/dl.z9d39t	https://www.gbif.org	The Global Biodiversity Information Facility (GBIF) is an international network and research infrastructure funded by the world’s governments and aimed at providing anyone, anywhere, open access to data about all types of life on Earth. Only using records with coordinates and localities specified.	2021-01-01	Every 6 months	t	1135718472
gadm	Database of Global Administrative Areas. v 3.6	https://gadm.org	GADM wants to map the administrative areas of all countries, at all levels of sub-division. It uses high spatial resolution, and of a extensive set of attributes. v 3.6.	2020-12-21	Every 12 months	t	386735
\.


--
-- Name: data_sources_source_id_idx; Type: INDEX; Schema: public; Owner: gisuser
--

CREATE INDEX data_sources_source_id_idx ON public.data_sources USING btree (datasource_id);


--
-- Name: TABLE data_sources; Type: ACL; Schema: public; Owner: gisuser
--

GRANT SELECT ON TABLE public.data_sources TO gisuser_ro;


--
-- PostgreSQL database dump complete
--
