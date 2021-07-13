#######################################################################################################################################################
#
# This script is run once a year to find and update data for the affordability dashboard. Run each time a new state is added.
#  Crated by Lauren Patterson, 2021
#
########################################################################################################################################################

###################################################################################################################################################################
#
# UPDATE CENSUS SPATIAL DATA. Will need municipal boundaries to create inside and outside service areas
#
####################################################################################################################################################################

##################################
#   (1)   MUNICIPALITIES / PLACES
#################################

#call census api
muni <- read_sf("https://opendata.arcgis.com/datasets/d8e6e822e6b44d80b4d3b5fe7538576d_0.geojson");
#reduce to states of interest
muni <-  muni %>% filter(STFIPS %in% state.fips) %>% select(NAME, CLASS, STFIPS, PLACEFIPS, SQMI, geometry) %>% rename(city_name = NAME) %>% st_transform(crs = 4326) 
muni <- muni %>% mutate(state = ifelse(STFIPS == "06", "ca", ifelse(STFIPS == "41", "or", "hold")))

#or systems are based on municipality
muni.or <- muni %>% filter(state=="or")
geojson_write(muni.or, file = paste0(swd_data, folder.year, "\\or_systems.geojson"))


#look to see if CA, PA, TX, or NC have their own municipal boundaries datasets. Prefer to use states when can.
#CA
ca.muni <- read_sf("https://opendata.arcgis.com/datasets/35487e8c86644229bffdb5b0a4164d85_0.geojson")
#remove unincorporated areas
ca.muni <- ca.muni %>% filter(CITY != "Unincorporated") %>% st_transform(crs = 4326) %>% select(CITY, geometry) %>% rename(city_name = CITY) %>% mutate(state="ca")
  mapview::mapview(ca.muni)

#PA, the url works but geojson_read and sf_read do not work directly. Therefore need to temporarily download and read in
tmp <- tempfile()
curl_download("https://www.pasda.psu.edu/json/PaMunicipalities2020_01.geojson", tmp); 
pa.muni <- read_sf(tmp) %>% st_transform(crs = 4326) %>% select(MUNICIPAL1, geometry) %>% rename(city_name = MUNICIPAL1) %>% mutate(state="pa")
  mapview::mapview(pa.muni)

#NC
nc.muni <- read_sf("https://opendata.arcgis.com/datasets/ee098aeaf28d44138d63446fbdaac1ee_0.geojson") %>% st_transform(crs = 4326) %>% select(MunicipalBoundaryName, geometry) %>% 
  rename(city_name = MunicipalBoundaryName) %>% mutate(state="nc")
  mapview::mapview(nc.muni)

#TX
tx.muni <- read_sf("https://opendata.arcgis.com/datasets/09cd5b6811c54857bd3856b5549e34f0_0.geojson") %>% st_transform(crs = 4326) %>% select(CITY_NM, geometry) %>% rename(city_name = CITY_NM) %>% mutate(state="tx")
  
#bind state munis together and save into affordability data folder
muni <- muni %>% filter(state %in% c("or")) %>% select(city_name, geometry, state) #only keep those states where another spatial file for municipal boundaries was not found
muni <- rbind(muni, ca.muni, pa.muni, nc.muni, tx.muni); 
all.muni <- muni %>% ms_simplify(keep=0.5, keep_shapes=TRUE); #simplify shapefiles a little (helps st_intersetion to work better)
geojson_write(all.muni, file = paste0(swd_data, "muni.geojson"))

#chck to find a good balance of simplifying polygons... 0.08 for munis is pretty good... miss some tiny pokey parts. I think more simplified for dashboard, but 0.5 start to lose too much.
leaflet() %>% addProviderTiles("Stamen.TonerLite") %>% 
  addPolygons(data = all.muni,  fillOpacity= 0.6,  fillColor = "gray", color="black",  weight=3) %>% 
  addPolygons(data = muni,  fillOpacity= 0.3,  fillColor = "white", color="red",  weight=1) 



