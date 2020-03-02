# Mass-Georeferencing

System and workflows for the mass georeferencing of museum records using known localities from collections and spatial databases.

## Approach

We are working on a system to test, develop, and showcase a new approach to allow to georeference museum records on a massive scale. This includes the setup of a set of tools by the institution's IT department, with help and input from GIS experts, to allow the collection staff to concentrate on the records instead of the overhead. For example, for the Smithsonian, the tasks would be divided between the IT team (OCIO) and the collection staff as:

![Georeferencing_IT](https://user-images.githubusercontent.com/2302171/75688119-e2d42a00-5c6c-11ea-87d1-e96d489d8334.png)

## Advantages
 * Web-based tools
   * Collection staff won't need a powerful workstation with ArcGIS/QGIS/GRASS, disk space for datasets, and large ammounts of RAM for performance 
 * Processing happens in the Data Center
 * Customizable for each Dept, Collection, or sub-Collection
 * Repeatable workflow with automated logging for error detection and correction
 * Exports a CIS-ready data package
   * Relevant data and spatial records included
 * Open source

## Development

We have started to develop a system based on PostGIS. The UI is written in R/Shiny, but will be ported to Python to keep a consistent language across the components of the project. 

![dpologo](https://user-images.githubusercontent.com/2302171/75351300-f00ca580-5875-11ea-89a6-cfa612395bc9.jpg)
