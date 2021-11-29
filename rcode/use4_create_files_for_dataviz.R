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
#swd_html = "C:\\Users\\lap19\\Documents\\GitHub\\water-affordability-develop\\water-affordability-dashboard\\data\\"
#swd_html = "C:\\Users\\lap19\\Documents\\GitHub\\bkup\\water-affordability-develop\\afford_ws\\data\\"

#only need to do once
county <- read_sf(paste0(swd_data, "county.geojson")) 
leaflet() %>% addProviderTiles("Stamen.TonerLite") %>% 
  addPolygons(data = county,  fillOpacity= 0.3,  fillColor = "white", color="red",  weight=1) 
geojson_write(county, file = paste0(swd_html, "..//mapbox_sources//county.geojson"))

state <- read_sf(paste0(swd_data, "state.geojson")) %>% ms_simplify(keep=0.75, keep_shapes=TRUE) #%>% ms_simplify(keep = 0.5, keep_shapes=TRUE)
state <- state %>% mutate(data = ifelse(geoid %in% state.fips, "yes", "no")) %>% filter(name != "Alaska") %>% 
  filter(name != "Hawaii") %>% filter(name != "Puerto Rico")
state <- state %>% mutate(data = ifelse(name=="Oregon", "muni", data))
#state <- state %>% mutate(data = ifelse(name=="Washington", "hybrid", data))

table(state$name, state$data)
geojson_write(state, file = paste0(swd_html, "..//mapbox_sources//state.geojson"))


#MUNIS COME FROM DIFFERENT SOURCES - except OR and CA
all.muni  <- read_sf(paste0(swd_data, "muni.geojson"))
bk.up <- all.muni
all.muni <- all.muni %>% ms_simplify(keep = 0.40, keep_shapes=TRUE); 

#remove special characters - do not translate into mapbox
all.muni <- all.muni %>% mutate(city_name = iconv(city_name, to='ASCII//TRANSLIT')) 

leaflet() %>% addProviderTiles("Stamen.TonerLite") %>% 
  addPolygons(data = bk.up,  fillOpacity= 0.6,  fillColor = "gray", color="black",  weight=3) %>% 
  addPolygons(data = all.muni,  fillOpacity= 0.3,  fillColor = "white", color="red",  weight=1) 
geojson_write(all.muni, file = paste0(swd_html, "..//mapbox_sources//muni.geojson"))

#save point file for labels
all.muni.pt <- st_centroid(all.muni)
geojson_write(all.muni.pt, file = paste0(swd_html, "..//mapbox_sources//muni_centers.geojson"))
rm(all.muni.pt, bk.up, all.muni, state, county)




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
zt <- block.scores %>% filter(hh_use==4000)
zt <- zt %>% mutate(duplicate = duplicated(zt[,1:2]))
check <- zt %>% filter(duplicate==TRUE); dim(check)


#find unique values
bs <- block.scores %>% select(GEOID, pwsid) %>% distinct()
combo <- merge(df.2serv, bs, by.x="pwsid", by.y="pwsid")
#remove pwsid in WA that shares same boundaries
combo <- combo %>% filter(pwsid != "WA5308273")

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
#lots of duplicates in NJ
cws <- cws %>% group_by(pwsid, name, owner_type) %>% summarize(population = median(population, na.rm=TRUE), .groups="drop")
#keep the first in the list if different names... will use names in rates
cws <- cws %>% distinct(pwsid, .keep_all = TRUE)


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
#subset(full.summary, is.na(sizeCategory) & hh_use==4000)

vl_break = 500000; ml_break = 75000;
full.summary <- full.summary %>% mutate(sizeCategory = ifelse(population >= vl_break, "Very Large", ifelse(population > 10000 & population <= ml_break, "Medium-Large", 
                                       ifelse(population > ml_break & population < vl_break, "Large", sizeCategory))))