##################################
#   (2)   COUNTIES & STATES
#################################
county <- get_acs(geography = "county", variables = "B01001_001E", state = state.fips, year = selected.year, geometry = TRUE) %>% st_transform(crs = 4326); #pulls county variable
#pull out state variables
county <- county %>% mutate(state_fips = substr(GEOID,0,2)) %>% select(GEOID, NAME, state_fips, geometry)
#create name - remove anything before "County"... or before ","
county <- county %>% mutate(name = gsub("(.*),.*", "\\1", NAME)) %>% mutate(name = substr(name,0,(nchar(name)-7))) %>% 
  mutate(state = ifelse(state_fips=="48", "tx", ifelse(state_fips=="06", "ca", ifelse(state_fips=="41", "or", ifelse(state_fips=="37", "nc", ifelse(state_fips=="42", "pa", "uh-oh")))))) %>% select(-NAME, -state_fips)
table(county$state)
county <- county %>% ms_simplify(keep=0.45, keep_shapes=TRUE)
geojson_write(county, file = paste0(swd_data, "county.geojson"))

#check to find a good balance of simplifying polygons
leaflet() %>% addProviderTiles("Stamen.TonerLite") %>% 
  addPolygons(data = county,  fillOpacity= 0.6,  fillColor = "gray", color="black",  weight=3) %>% 
  addPolygons(data = bk.up,  fillOpacity= 0.3,  fillColor = "white", color="red",  weight=1) 


state <- get_acs(geography = "state", variables = "B01001_001E", year = selected.year, geometry=TRUE) %>% st_transform(crs= 4326)
state <- state %>% select(GEOID, NAME, geometry) %>% rename(geoid = GEOID, name = NAME)
state <- state %>% mutate(data = ifelse(geoid %in% state.fips, "yes", "no")) %>% mutate(data = ifelse(name == "Oregon", "muni", data))
geojson_write(state, file = paste0(swd_data, "state.geojson"))



##################################
#   (3)   CENSUS TRACTS
#################################
#grab data for census tracts - can go back to 2010 with acs - only do one variable with geometry or it creates a massive shapefile   
fips = unique(substr(county$GEOID,3,5)); #list of unique county fips codes that we want census tract and block group data for
tract.sf <- get_acs(geography = "tract", variables = "B19080_001E", state = state.fips, county = fips, year = selected.year, geometry = TRUE); #set geometry as true to get spatial file for intersecting later
bk.up <- tract.sf;
tract.sf <- tract.sf %>% select(GEOID, geometry) %>% mutate(state_fips = substr(GEOID,0,2)) %>% 
  mutate(state = ifelse(state_fips=="48", "tx", ifelse(state_fips=="06", "ca", ifelse(state_fips=="41", "or", ifelse(state_fips=="37", "nc", ifelse(state_fips=="42", "pa", "uh-oh")))))) %>% select(-state_fips)
#tract.sf <- tract.sf %>% ms_simplify(keep=0.45, keep_shapes=TRUE); #don't simplify right now - keep full size for analysis. Simplify for dashboard.
geojson_write(tract.sf, file = paste0(swd_data, "tract_", selected.year,".geojson"))


##################################
#   (4)   CENSUS BLOCK GROUPS
#################################
#grab data for census block groups - super slow to do all at once. Do one at a time
i=1;
bkgroup.sf <- get_acs(geography = "block group", variables = "B19080_001E", state = state.fips[i], year = selected.year, geometry = TRUE); #set geometry as true to get spatial file for intersecting later
for (i in 2:length(state.fips)){
  bk.up <- get_acs(geography = "block group", variables = "B19080_001E", state = state.fips[i], year = selected.year, geometry = TRUE); #set geometry as true to get spatial file for intersecting later
  bkgroup.sf <- rbind(bkgroup.sf, bk.up);
  print(state.fips[i]);
}

bk.up <- bkgroup.sf;
bkgroup.sf <- bkgroup.sf %>% select(GEOID, geometry) %>% mutate(state_fips = substr(GEOID,0,2)) %>% 
  mutate(state = ifelse(state_fips=="48", "tx", ifelse(state_fips=="06", "ca", ifelse(state_fips=="41", "or", ifelse(state_fips=="37", "nc", ifelse(state_fips=="42", "pa", "uh-oh")))))) %>% select(-state_fips)
geojson_write(bkgroup.sf, file = paste0(swd_data,"block_groups_",selected.year,".geojson"))



