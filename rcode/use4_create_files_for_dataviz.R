#######################################################################################################################################################
#
# Created by Lauren Patterson, 2021
# Simplifies and saves files for data visualization
#
########################################################################################################################################################


###################################################################################################################################################################
#
# SAVE OUT GEOJSON FOR HTML - IN SIMPLIFIED FORMAT - only need to do for each state
#
###################################################################################################################################################################
swd_html = "C:\\Users\\lap19\\Documents\\GitHub\\bkup\\www\\data\\"

#only need to do once
county <- read_sf(paste0(swd_data, "county.geojson")) 
leaflet() %>% addProviderTiles("Stamen.TonerLite") %>% 
  addPolygons(data = bk.up,  fillOpacity= 0.6,  fillColor = "gray", color="black",  weight=3) %>% 
  addPolygons(data = county,  fillOpacity= 0.3,  fillColor = "white", color="red",  weight=1) 
geojson_write(county, file = paste0(swd_html, "mapbox_source//county.geojson"))

state <- read_sf(paste0(swd_data, "state.geojson")) #%>% ms_simplify(keep = 0.5, keep_shapes=TRUE)
geojson_write(state, file = paste0(swd_html, "mapbox_source//state.geojson"))


#MUNIS COME FROM DIFFERENT SOURCES - except OR and CA
all.muni  <- read_sf(paste0(swd_data, "mapbox_source//muni.geojson"))
bk.up <- all.muni
all.muni <- all.muni %>% ms_simplify(keep = 0.25, keep_shapes=TRUE); #already been simplified by 0.5 (0.15 is a little too much - file size is 5 MB. 0.20 is good but file size is 10 MB and slow)
leaflet() %>% addProviderTiles("Stamen.TonerLite") %>% 
  addPolygons(data = bk.up,  fillOpacity= 0.6,  fillColor = "gray", color="black",  weight=3) %>% 
  addPolygons(data = all.muni,  fillOpacity= 0.3,  fillColor = "white", color="red",  weight=1) 
geojson_write(all.muni, file = paste0(swd_html, "muni.geojson"))

#save point file for labels
all.muni.pt <- st_centroid(all.muni)
geojson_write(all.muni.pt, file = paste0(swd_html, "mapbox_source//muni_centers.geojson"))
rm(all.muni.pt, bk.up)




###################################################################################################################################################################
#
# SAVE OUT UTILITY INFORMATION --> ONLY THOSE SYSTEMS WITH DATA FOR BOTH DRINKING WATER AND WASTEWATER
#
###################################################################################################################################################################
#Load Rates Data -----------------------------------------------------------------------------------------------------------------------------------------
res.rates <- read.csv(paste0(swd_results, "estimated_bills.csv")) %>% mutate(state=tolower(substr(pwsid,0,2)))
res.rates[is.na(res.rates)] <- 0


#number of systems with some rates data
print(paste("Number of systems with some rates data:", length(unique(res.rates$pwsid)), "utilities"))

#keep only those that provide both water and wasteater services
df.2serv <- res.rates %>% filter(hh_use == 4000 & category=="inside" & service =="total") %>% select(pwsid, service_area, category, service, n_services, state) %>% distinct() %>% filter(n_services==2)
  table(df.2serv$state)
  print(paste("Number of systems with both drinking water and wastewater data:", length(unique(df.2serv$pwsid)), "utilities"))  

###################################################################################################################################################################
#
# SAVE OUT SHAPEFILES ... ONLY NEED TO DO IF ADD MORE RATES
#
###################################################################################################################################################################
service.scores <- read.csv(paste0(swd_results, "utility_service_scores_",selected.year,".csv"))
  print(paste("Number of systems with service area boundaries:", length(unique(service.scores$pwsid)), "utilities"))  

    #for some reason the GEOID character is inconsistent so check with mutate
block.scores <- read.csv(paste0(swd_results, "utility_block_scores_",selected.year,".csv"), colClasses=c("GEOID" = "character")) %>% mutate(GEOID = ifelse(nchar(GEOID) ==11, paste0("0",GEOID), GEOID))

