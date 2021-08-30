#######################################################################################################################################################
#
# SETS GLOBAL VARIABLES AND FUNCTIONS USED IN ALL FOLLOWING SCRIPTS. MUST BE RUN FIRST
# CREATED BY LAUREN PATTERSON
# 2021
#
########################################################################################################################################################

######################################################################################################################################################################
#
#   LOAD LIBRARIES
#
######################################################################################################################################################################
## First specify the packages of interest
packages = c("rstudioapi", "readxl", 
             "sf", "rgdal", "spData", "raster", "leaflet", "rmapshaper","geojsonio",
             "tidycensus", "jsonlite", "rvest", "purrr", "httr",
             "tidyverse", "lubridate", "plotly", "stringr")

## Now load or install&load all
package.check <- lapply(
  packages,
  FUN = function(x) {
    if (!require(x, character.only = TRUE)) {
      install.packages(x, dependencies = TRUE)
      library(x, character.only = TRUE)
    }
  }
)


options(scipen=999) #changes scientific notation to numeric
rm(list=ls()) #removes anything stored in memory
rm(list = setdiff(ls(), lsf.str())) #removes anything bunt functions
######################################################################################################################################################################


######################################################################################################################################################################
#
#   SET GLOBAL VARIABLES
#
######################################################################################################################################################################
#state lists --> ad a state and its fips code as needed
state.list <- c("ca", "pa", "nc", "tx", "or", "nj", "nm");  state.fips <- c("06","42", "37", "48", "41", "34","35")
state.df <- cbind(state.list, state.fips) %>% as.data.frame(); state.df
selected.year <- 2019; #reflects census year with current acs data
folder.year <- 2021; #reflects current year

# Set working directory to source file location if code is in similar directory to data files
source_path = rstudioapi::getActiveDocumentContext()$path 
setwd(dirname(source_path))

swd_data <- paste0("..\\data\\");   #swd_data <- paste0("..\\data_",folder.year,"\\")... instead will use version control of github & zenodo
swd_results <- paste0("..\\results\\");  #swd_results <- paste0("..\\results_",folder.year,"\\")
swd_html <- paste0("..\\www\\");  #if use - set to whatever your html or data viz folder will be



#census api key - https://api.census.gov/data/key_signup.html
census_api_key("YOUR API KEY GOES HERE BETWEEN THE QUOTES", install=TRUE, overwrite=TRUE); 
readRenviron("~/.Renviron")

#useful function
`%notin%` = function(x,y) !(x %in% y); #function to get what is not in the list


