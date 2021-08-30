# Living Data and Code for the Water Affordability Dashboard operated by the Nicholas Institute for Environmental Policy Solutions

Dashboard (desktop): https://nicholasinstitute.duke.edu/water-affordability/water-affordability-dashboard

Don't Panic Labs assisted in creating mapbox tiles: https://dontpaniclabs.com/

Information about Project: https://nicholasinstitute.duke.edu/water-affordability/

Current release version and doi: <a href="https://zenodo.org/badge/latestdoi/385713868"><img src="https://zenodo.org/badge/385713868.svg" alt="DOI"></a>

## Folders

1. **data** folder contains the raw service area boundaries, census, and rates data needed to create the dashboard. Many of the census files are pulled dynamically from the r script and are not provided here. The **rates_data** are provided in csv format for each state in the dashboard. The metadata and templates are provided as well for those who wish to create a database for a state not yet represented. The **census_time** folder contains two spreadsheets needed for the dashboard to display population and unemployment change over time. These data are not needed for the affordability analysis.
2. **rcode** folder contains all the r code needed to obtain the data, estimate bills, calculate affordability metrics, and create files for the dashboard. The rscripts are numbered in the order they must be run for the code to work. Please refer to the workflow document provided.
3. **results** folder contains the results from the rscript. We do not include those files here because they are large. However, we provide the simplified versions used to develop the dashboard in the www folder. We provide the folder since it is necessary for the rcode to run correctly.
4. **www** folder contains the data used to create the dashboard. The dashboard was built using html, css, and javascript. We also used mapbox tilesets and apis. Users will need to obtain their own API keys and create their own tilesets for use.

## Versions

1. Data that matches forthcoming paper. Includes: CA, PA, NC, part of TX, and 9 utilities in OR. There are 1,800 utilities in the data.
2. Added remaining utilities in TX, NJ, and NM. There are 2,349 utilities in the data.


## Terms of Use
1. Files in the data and rcode folder are licensed under the Creative Commons Attribution 4.0 International (CC BY 4.0: https://creativecommons.org/licenses/by/4.0/) by Duke University on behalf of the Nicholas Institute for Environmental Solutions.
2. Files in the www folder are licensed under MIT license.
3. Attribute the data, code, and dashboard as "Patterson, Lauren, Martin Doyle, Aislinn McLaughlin, and Sophia Bryson. 2021. Water Affordability Data Repository. Nicholas Institute for Environmental Policy Solutions at Duke University. https://github.com/NIEPS-Water-Program/water-affordability" or "NIEPS Water Affordability Data" for short, and the url: https://github.com/NIEPS-Water-Program/water-affordability. You may include the current release version with it's associated doi: 10.5281/zenodo.5156654.
<a href="https://zenodo.org/badge/latestdoi/385713868"><img src="https://zenodo.org/badge/385713868.svg" alt="DOI"></a>

5. We currently have a paper in review that we will ask to be cited for authors using these data in publications. We will provide those details once the paper is accepted.

6. This work is licensed under a
[Creative Commons Attribution 4.0 International License][cc-by].[![CC BY 4.0][cc-by-image]][cc-by]

Shield: [![CC BY 4.0][cc-by-shield]][cc-by]

[cc-by]: http://creativecommons.org/licenses/by/4.0/
[cc-by-image]: https://i.creativecommons.org/l/by/4.0/88x31.png
[cc-by-shield]: https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg




## Workflow
The process of creating the dashboard is detaield in the pdf: "Workflow for Creating Water Affordability Dashboard". Briefly, we manually collected rates data and used Rcran to access census and water service area boundaries. We combined the rates and census data with the service area boundaries to calculate affordability metrics in Rcran. The data are visualized using html and javascript. The process is illustrated in the figure below.

![process-overview](https://user-images.githubusercontent.com/15807329/126791513-2b65c0f9-956f-4aca-9dae-c2ae87e3cd6f.png)