#find unique values
bs <- block.scores %>% select(GEOID, pwsid) %>% distinct()
combo <- merge(df.2serv, bs, by.x="pwsid", by.y="pwsid")
unique.pwsid <- unique(combo$pwsid)
print(paste("Number of systems sufficient data:", length(unique.pwsid), "utilities"))  

block.scores <- block.scores %>% filter(pwsid %in% unique.pwsid); #filter to those with rates data
unique.bgs <- unique(block.scores$GEOID)
table(substr(block.scores$GEOID,0,2))


######################################################################################################################################################################
#
#   LOAD RATES, CWS Data, UTILITY SUMMARY DATA -- THIS FORMS THE BASIS FOR REMAINING FILES
#
######################################################################################################################################################################
all.rates <- read.csv(paste0(swd_results, "utility_rates_table.csv"))
cws <- read.csv(paste0(swd_data, "sdwis//cws_systems.csv")) %>% filter(PWSID %in% unique.pwsid)
cws <- cws %>% rename(pwsid=PWSID, name = PWS_NAME, population = POPULATION_SERVED_COUNT, owner_type = OWNER_TYPE_CODE) %>% select(pwsid, name, population, owner_type)


#Create summary
hb_high = 9.2; hb_mod = 4.6;
service.scores <- service.scores %>% filter(pwsid %in% unique.pwsid) %>% mutate(LaborHrs = round((LaborHrsMax + LaborHrsMin)/2,2)) %>% mutate(state=tolower(substr(pwsid,0,2)))
service.scores <- service.scores %>% mutate(burden = ifelse(PPI >= 35 & HBI >= hb_high, "Very High", ifelse(PPI >=35 & HBI < hb_high & HBI >= hb_mod, "High", ifelse(PPI >= 35 & HBI < hb_mod, "Moderate-High", 
                                           ifelse(PPI >= 20 & PPI < 35 & HBI >=hb_high, "High", ifelse(PPI >=20 & PPI < 35 & HBI >= hb_mod & HBI < hb_high, "Moderate-High", ifelse(PPI >=20 & PPI < 35 & HBI < hb_mod, "Low-Moderate", 
                                           ifelse(PPI < 20 & HBI >= hb_high, "Moderate-High", ifelse(PPI < 20 & HBI >= hb_mod & HBI < hb_high, "Low-Moderate", ifelse(PPI < 20 & HBI < hb_mod, "Low", "Unknown")))))))))) %>% 
  mutate(burden = ifelse(is.na(burden)==TRUE, "unknown", burden))

full.summary <- merge(service.scores, cws, by.x="pwsid", by.y="pwsid", all=TRUE)  #keep all of them or no?
#if NA then set to following
full.summary <- full.summary %>% mutate(burden = ifelse(is.na(burden), "Unknown", burden))
table(full.summary$burden, useNA="ifany");

#names
simpleCap <- function(x) {
  s <- strsplit(x, " ")[[1]]
  paste(toupper(substring(s, 1,1)), tolower(substring(s, 2)),
        sep="", collapse=" ")
}
full.summary$name2 = simpleCap(as.character(full.summary$name))
full.summary <- full.summary %>% mutate(service_area = ifelse(is.na(service_area), name2, service_area)) %>% select(-name, -name2)

#if a system does not have any sdwis violations - add cws population and size category
full.summary <- full.summary %>% 
  mutate(sizeCategory = ifelse(population <= 500, "Very Small", ifelse(population > 500 & population <=3300, "Small", ifelse(population > 3300 & population <= 10000, "Medium", 
         ifelse(population > 10000 & population <= 100000, "Large", ifelse(population > 100000, "Very Large", "Unknown"))))))
table(full.summary$sizeCategory, useNA='ifany')
table(full.summary$owner_type, useNA="ifany")

#full.summary[is.na(full.summary)] <- 0;
full.summary <- full.summary %>%  
  mutate(owner_type = ifelse(owner_type == "F", "Federal", ifelse(owner_type == "L", "Local", ifelse(owner_type == "M", "Public/Private", ifelse(owner_type == "S", "State", ifelse(owner_type == "P", "Private",
                      ifelse(owner_type=="N", "Native American", "Unknown")))))))