#pull in old data to fill out (some reason sdwis is missing them)
old.details <- read.csv(paste0(swd_html, "utility_descriptions.csv")) %>% select(pwsid, sizeCategory, owner_type)
merge.sum <- left_join(full.summary, old.details, by = 'pwsid') 
merge.sum <- merge.sum %>% mutate(owner_type.x = ifelse(is.na(owner_type.x), owner_type.y, owner_type.x), 
                                  sizeCategory.x = ifelse(is.na(sizeCategory.x), sizeCategory.y, sizeCategory.x))
merge.sum %>% filter(hh_use == 4000 & is.na(owner_type.x))
full.summary <- merge.sum %>% select(-sizeCategory.y, -owner_type.y) %>% rename(owner_type = owner_type.x, sizeCategory = sizeCategory.x)
rm(old.details, merge.sum)


#fill in missing info not in EPA SDWIS
full.summary <- full.summary %>% mutate(sizeCategory = ifelse(pwsid=="NC5063021", "Very Small", sizeCategory), owner_type = ifelse(pwsid=="NC5063021", "Local", owner_type)); #https://www.ncwater.org/WUDC/app/LWSP/report.php?pwsid=50-63-021&year=2019
full.summary <- full.summary %>% mutate(sizeCategory = ifelse(pwsid=="PA1230012", "Medium", sizeCategory), owner_type = ifelse(pwsid=="PA1230012", "Private", owner_type)); #https://www.ewg.org/tapwater/system.php?pws=PA1230012
full.summary <- full.summary %>% mutate(sizeCategory = ifelse(pwsid=="PA2450045", "Very Small", sizeCategory), owner_type = ifelse(pwsid=="PA2450045", "Private", owner_type)); #https://www.nytimes.com/interactive/projects/toxic-waters/contaminants/pa/monroe/pa2450045-mountain-top-estates/index.html
full.summary <- full.summary %>% mutate(sizeCategory = ifelse(pwsid=="PA2520051", "Very Small", sizeCategory), owner_type = ifelse(pwsid=="PA2520051", "Private", owner_type)); #https://www.annualreports.com/HostedData/AnnualReportArchive/m/NASDAQ_MSEX_2018.pdf

full.summary <- full.summary %>% mutate(sizeCategory = ifelse(pwsid=="NM3503129", "Small", sizeCategory), owner_type = ifelse(pwsid=="NM3503129", "Local", owner_type));
full.summary <- full.summary %>% mutate(sizeCategory = ifelse(pwsid=="NM3524626", "Large", sizeCategory), owner_type = ifelse(pwsid=="NM3524626", "Private", owner_type));

full.summary <- full.summary %>% mutate(sizeCategory = ifelse(pwsid=="CT0180141", "Small", sizeCategory), owner_type = ifelse(pwsid=="CT0180141", "Private", owner_type)); #https://www.ewg.org/tapwater/system.php?pws=CT0180141
full.summary <- full.summary %>% mutate(sizeCategory = ifelse(pwsid=="CT1180081", "Medium", sizeCategory), owner_type = ifelse(pwsid=="CT1180081", "Private", owner_type)); #https://www.ewg.org/tapwater/system.php?pws=CT1180081
full.summary <- full.summary %>% mutate(sizeCategory = ifelse(pwsid=="WA5308273", "Very Small", sizeCategory), owner_type = ifelse(pwsid=="WA5308273", "Local", owner_type)); #

