#######################################################################################################################################################
#
# DOWNLOADS AND CREATES GEOJSON FILES FOR MAP LAYERS IN THE NORTH CAROLINA WATER SUPPLY DASHBOARD
# CREATED BY LAUREN PATTERSON
# FEBRUARY 2021
#
########################################################################################################################################################

######################################################################################################################################################################
#
#   LOAD LIBRARIES
#
######################################################################################################################################################################
## First specify the packages of interest
packages = c("rstudioapi", "readxl", "curl",
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

#New SF package creates problems
sf::sf_use_s2(FALSE)


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
state.list <- c("ca", "pa", "nc", "tx", "or", "nj", "nm", "ct", "ks", "wa");  
state.fips <- c("06", "42", "37", "48", "41", "34", "35", "09", "20", "53");
state.df <- cbind(state.list, state.fips) %>% as.data.frame(); state.df
selected.year <- 2019;
folder.year <- 2021;

# Set working directory to source file location if code is in similar directory to data files
#source_path = rstudioapi::getActiveDocumentContext()$path 
#setwd(dirname(source_path))

swd_data <- paste0("data_",folder.year,"\\")
swd_results <- paste0("results_",folder.year,"\\")
swd_html <- paste0("www\\data\\")



#census api key -
census_api_key("YOUR CENSUS KEY HERE", install=TRUE, overwrite=TRUE); 
readRenviron("~/.Renviron")

#useful function
`%notin%` = function(x,y) !(x %in% y); #function to get what is not in the list