#redo sizeCategory to provide more nuance
table(full.summary$sizeCategory, useNA="ifany")/17
subset(full.summary, is.na(sizeCategory))

vl_break = 500000; ml_break = 75000;
full.summary <- full.summary %>% mutate(sizeCategory = ifelse(population >= vl_break, "Very Large", ifelse(population > 10000 & population <= ml_break, "Medium-Large", 
                                       ifelse(population > ml_break & population < vl_break, "Large", sizeCategory))))

#fill in missing info not in EPA SDWIS
full.summary <- full.summary %>% mutate(sizeCategory = ifelse(pwsid=="NC5063021", "Very Small", sizeCategory), owner_type = ifelse(pwsid=="NC5063021", "L", owner_type)); #https://www.ncwater.org/WUDC/app/LWSP/report.php?pwsid=50-63-021&year=2019
full.summary <- full.summary %>% mutate(sizeCategory = ifelse(pwsid=="PA1230012", "Medium", sizeCategory), owner_type = ifelse(pwsid=="PA1230012", "P", owner_type)); #https://www.ewg.org/tapwater/system.php?pws=PA1230012
full.summary <- full.summary %>% mutate(sizeCategory = ifelse(pwsid=="PA2450045", "Very Small", sizeCategory), owner_type = ifelse(pwsid=="PA2450045", "P", owner_type)); #https://www.nytimes.com/interactive/projects/toxic-waters/contaminants/pa/monroe/pa2450045-mountain-top-estates/index.html
full.summary <- full.summary %>% mutate(sizeCategory = ifelse(pwsid=="PA2520051", "Very Small", sizeCategory), owner_type = ifelse(pwsid=="PA2520051", "P", owner_type)); #https://www.annualreports.com/HostedData/AnnualReportArchive/m/NASDAQ_MSEX_2018.pdf

#since so few - F, M, N, and S to "Other"
full.summary <- full.summary %>% mutate(owner_type = ifelse(owner_type=="Local" | owner_type == "Private", owner_type, "Other"))

#remove to those you are using
full.summary <- full.summary %>% dplyr::select(-LaborHrsMin, -LaborHrsMax)

#combine with block group to get distributions
bs.hist <- block.scores %>% group_by(pwsid, hh_use, burden) %>% summarize(count=n(), .groups="drop") %>% spread(key=burden, value=count)
bs.hist[is.na(bs.hist)] = 0
bs.hist <- bs.hist %>% mutate(total = High + Low + `Low-Moderate` + `Moderate-High` + `Very High` + unknown) %>% 
  mutate(low = round(Low/total*100, 1), low_mod = round(`Low-Moderate`/total*100, 1), mod_high = round(`Moderate-High`/total*100, 1), high = round(High/total*100, 1), very_high = round(`Very High`/total*100, 1)) %>% 
  dplyr::select(pwsid, hh_use, low, low_mod, mod_high, high, very_high) 
bs.hist <- bs.hist %>% mutate(total_per = low+low_mod+mod_high+high+very_high)
subset(bs.hist, total_per==0)

bs.hist <- bs.hist %>% select(-total_per) %>%  distinct()

full.summary = merge(full.summary, bs.hist, by=c("pwsid", "hh_use"))


#Save out characteristics used for filtering that do not change with volume
main.data <- full.summary %>% select(pwsid, service_area, state, sizeCategory, owner_type) %>% distinct()
write.csv(main.data, paste0(swd_html,"utility_descriptions.csv"), row.names=FALSE)

full.summary.short <- full.summary %>% select(pwsid, hh_use, HBI, PPI, TRAD, burden, LaborHrs, low, low_mod, mod_high, high, very_high)
write.csv(full.summary.short, paste0(swd_html,"utility_afford_scores.csv"), row.names=FALSE)



#commodity price
commod.price <- res.rates %>% select(pwsid, category, total, hh_use, service, commodity_unit_price) %>% filter(service != "storm") %>% 
  filter(service != "total") %>% arrange(pwsid, category, service, hh_use) %>% mutate(commodity_unit_price = round(commodity_unit_price, 2))
commod.price <- commod.price %>% filter(category == "inside" | category == "outside" & total > 0) %>% select(-total)
write.csv(commod.price, paste0(swd_html, "commodity_price.csv"), row.names=FALSE)