subset(full.summary %>% filter(hh_use==4000 & is.na(sizeCategory)))
#all these systems are listed as inactive... but so are others that are still in SDWIS as active?
full.summary <- full.summary %>% mutate(sizeCategory = ifelse(pwsid=="KS2000104", "Very Small", sizeCategory), owner_type = ifelse(pwsid=="KS2000104", "Non-Public", owner_type)); #https://dww.kdhe.ks.gov/DWW/JSP/WaterSystemDetail.jsp
full.summary <- full.summary %>% mutate(sizeCategory = ifelse(pwsid=="KS2000108", "Very Small", sizeCategory), owner_type = ifelse(pwsid=="KS2000108", "Non-Public", owner_type)); #https://dww.kdhe.ks.gov/DWW/JSP/WaterSystemDetail.jsp
full.summary <- full.summary %>% mutate(sizeCategory = ifelse(pwsid=="KS2000902", "Very Small", sizeCategory), owner_type = ifelse(pwsid=="KS2000902", "Non-Public", owner_type)); #https://dww.kdhe.ks.gov/DWW/JSP/WaterSystemDetail.jsp
full.summary <- full.summary %>% mutate(sizeCategory = ifelse(pwsid=="KS2008705", "Very Small", sizeCategory), owner_type = ifelse(pwsid=="KS2008705", "Non-Public", owner_type)); #https://dww.kdhe.ks.gov/DWW/JSP/WaterSystemDetail.jsp
full.summary <- full.summary %>% mutate(sizeCategory = ifelse(pwsid=="KS2009907", "Very Small", sizeCategory), owner_type = ifelse(pwsid=="KS2009907", "Non-Public", owner_type)); #https://dww.kdhe.ks.gov/DWW/JSP/WaterSystemDetail.jsp
full.summary <- full.summary %>% mutate(sizeCategory = ifelse(pwsid=="KS2020503", "Very Small", sizeCategory), owner_type = ifelse(pwsid=="KS2020503", "Non-Public", owner_type)); #https://dww.kdhe.ks.gov/DWW/JSP/WaterSystemDetail.jsp
#remove inactive systems
full.summary <- full.summary %>% filter(pwsid %notin% c("KS2000104","KS2000108","KS2000902","KS2008705","KS2009907","KS2020503"))

table(full.summary$sizeCategory, useNA='ifany')
table(full.summary$owner_type, useNA="ifany")


#since so few - F, M, N, and S to "Other"
full.summary <- full.summary %>% mutate(owner_type = ifelse(owner_type=="Local" | owner_type == "Private", owner_type, "Other"))

#since owner errors in PA and similar start to names - check and make private
zt <- subset(full.summary, substr(service_area, 1, 7) == "Aqua PA"); table(zt$owner_type); #looks ok
zt <- subset(full.summary, substr(service_area, 1, 21) == "Pennsylvania American"); table(zt$owner_type); #Two are set as local, one to other... set local to Private
full.summary <- full.summary %>% mutate(owner_type = ifelse(substr(service_area,1,21) == "Pennsylvania American" & owner_type=="Local", "Private", owner_type)); #set Local to Private

zt <- subset(full.summary, substr(service_area, 1, 4) == "Suez"); table(zt$owner_type); #several listed as local... set those to private
full.summary <- full.summary %>% mutate(owner_type = ifelse(substr(service_area,1,4) == "Suez" & owner_type=="Local", "Private", owner_type)); #set Local to Private

zt <- subset(full.summary, substr(service_area, 1, 19) == "California American"); table(zt$owner_type); #All private
zt <- subset(full.summary, substr(service_area, 1, 24) == "California Water Service"); table(zt$owner_type); #1 local - set to private
full.summary <- full.summary %>% mutate(owner_type = ifelse(substr(service_area,1,24) == "California Water Service" & owner_type=="Local", "Private", owner_type)); #set Local to Private

zt <- subset(full.summary, substr(service_area, 1, 17) == "Aquarion Water Co"); table(zt$owner_type); #All private


#remove to those you are using
full.summary <- full.summary %>% dplyr::select(-LaborHrsMin, -LaborHrsMax)

#combine with block group to get distributions
bs.hist <- block.scores %>% group_by(pwsid, hh_use, burden) %>% summarize(count=n(), .groups="drop") %>% spread(key=burden, value=count)
bs.hist[is.na(bs.hist)] = 0
bs.hist <- bs.hist %>% mutate(total = High + Low + `Low-Moderate` + `Moderate-High` + `Very High` + unknown) %>% 
  mutate(low = round(Low/total*100, 1), low_mod = round(`Low-Moderate`/total*100, 1), 
         mod_high = round(`Moderate-High`/total*100, 1), high = round(High/total*100, 1), 
         very_high = round(`Very High`/total*100, 1), unknown = round(unknown/total,1)) %>% 
  dplyr::select(pwsid, hh_use, low, low_mod, mod_high, high, very_high, unknown) 
bs.hist <- bs.hist %>% mutate(total_per = low+low_mod+mod_high+high+very_high+unknown)
unique(subset(bs.hist, total_per==0)$pwsid)

