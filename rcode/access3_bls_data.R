#######################################################################################################################################################
#
#
# (c) Copyright Affordability Dashboard by Lauren Patterson, 2021
# This script is run as needed to update data from the bureau of labor statistics
# Recommended update frequency: monthly to bi-monthly
#
#
########################################################################################################################################################


######################################################################################################################################################################
#
#   READ IN HISTORIC DATA
#
######################################################################################################################################################################
bls.recent <- read.csv(paste0(swd_data, "\\census_time\\current_unemploy.csv")) %>% as.data.frame()


######################################################################################################################################################################
#
#   READ IN RECENT DATA
#
######################################################################################################################################################################
temp = tempfile();
download.file("https://www.bls.gov/web/metro/laucntycur14.zip",temp, mode="wb")
zt <- read_excel(unzip(temp, "laucntycur14.xlsx"), sheet="laucntycur14", skip = 6, col_names=FALSE)
  colnames(zt) <- colnames(bls.recent)

# remove the provisional "p" on data in the year column 
zt <- zt %>% mutate(year = str_remove_all(year, " p")) %>% filter(is.na(stateFips)==FALSE)
#remove missing data
zt <- zt %>% filter(is.na(stateFips)==FALSE)

#only add new data to bls.recent
#check format of date
check.form <- bls.recent$year[dim(bls.recent)[1]]
if(is.na(as.numeric(substr(check.form,1,1))) == TRUE){
  str_format="%b-%y-%d"; #sometimes format changes
} else {
  str_format="%y-%b-%d"; #sometimes format changes
}

last.date <- as.Date(paste0(bls.recent$year[dim(bls.recent)[1]],"-01"), format=str_format); #sometimes format changes
last.date


check.form <- zt$year[dim(zt)[1]]
if(is.na(as.numeric(substr(check.form,1,1))) == TRUE){
  str_format="%b-%y-%d"; #sometimes format changes
} else {
  str_format="%y-%b-%d"; #sometimes format changes
}
zt2 <- zt %>% mutate(format = str_format, date = as.Date(paste0(year,"-01"), format=str_format)) %>% filter(date > as.Date(last.date, format=str_format))
table(zt2$year)

bls.recent <- rbind(bls.recent, zt2)

#reformat a standard date
bls.recent <- bls.recent %>% mutate(format = ifelse(is.na(as.numeric(substr(year,1,1)))==TRUE, "%b-%y-%d", "%y-%b-%d"), date=as.Date(paste0(year,"-01"), format)) 
bls.recent <- bls.recent %>% mutate(year = as.character(date, format="%y-%b"))

#save file
write.csv(bls.recent, paste0(swd_data, "\\census_time\\current_unemploy.csv"), row.names=FALSE)

unlink(temp)


rm(temp, zt, last.date, bls.recent, zt2)