#res rates
hh_vols <- c(0, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000, 11000, 12000, 13000, 14000, 15000, 16000)
for (i in 1:length(hh_vols)){
  zt <- res.rates %>% filter(hh_use == hh_vols[i])  %>%  filter(category=="inside" | category=="outside" & total>0) %>% filter(n_services > 1) %>% 
    select(-n_services, -service_area, -state, -commodity_unit_price, -hh_use)
  write.csv(zt, paste0(swd_html, "rates\\rates_",hh_vols[i],".csv"), row.names=FALSE); #can split by hh_volume
  print(hh_vols[i])
}
#make smaller for now
all.rates2 <- all.rates %>% select(-percent_variable_water, -percent_variable_sewer, -percent_surcharge_water, -percent_surcharge_sewer, -surcharge_cost_storm, -variable_cost_storm, -base_cost_storm, -service_area)
write.csv(all.rates2, paste0(swd_html, "\\all_rates_table_current.csv"), row.names = FALSE)



#######################################################################################################################################################################################3
#
#                                              CREATE MAPBOX FILES FOR UTILITIES
#
#######################################################################################################################################################################################3
#read in water systems - FOR NOW WILL ONLY KEEP THOSE THAT HAVE RATES DATA...#simplify shapefiles differently because NC is so problematic and then combine
ca.systems <- read_sf(paste0(swd_data, "ca_systems.geojson")) %>% ms_simplify(keep = 0.5, keep_shapes = TRUE) %>% mutate(state = "ca") %>% select(pwsid, gis_name, state, geometry)
nc.systems <- read_sf(paste0(swd_data, "nc_systems.geojson")) %>% ms_simplify(keep = 0.25, keep_shapes = TRUE) %>% 
               mutate(pwsid = ifelse(gis_name=="Town_of_Forest_City", "NC0181010", pwsid)); ##"NC0363108"; duplicated... forest city is wrong in the pwsid... NC0181010
or.systems <- read_sf(paste0(swd_data, "or_systems.geojson")) %>% ms_simplify(keep = 0.5, keep_shapes = TRUE) %>% select(pwsid, gis_name, state, geometry)
pa.systems <- read_sf(paste0(swd_data, "pa_systems.geojson")) %>% ms_simplify(keep = 0.5, keep_shapes = TRUE) %>% mutate(state = "pa") %>% select(pwsid, gis_name, state, geometry)
tx.systems <- read_sf(paste0(swd_data, "tx_systems.geojson")) %>% ms_simplify(keep = 0.5, keep_shapes = TRUE)


#save to only those systems with pwsid in unique.pwsid
all.systems <- rbind(ca.systems, nc.systems, or.systems, pa.systems, tx.systems) %>% filter(pwsid %in% unique.pwsid)
#mapview::mapview(all.systems)
rm(ca.systems, nc.systems, or.systems, pa.systems, tx.systems)

simple.systems <- all.systems %>% ms_simplify(keep = 0.02, keep_shapes=TRUE)
mapview::mapview(simple.systems)
geojson_write(simple.systems, file = paste0(swd_html, "simple_water_systems.geojson")); #aim for 1 MB


#loop through and save individual volumes
hh_vols <- c(0, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000, 11000, 12000, 13000, 14000, 15000, 16000)
bare.systems <- all.systems %>% dplyr::select(pwsid, geometry)
for (i in 1:length(hh_vols)){
  zt = NA; zt.systems = NA;
  zt <- full.summary.short %>% filter(hh_use == hh_vols[i]) %>% dplyr::select(-hh_use) %>% mutate(HBI = round(HBI, 1), PPI = round(PPI, 1), TRAD = round(TRAD, 1), LaborHrs = round(LaborHrs, 1))

  zt.systems <- merge(bare.systems, zt, by.x="pwsid", by.y="pwsid", all.x=TRUE)
  geojson_write(zt.systems, file = paste0(swd_html, "mapbox_source\\water_systems_",hh_vols[i],".geojson")); #aim for 5 MB
  
  print(hh_vols[i])
}