bs.hist <- bs.hist %>% select(-total_per, -unknown) %>%  distinct()

full.summary = merge(full.summary, bs.hist, by=c("pwsid", "hh_use"))


#Save out characteristics used for filtering that do not change with volume
main.data <- full.summary %>% select(pwsid, service_area, state, sizeCategory, owner_type, min_wage, min_year) %>% distinct()
write.csv(main.data, paste0(swd_html,"utility_descriptions.csv"), row.names=FALSE)

full.summary.short <- full.summary %>% select(pwsid, hh_use, HBI, PPI, TRAD, burden, LaborHrs)
write.csv(full.summary.short, paste0(swd_html,"utility_afford_scores.csv"), row.names=FALSE)


#commodity price
commod.price <- res.rates %>% select(pwsid, category, total, hh_use, service, commodity_unit_price) %>% filter(service != "storm") %>% filter(pwsid %in% main.data$pwsid) %>% 
  filter(service != "total") %>% arrange(pwsid, category, service, hh_use) %>% mutate(commodity_unit_price = round(commodity_unit_price, 2))
commod.price <- commod.price %>% filter(category == "inside" | category == "outside" & total > 0) %>% select(-total)
write.csv(commod.price, paste0(swd_html, "commodity_price.csv"), row.names=FALSE)


#res rates
hh_vols <- c(0, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000, 11000, 12000, 13000, 14000, 15000, 16000)
for (i in 1:length(hh_vols)){
  zt <- res.rates %>% filter(hh_use == hh_vols[i])  %>%  filter(category=="inside" | category=="outside" & total>0) %>% filter(pwsid %in% main.data$pwsid) %>% 
    select(-n_services, -service_area, -state, -commodity_unit_price, -hh_use)
  write.csv(zt, paste0(swd_html, "rates\\rates_",hh_vols[i],".csv"), row.names=FALSE); #can split by hh_volume
  print(hh_vols[i])
}
#make smaller for now
all.rates2 <- all.rates %>% select(-percent_variable_water, -percent_variable_sewer, -percent_surcharge_water, -percent_surcharge_sewer, -surcharge_cost_storm, -variable_cost_storm, -base_cost_storm, -service_area) %>% 
  filter(pwsid %in% main.data$pwsid)
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
tx.systems <- read_sf(paste0(swd_data, "tx_systems.geojson")) %>% ms_simplify(keep = 0.5, keep_shapes = TRUE) %>% mutate(state ="tx")
nm.systems <- read_sf(paste0(swd_data, "nm_systems.geojson")) %>% ms_simplify(keep = 0.5, keep_shapes = TRUE) %>% mutate(state = "nm")
nj.systems <- read_sf(paste0(swd_data, "nj_systems.geojson")) %>% ms_simplify(keep = 0.5, keep_shapes = TRUE) 
ct.systems <- read_sf(paste0(swd_data, "ct_systems.geojson")) %>% ms_simplify(keep = 0.5, keep_shapes = TRUE) %>% mutate(state = "ct")
ks.systems <- read_sf(paste0(swd_data, "ks_systems.geojson")) %>% ms_simplify(keep = 0.5, keep_shapes = TRUE) %>% mutate(state = "ks")
wa.systems <- read_sf(paste0(swd_data, "wa_systems.geojson")) %>% ms_simplify(keep = 0.5, keep_shapes = TRUE) %>% mutate(state = "wa")


#save to only those systems with pwsid in unique.pwsid
all.systems <- rbind(ca.systems, nc.systems, or.systems, pa.systems, tx.systems, nm.systems, nj.systems, ct.systems, ks.systems, wa.systems) %>% filter(pwsid %in% main.data$pwsid)
#mapview::mapview(all.systems)
rm(ca.systems, nc.systems, or.systems, pa.systems, tx.systems, nm.systems, nj.systems, ct.systems, wa.systems, ks.systems)

simple.systems <- all.systems %>% ms_simplify(keep = 0.005, keep_shapes=TRUE)
mapview::mapview(simple.systems)
#instead calculate bounding box
as.data.frame(table(st_geometry_type(simple.systems)))
#geojson_write(simple.systems, file = paste0(swd_html, "simple_water_systems.geojson")); #aim for 1 MB



