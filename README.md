# Mass-Georeferencing

System and workflows for the mass georeferencing of museum records using known localities from collections and spatial databases.

## Requirements

 * Linux Server
 * PostgreSQL with PostGIS
 * Python3
    * rapidfuzz
    * tqdm
    * pycountry
    * swifter
    * pandas
    * pyfiglet
    * psycopg2
    * nltk
 * R
    * shiny
    * shinyjs
    * leaflet
    * jsonlite
    * shinyWidgets
    * shinycssloaders
    * dplyr
    * sp
    * DT
    * rgbif
    * rmarkdown
 * shp2pgsql



## Approach

We are working on a system to test, develop, and showcase a new approach to allow to georeference museum records on a massive scale. This includes the setup of a set of tools by the institution's IT department, with help and input from GIS experts, to allow the collection staff to concentrate on the records instead of the overhead. For example, for the Smithsonian, the tasks would be divided between the IT team ([OCIO](https://www.si.edu/ocio "Office of the Chief Information Officer")) and the collection staff as:

![division of tasks](https://user-images.githubusercontent.com/2302171/87707101-934f5000-c76e-11ea-8484-9ca9682e3a17.png)

## Advantages
 * Web-based tools
   * Collection staff won't need a powerful workstation with ArcGIS/QGIS/GRASS, disk space for datasets, and large ammounts of RAM for performance 
 * Processing happens in the Data Center
 * Customizable for each Dept, Collection, or sub-Collection
 * Repeatable workflow with automated logging for error detection and correction
 * Exports a CIS-ready data package
   * Relevant data and spatial records included
 * Open source

![batch](https://user-images.githubusercontent.com/2302171/87707200-c09bfe00-c76e-11ea-9b90-566eb46946ef.png)

## Development

We have started to develop a system based on PostGIS. The UI is written in R/Shiny, but will be ported to Python to keep a consistent language across the components of the project. 

The current version of the UI allows the collection staff to browse each species, select a group of records and select the best match for that locality. 

![workflow_NMNH](https://user-images.githubusercontent.com/2302171/87707164-ad892e00-c76e-11ea-9b15-e24b5148042c.png)

## About

This is a project by the Digitization Program Office, OCIO, at the Smithsonian Institution.

![dpologo](https://user-images.githubusercontent.com/2302171/75351300-f00ca580-5875-11ea-89a6-cfa612395bc9.jpg)

Available under an Apache 2.0 License.