#######################################################################################################################################################################################3
#
#                                              BLOCK SCORES AND BLOCK GROUPS FOR WEBSITE
#
#######################################################################################################################################################################################3
#read in block groups
bk.groups <- read_sf(paste0(swd_data, "block_groups_", selected.year, ".geojson")) %>% filter(GEOID %in% unique.bgs)
bk.groups <- bk.groups %>% ms_simplify(keep = 0.45, keep_shapes=TRUE); #Trying to balance simplicity and file size
#mapview::mapview(bk.groups %>% filter(substring(GEOID,0,2)=="42"))
table(substr(bk.groups$GEOID,0,2))
#geojson_write(bk.groups, file = paste0(swd_html, "all_bk_groups.geojson")); #aim for 10MB

#will need to break up block scores by hh_use
block.scores <- block.scores %>% select(-service_area) %>% mutate(state = tolower(substr(pwsid,0,2)))
#rewrite burden score using days of labor
hb_high = 9.2; hb_mod = 4.6;
block.scores <- block.scores %>% mutate(burden = ifelse(PPI >= 35 & HBI >= hb_high, "Very High", ifelse(PPI >=35 & HBI < hb_high & HBI >= hb_mod, "High", ifelse(PPI >= 35 & HBI < hb_mod, "Moderate-High", 
                                  ifelse(PPI >= 20 & PPI < 35 & HBI >=hb_high, "High", ifelse(PPI >=20 & PPI < 35 & HBI >= hb_mod & HBI < hb_high, "Moderate-High", ifelse(PPI >=20 & PPI < 35 & HBI < hb_mod, "Low-Moderate", 
                                  ifelse(PPI < 20 & HBI >= hb_high, "Moderate-High", ifelse(PPI < 20 & HBI >= hb_mod & HBI < hb_high, "Low-Moderate", ifelse(PPI < 20 & HBI < hb_mod, "Low", "Unknown")))))))))) %>% 
  mutate(burden = ifelse(is.na(burden)==TRUE, "unknown", burden))


hh_vols <- c(0, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000, 11000, 12000, 13000, 14000, 15000, 16000)
for (i in 1:length(hh_vols)){
  zt <- block.scores %>% filter(hh_use == hh_vols[i]) %>% dplyr::select(-hh_use, -hhsize, -totalpop, -state) %>% mutate(HBI = round(HBI, 1), PPI = round(PPI, 1), TRAD = round(TRAD, 1))
  
  zt.systems <- merge(bk.groups, zt, by.x="GEOID", by.y="GEOID", all.x=TRUE) %>% select(-state)
  
  geojson_write(zt.systems, file = paste0(swd_html, "mapbox_source\\block_groups_",hh_vols[i],".geojson")); #aim for 5 MB

  write.csv(zt, paste0(swd_html, "block_scores\\block_scores_",hh_vols[i],".csv"), row.names=FALSE); #can split by hh_volume
  print(hh_vols[i])
}




#########################################################################################################################################################################################################
##                                                    READ IN RESULTS FOR All States
##########################################################################################################################################################################################################
#read in files and save over
cs <- read.csv(paste0(swd_results, "\\utility_census_summary.csv")) %>% mutate(state = tolower(substring(pwsid, 0, 2))) %>% filter(pwsid %in% full.summary$pwsid) %>% select(-service_area, -state)
write.csv(cs, paste0(swd_html, "\\census_summary.csv"), row.names = FALSE)

blm <- read.csv(paste0(swd_results, "\\utility_bls_monthly.csv")) %>% select(pwsid, date, unemploy_rate) 
write.csv(blm, paste0(swd_html, "\\bls_monthly.csv"), row.names = FALSE)

bls <- read.csv(paste0(swd_results, "\\utility_bls_summary.csv"))
#to lower file size save out every other year
current_year <- year(today())
last_even_year <- ifelse(substr(current_year,4,4) %in% c(1,3,5,7,9), current_year-1, current_year)
bls <- bls %>% filter(year %in% c(seq(1990,last_even_year,2), current_year)) %>% select(pwsid, year, unemploy_rate)
write.csv(bls, paste0(swd_html, "\\bls_summary.csv"), row.names = FALSE)