#loop through and save individual volumes
hh_vols <- c(0, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000, 11000, 12000, 13000, 14000, 15000, 16000)
bare.systems <- all.systems %>% dplyr::select(pwsid, geometry)
as.data.frame(table(st_geometry_type(bare.systems)))
bare.systems <- all.systems %>% group_by(pwsid) %>% summarise() %>% st_cast(); #this dissolves polygons
#simplify some
bare.systems <- bare.systems %>% ms_simplify(keep = 0.5, keep_shapes=TRUE)

#create dataframe
zt.box <- bare.systems %>% select(pwsid)
st_geometry(zt.box) = NULL
zt.box$xmin = zt.box$ymin = zt.box$xmax = zt.box$ymax = NA


#fix geometry
if (FALSE %in% st_is_valid(bare.systems)) {bare.systems <- suppressWarnings(st_buffer(bare.systems[!is.na(st_is_valid(bare.systems)),], 0.0)); print("fixed")}#fix corrupt shapefiles for block group... takes awhile can try to skip

#need to replace all special characters
full.summary <- full.summary %>% mutate(service_area = iconv(service_area, to='ASCII//TRANSLIT'))

for (i in 1:length(hh_vols)){
  zt = NA; zt.systems = NA;
  zt <- full.summary %>% filter(hh_use == hh_vols[i]) %>% dplyr::select(-hh_use, -population) %>% mutate(HBI = round(HBI, 1), PPI = round(PPI, 1), TRAD = round(TRAD, 1), LaborHrs = round(LaborHrs, 1))

  zt.systems <- merge(bare.systems, zt, by.x="pwsid", by.y="pwsid", all.x=TRUE)
  geojson_write(zt.systems, file = paste0(swd_html, "..\\mapbox_sources\\water_systems_",hh_vols[i],".geojson")); #aim for 5 MB
  
  print(hh_vols[i])
}



#######################################################################################################################################################################################3
#
#                                              BLOCK SCORES AND BLOCK GROUPS FOR WEBSITE
#
#######################################################################################################################################################################################3
#repeat since removed some 
block.scores <- block.scores %>% filter(pwsid %in% main.data$pwsid); #filter to those with rates data
unique.bgs <- unique(block.scores$GEOID)
table(substr(block.scores$GEOID,0,2))

#read in block groups
bk.groups <- read_sf(paste0(swd_data, "block_groups_", selected.year, ".geojson")) %>% filter(GEOID %in% unique.bgs)
bk.groups <- bk.groups %>% ms_simplify(keep = 0.6, keep_shapes=TRUE); #Trying to balance simplicity and file size
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

#In Washington - a bunch of islands all have the same census block group with no houses
del.block <- c("530099901000")
bk.groups <- bk.groups %>% filter(GEOID %notin% del.block)
block.scores <- block.scores %>% filter(GEOID %notin% del.block)

hh_vols <- c(0, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000, 11000, 12000, 13000, 14000, 15000, 16000)
for (i in 1:length(hh_vols)){
  zt <- block.scores %>% filter(hh_use == hh_vols[i]) %>% dplyr::select(-hh_use, -hhsize, -totalpop, -state) %>% mutate(HBI = round(HBI, 1), PPI = round(PPI, 1), TRAD = round(TRAD, 1))
  
  zt.systems <- merge(bk.groups, zt, by.x="GEOID", by.y="GEOID", all.x=TRUE) %>% select(-state)
  geojson_write(zt.systems, file = paste0(swd_html, "..//mapbox_sources//block_groups_",hh_vols[i],".geojson")); #aim for 5 MB

  #we don't use block scores for much so can slim down
  zt <- zt %>% select(GEOID, pwsid, burden)
  write.csv(zt, paste0(swd_html, "block_scores\\block_scores_",hh_vols[i],".csv"), row.names=FALSE); #can split by hh_volume

  print(hh_vols[i])
}