###############################################################################################################################################################################################################
#
#   (5)   UPDATE CENSUS TIME SERIES DATA NEEDED FOR ANALYSIS
#
###############################################################################################################################################################################################################
#######################################################
#   TRACT CENSUS DATA FOR AFFORDABILITY ANALYSIS
########################################################
vars <- c('B19080_001E','B19013_001E',"B01001_001E","B08201_001E") 
#grab data for census tracts - can go back to 2010 with acs        
census.tract <- get_acs(geography = "tract", variables = vars, state = state.fips, county = fips, year = selected.year, geometry = FALSE)
foo <- get_acs(geography = "tract", variables = c("S0101_C01_001E", "S1701_C01_042E"), state= state.fips, county=fips, year = selected.year, geometry = FALSE)
census.tract <- rbind(census.tract, foo)
write.csv(census.tract, paste0(swd_data, "census_time\\census_tract_",selected.year,".csv"), row.names=FALSE)


#########################################################
#   ACCESS BLOCK GROUP DATA FOR AFFORDABILITY ANALYSIS
#########################################################
i = 1;
block.data <- get_acs(geography = "block group", variables=c("B01001_001E","B19001_001E", "B19001_002E", "B19001_003E", "B19001_004E", "B19001_005E", "B19001_006E", "B19001_007E", "B19001_008E",
                                                             "B19001_009E", "B19001_010E", "B19001_011E", "B19001_012E", "B19001_013E", "B19001_014E", "B19001_015E", "B19001_016E", "B19001_017E", "B19013_001E"), 
                      state=state.fips[i], year=selected.year, geometry = FALSE)
for (i in 2:length(state.fips)){
  bk.up <- get_acs(geography = "block group", variables=c("B01001_001E","B19001_001E", "B19001_002E", "B19001_003E", "B19001_004E", "B19001_005E", "B19001_006E", "B19001_007E", "B19001_008E",
                                                          "B19001_009E", "B19001_010E", "B19001_011E", "B19001_012E", "B19001_013E", "B19001_014E", "B19001_015E", "B19001_016E", "B19001_017E", "B19013_001E"), 
                   state=state.fips[i], year=selected.year, geometry = FALSE)
  block.data <- rbind(block.data, bk.up)
  pring(state.fips[i]);
}
write.csv(block.data, paste0(swd_data,"census_time\\block_group_",selected.year,".csv"), row.names=FALSE)                        


######################################################################################################################################################################
##   CENSUS TAB OF DASHBOARD
#######################################################################################################################################################################
########################################################
##   Population Change Over Time by Block Group
########################################################
#since block groups change over time - we pull from IPUMS Data... #IPUMS NHGIS... block group... time series... JUST PULL FROM CURRENT AND ADD TO IT
pop.time <- read.csv(paste0(swd_data, "census_time/nhgis0033_ts_geog2010_blck_grp.csv")) 

#create GEOID
pop.time <- pop.time %>% mutate(GEOID_state = ifelse(nchar(STATEA)==1, paste0("0",STATEA), STATEA)) %>% 
  mutate(GEOID_county = ifelse(nchar(COUNTYA)==1, paste0("00",COUNTYA), ifelse(nchar(COUNTYA)==2, paste0("0", COUNTYA), COUNTYA))) %>% #county add zeros to front
  mutate(GEOID_tract = ifelse(nchar(TRACTA)==3, paste0("000",TRACTA), ifelse(nchar(TRACTA)==4, paste0("00",TRACTA), ifelse(nchar(TRACTA)==5, paste0("0",TRACTA), TRACTA))))

pop.time <- pop.time %>% mutate(GEOID = paste0(GEOID_state, GEOID_county, GEOID_tract, BLCK_GRPA)) %>% select(GISJOIN, GEOID, STATE, COUNTY, CL8AA1990, CL8AA2000, CL8AA2010)
colnames(pop.time) <- c("GISJOIN", "GEOID", "state", "county", "pop1990", "pop2000", "pop2010")
pop.time <- pop.time %>% mutate(pop1990 = round(pop1990,0), pop2000 = round(pop2000, 0)) %>% mutate(GISJOIN = as.character(GISJOIN))

#grab current 5 year summary from above and create variable to match their unique ID
pop.now <- block.data %>% filter(variable=="B01001_001") %>% select(GEOID, estimate) %>% mutate(GEOID = ifelse(nchar(GEOID) == 11, paste0("0",GEOID), GEOID)) %>% rename(popNow = estimate)
pop.time <- merge(pop.time, pop.now, by.x="GEOID", by.y="GEOID", all.y=TRUE)