#IDWS-----------------------------------------------------------------------------
all.cost.to.bill <- read.csv(paste0(swd_results, "utility_idws.csv"))
table(substr(all.cost.to.bill$pwsid,0,2))
all.cost.to.bill <- all.cost.to.bill %>% select(pwsid, service_area, category, hh_use, percent_income, annual_cost, percent_pays_more) %>% mutate(state = tolower(substr(pwsid, 0, 2))) %>% 
   filter(category=="inside" | category=="outside" & percent_pays_more > 0) %>% filter(pwsid %in% unique(full.summary$pwsid)) 

#remove very small utilities because not enough data
keep.list <- cs %>% filter(keep == "keep")
all.cost.to.bill <- all.cost.to.bill %>% filter(pwsid %in% keep.list$pwsid)

for (i in 1:length(hh_vols)){
  zt <- all.cost.to.bill %>% filter(hh_use == hh_vols[i]) %>% select(pwsid, category, percent_income, annual_cost, percent_pays_more) %>% 
    mutate(percent_pays_more = round(percent_pays_more,1), annual_cost = round(annual_cost, 0))
  write.csv(zt, paste0(swd_html, "IDWS\\idws_",hh_vols[i],".csv"), row.names=FALSE); #can split by hh_volume
  print(hh_vols[i])
}


#########################################################################################################################################################################################################
#
#                                                    SAVE OUT WATER RATES DATA
#
#########################################################################################################################################################################################################
head(res.rates)

#read in all original rates too
#Load Rates Data -----------------------------------------------------------------------------------------------------------------------------------------
ca.meta <- read_excel(paste0(swd_data, "rates_data\\rates_ca.xlsx"), sheet="ratesMetadata") %>% mutate(state = "ca") %>% select(-notes)
or.meta <- read_excel(paste0(swd_data, "rates_data\\rates_or.xlsx"), sheet="ratesMetadata") %>% mutate(state = "or") %>% select(-Notes) %>% select(-GEOID)
pa.meta <- read_excel(paste0(swd_data, "rates_data\\rates_pa.xlsx"), sheet="ratesMetadata") %>% mutate(state = "pa") %>% select(-notes)
nc.meta <- read_excel(paste0(swd_data, "rates_data\\rates_nc.xlsx"), sheet="ratesMetadata") %>% mutate(state = "nc") %>% select(-notes) %>% mutate(pwsid = paste0("NC",str_remove_all(pwsid, "[-]")))
tx.meta <- read_excel(paste0(swd_data, "rates_data\\rates_tx.xlsx"), sheet="ratesMetadata") %>% mutate(state = "tx") %>% select(-notes)

#condense to similar names
all.meta <- rbind(ca.meta, or.meta, pa.meta, nc.meta, tx.meta)
all.meta <- all.meta %>% mutate(date = as.Date(paste0(year,"-",month,"-",day), "%Y-%m-%d")) %>% filter(pwsid %in% full.summary$pwsid) %>% 
  select(pwsid, service_area, city_name, utility_name, date, year, month, day, service_type, website, last_updated) %>% rename(service = service_type)
table(all.meta$service, useNA="ifany")

#save most recent data
all.meta <- all.meta %>% group_by(pwsid, service_area, city_name, utility_name, service) %>% filter(date == max(date)) %>% ungroup()

#remove cities and just keep distinct service area and utility
all.meta <- all.meta %>% filter(service != "stormwater" | service == "stormwater" & substr(website,0,4) == "http") %>% distinct() %>% 
  mutate(service = ifelse(service=="sewer", "wastewater", service)) %>% mutate(service = ifelse(service=="sewer_septic", "septic/on-site", service)) %>% 
  mutate(service = ifelse(service=="water", "drinking water", service)) 

all.meta <- all.meta %>% mutate(order = ifelse(service=="drinking water", 1, ifelse(service=="wastewater", 2, ifelse(service=="septic/on-site", 3, ifelse(service=="stormwater", 4, 5))))) %>% 
  arrange(pwsid, order, utility_name, city_name)
table(all.meta$order, useNA="ifany")

all.meta <- all.meta %>% select(-month, -day)

#save file
write.csv(all.meta, paste0(swd_html, "rates_metadata.csv"), row.names = FALSE)