#create bounding box for geojsons
for(i in 1:length(bare.systems$pwsid)){
  yt <- block.scores %>% filter(pwsid == bare.systems$pwsid[i])
  zt <- bk.groups %>% filter(GEOID %in% yt$GEOID);
  zt.box$xmin[i] = round(st_bbox(zt)[1],2); zt.box$ymin[i] = round(st_bbox(zt)[2],2); zt.box$xmax[i] = round(st_bbox(zt)[3],2);  zt.box$ymax[i] = round(st_bbox(zt)[4],2); 
  print(i);
}
summary(zt.box)
write_csv(zt.box, file=paste0(swd_html, "bbox.csv"))



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
or.meta <- read_excel(paste0(swd_data, "rates_data\\rates_or.xlsx"), sheet="ratesMetadata") %>% mutate(state = "or") %>% select(-notes) %>% select(-GEOID)
pa.meta <- read_excel(paste0(swd_data, "rates_data\\rates_pa.xlsx"), sheet="ratesMetadata") %>% mutate(state = "pa") %>% select(-notes)
nc.meta <- read_excel(paste0(swd_data, "rates_data\\rates_nc.xlsx"), sheet="ratesMetadata") %>% mutate(state = "nc") %>% select(-notes) %>% mutate(pwsid = paste0("NC",str_remove_all(pwsid, "[-]")))
tx.meta <- read_excel(paste0(swd_data, "rates_data\\rates_tx.xlsx"), sheet="ratesMetadata") %>% mutate(state = "tx") %>% select(-notes)
nm.meta <- read_excel(paste0(swd_data, "rates_data\\rates_nm.xlsx"), sheet="ratesMetadata") %>% mutate(state = "nm") %>% select(-notes)
nj.meta <- read_excel(paste0(swd_data, "rates_data\\rates_nj.xlsx"), sheet="ratesMetadata") %>% mutate(state = "nj") %>% select(-notes)
ct.meta <- read_excel(paste0(swd_data, "rates_data\\rates_ct.xlsx"), sheet="ratesMetadata") %>% mutate(state = "ct") %>% select(-notes)
ks.meta <- read_excel(paste0(swd_data, "rates_data\\rates_ks.xlsx"), sheet="ratesMetadata") %>% mutate(state = "ks") %>% select(-notes)
wa.meta <- read_excel(paste0(swd_data, "rates_data\\rates_wa.xlsx"), sheet="ratesMetadata") %>% mutate(state = "wa") %>% select(-notes)



#condense to similar names
all.meta <- rbind(ca.meta, or.meta, pa.meta, nj.meta, nm.meta, nc.meta, tx.meta, ct.meta, ks.meta, wa.meta)
all.meta <- all.meta %>% mutate(date = as.Date(paste0(year,"-",month,"-",day), "%Y-%m-%d")) %>% filter(pwsid %in% main.data$pwsid) %>% 
  select(pwsid, service_area, city_name, utility_name, date, year, month, day, service_type, website, last_updated) %>% rename(service = service_type)
table(all.meta$service, useNA="ifany")

#save most recent data
all.meta <- all.meta %>% group_by(pwsid, service_area, city_name, utility_name, service) %>% filter(date == max(date)) %>% ungroup()

#remove cities and just keep distinct service area and utility
all.meta <- all.meta %>% filter(service != "stormwater" | service == "stormwater" & substr(website,0,4) == "http") %>% distinct() %>% 
  mutate(service = ifelse(service=="sewer", "wastewater", service)) %>% mutate(service = ifelse(service=="sewer_septic", "septic/on-site", service)) %>% 
  mutate(service = ifelse(service=="water", "drinking water", service)) 

all.meta <- all.meta %>% mutate(order = ifelse(service=="drinking water", 1, ifelse(service=="wastewater", 2, ifelse(service=="septic/on-site", 3, ifelse(service=="stormwater", 4, 5))))) %>% 
  arrange(pwsid, order, utility_name, city_name) %>% distinct()
table(all.meta$order, useNA="ifany")

all.meta <- all.meta %>% select(-month, -day)

#save file
write.csv(all.meta, paste0(swd_html, "rates_metadata.csv"), row.names = FALSE)