#write to file
write.csv(pop.time, paste0(swd_data,"census_time\\bkgroup_pop_time.csv"), row.names=FALSE)


###########################################################
#   Population below 18, 18 - 65, and over 65
###########################################################
age.vars <- c("B06001_001E", "B06001_002E","B06001_003E","B06001_004E","B06001_005E","B06001_006E","B06001_007E","B06001_008E","B06001_009E","B06001_010E","B06001_011E","B06001_012E")
#no data at block group scale... go to tracts
age.pop <- get_acs(geography = "tract", variables = age.vars, state = state.fips, county = fips, year = selected.year, geometry = FALSE)
#age.pop <- get_acs(geography = "block group", variables = age.vars, state = state.fips, year = selected.year, geometry = FALSE)
head(age.pop)
#rename variable
age.pop <- age.pop %>% mutate(age = ifelse(variable=="B06001_001", "Total", ifelse(variable=="B06001_002", "Ages<5", ifelse(variable=="B06001_003", "Ages5-17", ifelse(variable=="B06001_004","Ages18-24",
                                    ifelse(variable=="B06001_005", "Ages25-34", ifelse(variable=="B06001_006", "Ages35-44", ifelse(variable=="B06001_007","Ages45-54", ifelse(variable=="B06001_008","Ages55-59",
                                    ifelse(variable=="B06001_009", "Ages60-61", ifelse(variable=="B06001_010", "Ages62-64", ifelse(variable=="B06001_011","Ages65-74", "Ages>75"))))))))))))

#group by category
age.pop <- age.pop %>% mutate(ageGroup = ifelse((age=="Ages<5" | age=="Ages5-17"), "under18", ifelse((age=="Ages18-24" | age=="Ages25-34"), "age18to34", ifelse((age=="Ages35-44" | age=="Ages45-54" | age=="Ages55-59"), "age35to59",
                                          ifelse((age=="Ages60-61" | age=="Ages62-64"), "age60to64", ifelse((age=="Ages65-74" | age=="Ages>75"), "over65", "total"))))))
age.pop2 <- age.pop %>% group_by(GEOID, ageGroup) %>% summarize(population = sum(estimate, na.rm=TRUE), .groups="drop")
#spread out
age.pop2 <- age.pop2 %>% group_by(GEOID) %>% spread(ageGroup, population) %>% as.data.frame()
#write to file
write.csv(age.pop2, paste0(swd_data, "census_time\\tract_age.csv"), row.names=FALSE)


###########################################################
#   Racial Characterization
###########################################################
race.vars <- c("B02001_001E", "B02001_002E", "B02001_003E", "B02001_004E", "B02001_005E", "B02001_006E", "B02001_007E", "B02001_008E" );
race.pop <- get_acs(geography = "tract", variables = race.vars, state = state.fips, county = fips, year = selected.year, geometry = FALSE)
head(race.pop)

#rename variable
race.pop2 <- race.pop %>% mutate(race = ifelse(variable=="B02001_001", "Total", ifelse(variable=="B02001_002", "white", ifelse(variable=="B02001_003", "Black", ifelse(variable=="B02001_004", "Native",
                                        ifelse(variable=="B02001_005", "Asian", ifelse(variable=="B02001_006","Pacific Islander", ifelse(variable=="B02001_007", "Other", "Multiple Races"))))))))
table(race.pop2$race)
race.pop2 <- race.pop2 %>% mutate(raceGroup = ifelse(race=="Pacific Islander" | race=="Other" | race=="Multiple Races", "other", race))
race.pop2 <- race.pop2 %>% group_by(GEOID, raceGroup) %>% summarize(population = sum(estimate, na.rm=TRUE), .groups="drop")
#spread out
race.pop2 <- race.pop2 %>% group_by(GEOID) %>% spread(raceGroup, population) %>% as.data.frame()

