# Living Data and Code for the Water Affordability Dashboard operated by the Nicholas Institute for Environmental Policy Solutions

Dashboard (desktop): https://nicholasinstitute.duke.edu/water-affordability/water-affordability-dashboard

Don't Panic Labs assisted in creating mapbox tiles: https://dontpaniclabs.com/

Information about Project: https://nicholasinstitute.duke.edu/water-affordability/

Paper explaining methods: http://dx.doi.org/10.1002/aws2.1260

Current release version and doi: <a href="https://zenodo.org/badge/latestdoi/385713868"><img src="https://zenodo.org/badge/385713868.svg" alt="DOI"></a>

## Folders

1. **data** folder contains the raw service area boundaries, census, and rates data needed to create the dashboard. Many of the census files are pulled dynamically from the r script and are not provided here. The **rates_data** are provided in csv format for each state in the dashboard. The metadata and templates are provided as well for those who wish to create a database for a state not yet represented. The **census_time** folder contains two spreadsheets needed for the dashboard to display population and unemployment change over time. These data are not needed for the affordability analysis.
2. **rcode** folder contains all the r code needed to obtain the data, estimate bills, calculate affordability metrics, and create files for the dashboard. The rscripts are numbered in the order they must be run for the code to work. Please refer to the workflow document provided.
3. **results** folder contains the results from the rscript. We do not include those files here because they are large. However, we provide the simplified versions used to develop the dashboard in the www folder. We provide the folder since it is necessary for the rcode to run correctly.
4. **www** folder contains the data used to create the dashboard. The dashboard was built using html, css, and javascript. We also used mapbox tilesets and apis. Users will need to obtain their own API keys and create their own tilesets for use.

## Versions

1. v2021-1.0: Data that matches our <a href="http://dx.doi.org/10.1002/aws2.1260">paper</a>. Includes: CA, PA, NC, part of TX, and 9 utilities in OR. There are 1,800 utilities in the data.
2. v2021-2.0: Added remaining utilities in TX, NJ, and NM. There are 2,349 utilities in the data.
3. v2021-3.2: Added utilities in CT, KS, and WA. There are 3,038 utilities represented here. Methods were updated to allow for the inclusion of local minimum wages based on  Version 3.0 and 3.1 are nearly identical but were removed due to syncing challenges with Zenodo.


## Terms of Use
The copyrights of the Water Affordability Dashboard software and website are owned by Duke University. Developed by Lauren Patterson and Martin Doyle at the Duke Nicholas Institute for Environmental Policy Solutions.
Use of this software and dataset is allowed for noncommercial purposes only. 

The Water Affordability Dashboard project relies on four components:
1. The data/rates/ are shared under a Creative Commons CC-BY-NC-ND-4.0 license.
License: https://creativecommons.org/licenses/by-nc-nd/4.0/
<a rel="license" href="http://creativecommons.org/licenses/by-nc-nd/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-nd/4.0/88x31.png" /></a>

2. The R algorithm /rcode/, shared under a GPLv3 license: License: https://www.gnu.org/licenses/gpl-3.0.en.html

3. The visualization website /www/, shared under the HTML5 Boilerplate license for noncommercial use only under the MIT license.

For commercial purposes or inquiries regarding licensing, please contact the Digital Innovations department at the Duke Office for Translation & Commercialization (OTC) (https://olv.duke.edu/software/) at otcquestions@duke.edu with reference to ‘OTC File No. 7788’.

Please note that this software is distributed AS IS, WITHOUT ANY WARRANTY; and without the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

4. Attribute the data, code, and dashboard as "Patterson, Lauren, Martin Doyle, Aislinn McLaughlin, and Sophia Bryson. 2021. Water Affordability Data Repository. Nicholas Institute for Environmental Policy Solutions at Duke University. https://github.com/NIEPS-Water-Program/water-affordability" or "NIEPS Water Affordability Data" for short, and the url: https://github.com/NIEPS-Water-Program/water-affordability. You can cite all versions using the doi: 10.5281/zenodo.5156654. The doi for the current version is:
<a href="https://zenodo.org/badge/latestdoi/385713868"><img src="https://zenodo.org/badge/385713868.svg" alt="DOI"></a>

5.  Attribute the concept of this approach and our findings to: Patterson, LA and MW Doyle. 2021 Measuring water affordability and the financial capability of utilities. AWWA Water Science (e1260). 25pp. doi: http://dx.doi.org/10.1002/aws2.1260.




## Workflow
The process of creating the dashboard is detaield in the pdf: "Workflow for Creating Water Affordability Dashboard". Briefly, we manually collected rates data and used Rcran to access census and water service area boundaries. We combined the rates and census data with the service area boundaries to calculate affordability metrics in Rcran. The data are visualized using html and javascript. The process is illustrated in the figure below.

![process-overview](https://user-images.githubusercontent.com/15807329/126791513-2b65c0f9-956f-4aca-9dae-c2ae87e3cd6f.png)



