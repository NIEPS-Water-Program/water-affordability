# Living Data and Code for the Water Affordability Dashboard operated by the Nicholas Institute for Environmental Policy Solutions

Dashboard (desktop): https://www.nicholasinstitute.duke.edu/water-affordability/water-affordability-dashboard

Don't Panic Labs assisted in developing the map interface: https://dontpaniclabs.com/

Information about Project: https://www.nicholasinstitute.duke.edu/water-affordability/

## Folders

1. **data** folder contains the raw service area boundaries, census, and rates data needed to create the dashboard. Many of the census files are pulled dynamically from the r script and are not provided here. The **rates_data** are provided in csv format for each state in the dashboard. The metadata and templates are provided as well for those who wish to create a database for a state not yet represented. The **census_time** folder contains two spreadsheets needed for the dashboard to display population and unemployment change over time. These data are not needed for the affordability analysis.
3. **rcode** folder contains all the r code needed to obtain the data, estimate bills, calculate affordability metrics, and create files for the dashboard. The rscripts are numbered in the order they must be run for the code to work. Please refer to the workflow document provided.
4. **results** folder contains the results from the rscript. We do not include those files here because they are large. However, we provide the simplified versions used to develop the dashboard in the www folder. We provide the folder since it is necessary for the rcode to run correctly.
5. **www** folder contains the html, css, javascript, and data files used to create the affordability dashboard: https://www.nicholasinstitute.duke.edu/water-affordability/water-affordability-dashboard. Users will need to create their own api key and mapbox tiles.


## Terms of Use
1. Files in the data and rcode folder are licensed under the Creative Commons Attribution 4.0 International (CC BY 4.0: https://creativecommons.org/licenses/by/4.0/) by Duke University on behalf of the Nicholas Institute for Environmental Solutions.
2. Files in the www folder are licensed under MIT license.
3. Attribute the data, code, and dashboard as "Patterson, Lauren, Martin Doyle, Aislinn McLaughlin, and Sophia Bryson. 2021. Water Affordability Data Repository. Nicholas Institute for Environmental Policy Solutions at Duke University. https://github.com/NIEPS-Water-Program/water-affordability" or "NIEPS Water Affordability Data" for short, and the url: https://github.com/NIEPS-Water-Program/water-affordability.
4. For publications that use the data, please cite the following publication: "Patterson, LA and MW Doyle. 2021. Exploring the affordability of water services across and within utilities in the United States. Plos One. doi: 
5. 

forthcoming...

Shield: [![CC BY 4.0][cc-by-shield]][cc-by]

This work is licensed under a
[Creative Commons Attribution 4.0 International License][cc-by].

[![CC BY 4.0][cc-by-image]][cc-by]

[cc-by]: http://creativecommons.org/licenses/by/4.0/
[cc-by-image]: https://i.creativecommons.org/l/by/4.0/88x31.png
[cc-by-shield]: https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg


## Workflow....
forthcoming