hispanic.vars <- c("B03001_001E", "B03001_002E", "B03001_003E");  #not at block group, only tract level.
his.pop <- get_acs(geography = "tract", variables = hispanic.vars, state = state.fips, county = fips, year = selected.year, geometry = FALSE) %>% as.data.frame()
#rename variable
his.pop <- his.pop %>% mutate(hispanic = ifelse(variable=="B03001_001", "Total", ifelse(variable=="B03001_002", "NotHispanic", ifelse(variable=="B03001_003", "Hispanic", NA))))
table(his.pop$hispanic)
#spread out
his.pop2 <- his.pop %>% select(GEOID, hispanic, estimate) %>% group_by(GEOID) %>% spread(hispanic, estimate) %>% select(-Total) %>% as.data.frame()
#merge to race and save out
race.pop2 <- merge(race.pop2, his.pop2, by.x="GEOID", by.y="GEOID", all=TRUE)

#write to file
write.csv(race.pop2, paste0(swd_data, "census_time\\tract_race.csv"), row.names=FALSE)


##############################################################
##   Income Characterizations
##############################################################
hh.by.income <- block.data %>% filter(variable %in% c("B19001_001", "B19001_002", "B19001_003", "B19001_004", "B19001_005", "B19001_006", "B19001_007", "B19001_008",
                                                     "B19001_009", "B19001_010", "B19001_011", "B19001_012", "B19001_013", "B19001_014", "B19001_015", "B19001_016", "B19001_017"))
hh.income <- hh.by.income %>% select(GEOID, variable, estimate) %>% spread(variable, estimate)
colnames(hh.income) <- c("GEOID", "totalhh", "hh10","hh15","hh20","hh25","hh30","hh35","hh40","hh45","hh50","hh60","hh75","hh100","hh125","hh150","hh200","hh200more")

#calculate percent of homes and remove total households... group by $25 buckets to be consistent across
hh.income$d0to24k <- round((hh.income$hh10 + hh.income$hh15 + hh.income$hh20 + hh.income$hh25))#/hh.income$totalhh*100,2)
hh.income$d25to49k <- round((hh.income$hh30 + hh.income$hh35 + hh.income$hh40 + hh.income$hh45 + hh.income$hh50))#/hh.income$totalhh*100, 2)
hh.income$d50to74k <- round((hh.income$hh60 + hh.income$hh75))#/hh.income$totalhh*100, 2)
hh.income$d75to100k <- round(hh.income$hh100)#/hh.income$totalhh*100, 2)
hh.income$d100to125k <- round(hh.income$hh125)#/hh.income$totalhh*100, 2)
hh.income$d125to150k <- round(hh.income$hh150)#/hh.income$totalhh*100, 2)
hh.income$d150kmore <- round((hh.income$hh200 + hh.income$hh200more))#/hh.income$totalhh*100, 2)

#reduce dataset
hh.income <- hh.income %>% select(GEOID, totalhh, d0to24k, d25to49k, d50to74k, d75to100k, d100to125k, d125to150k, d150kmore)
#write to file
write.csv(hh.income, paste0(swd_data, "census_time\\block_group_income.csv"), row.names=FALSE)



######################################################################################################################################################################
##   HH AGE CHARACTERISTICS
#######################################################################################################################################################################
hh.age <- get_acs(geography = "block group", variables=c("B25034_001E","B25034_002E","B25034_003E","B25034_004E","B25034_005E","B25034_006E","B25034_007E", "B25034_008E", "B25034_009E", "B25034_010E", "B25034_011E"), 
                  state=state.fips, year=selected.year, geometry = FALSE)
bk.up <- hh.age
table(substr(hh.age$GEOID, 0,2), useNA="ifany")
hh.age <- hh.age %>% select(GEOID, variable, estimate) %>% spread(variable, estimate)
colnames(hh.age) <- c("GEOID", "totalhh", "built_2014later", "built_2010to2013", "built_2000to2009", "built_1990to1999", "built_1980to1989", "built_1970to1979", "built_1960to1969", "built_1950to1959", "built_1940to1949",
                      "built_1939early")
hh.age <- hh.age %>% mutate(built_2010later = built_2014later+built_2010to2013) %>% select(GEOID, totalhh, built_2010later, built_2000to2009, built_1990to1999, built_1980to1989, built_1970to1979, built_1960to1969,
                                                                                           built_1950to1959, built_1940to1949, built_1939early)
#save out full amount because will add over service area
write.csv(hh.age, paste0(swd_data, "census_time\\bg_house_age.csv"), row.names=FALSE)                        



