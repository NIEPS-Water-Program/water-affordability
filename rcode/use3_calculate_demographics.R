#################################################################################################################################################################################
#
#  CODE FOR CENSUS DATA IN AFFORDABILITY DASHBOARD
#  CREATED by Lauren Patterson, 2021
#
#################################################################################################################################################################################


######################################################################################################################################################################
#
#   MERGE CENSUS DATA WITH PWSID AND CALCULATE VALUES
#
######################################################################################################################################################################
#read files
pop <- read.csv(paste0(swd_data, "census_time\\bkgroup_pop_time.csv"), colClasses=c("GEOID" = "character")) %>% select(-GISJOIN, -state, -county) %>% mutate(GEOID = ifelse(nchar(GEOID) ==11, paste0("0",GEOID), GEOID))
age <- read.csv(paste0(swd_data, "census_time\\tract_age.csv"), colClasses=c("GEOID" = "character")) %>% mutate(GEOID = ifelse(nchar(GEOID) ==10, paste0("0",GEOID), GEOID))
race <- read.csv(paste0(swd_data, "census_time\\tract_race.csv"), colClasses=c("GEOID" = "character")) %>% mutate(GEOID = ifelse(nchar(GEOID) ==10, paste0("0",GEOID), GEOID))
hh.income <- read.csv(paste0(swd_data,"census_time\\block_group_income.csv"), colClasses=c("GEOID" = "character"))
build.age <- read.csv(paste0(swd_data, "census_time\\bg_house_age.csv"), colClasses=c("GEOID" = "character"))

cws <- read.csv(paste0(swd_data, "sdwis\\cws_systems.csv")) %>% select(PWSID, POPULATION_SERVED_COUNT)


#read in all.block.scores to link GEOID with PWSID
all.block.scores <- read.csv(paste0(swd_results, "utility_block_scores_", selected.year, ".csv"), colClasses=c("GEOID" = "character")); 
all.block.scores <- all.block.scores %>% mutate(GEOID = ifelse(nchar(GEOID) ==11, paste0("0",GEOID), GEOID)) %>% #sometimes the 0 is still being left out
  mutate(tracts = substr(GEOID,0,11), county = substr(GEOID,1,5)) %>% select(pwsid, service_area, GEOID, tracts, county, perArea) %>% distinct()
#very small systems cannot be weighted. Change to NA.... it seems 15% makes most of the metrics fairly close. Some still are over 100%
tooSmall <- all.block.scores %>% group_by(pwsid, service_area) %>% summarize(n = n(), totalArea = sum(perArea, na.rm=TRUE), .groups="drop") %>% mutate(keep = ifelse(totalArea >= 15, "keep", "too small"))
table(tooSmall$keep);
head(tooSmall %>% filter(keep=="too small" & totalArea>14.5))

#Now summarize by groups
pop <- merge(all.block.scores, pop, by.x="GEOID", by.y="GEOID", all.x=TRUE) %>% distinct()
#pop <- pop %>% mutate(pop1990 = ceiling(pop1990*perArea/100), pop2000 = ceiling(pop2000*perArea/100), pop2010 = ceiling(pop2010*perArea/100), popNow = ceiling(popNow*perArea/100));
pop <- pop %>% group_by(pwsid, service_area) %>% summarize(pop1990 = sum(pop1990, na.rm=TRUE), pop2000 = sum(pop2000, na.rm=TRUE), pop2010 = sum(pop2010, na.rm=TRUE), popNow = sum(popNow, na.rm=TRUE), .groups="keep")

pop2 <- merge(pop, cws, by.x="pwsid", by.y="PWSID", all.x=TRUE)
pop2 <- pop2 %>% mutate(cwsPop = ifelse(is.na(POPULATION_SERVED_COUNT), popNow, POPULATION_SERVED_COUNT)) %>% select(-POPULATION_SERVED_COUNT)
#weight popNow by cwsPop and adjust earlier years accordingly
pop2 <- pop2 %>% mutate(perCWS = cwsPop/popNow, pop1990a = ceiling(pop1990*perCWS), pop2000a = ceiling(pop2000*perCWS), pop2010a = ceiling(pop2010*perCWS))
pop <- pop2 %>% select(pwsid, service_area, pop1990a, pop2000a, pop2010a, cwsPop) %>% rename(pop1990 = pop1990a, pop2000 = pop2000a, pop2010 = pop2010a)
#names(pop)[names(pop) == 'popNow'] <-  paste0("pop",selected.year); leave cwsPop because makes easier in scripts

#age
all.tract.scores <- all.block.scores %>% select(pwsid, service_area, tracts, perArea) %>% distinct()
age <-merge(all.tract.scores, age, by.x="tracts", by.y="GEOID", all.x=TRUE)
#if only one census tract... do not need to weight... if more than 5, weight age, otherwise just use basic proportions
age <- age %>% group_by(pwsid) %>% mutate(count=n()) %>% mutate(age18to34 = ifelse(count>5, ceiling(age18to34*perArea/100), age18to34), age35to59 = ifelse(count>5, ceiling(age35to59*perArea/100), age35to59),
                                                                age60to64 = ifelse(count>5, ceiling(age60to64*perArea/100), age60to64), over65 = ifelse(count>5, ceiling(over65*perArea/100), over65),
                                                                under18 = ifelse(count>5, ceiling(under18*perArea/100), under18))
age <- age %>% group_by(pwsid) %>% summarize(under18 = sum(under18, na.rm=TRUE), age18to34 = sum(age18to34, na.rm=TRUE), age35to59 = sum(age35to59, na.rm=TRUE), age60to64 = sum(age60to64, na.rm=TRUE), 
                                                                     over65 = sum(over65, na.rm=TRUE), .groups="drop")
age <- age %>% mutate(total = under18+age18to34+age35to59+age60to64+over65)
#sums are much higher because census tracts instead of block group so only want percent of population
age <- age %>% mutate(under18 = round(under18/total*100,2), age18to34 = round(age18to34/total*100,2), age35to59 = round(age35to59/total*100,2), age60to64 = round(age60to64/total*100,2), over65 = round(over65/total*100,2))
age <- age %>% mutate(total = under18+age18to34+age35to59+age60to64+over65)
age <- age %>% select(-total)

census.data <- merge(pop, age, by.x="pwsid", by.y="pwsid", all=TRUE)

#add race
race <- merge(all.tract.scores, race, by.x="tracts", by.y="GEOID", all.x=TRUE)
#if few census tracts... do not weight... if more than 5, weight age, otherwise just use basic proportions
race <- race %>% group_by(pwsid) %>% mutate(count=n()) %>% mutate(Asian = ifelse(count>5, ceiling(Asian*perArea/100), Asian), Black = ifelse(count>5, ceiling(Black*perArea/100), Black),
                                                                Native = ifelse(count>5, ceiling(Native*perArea/100), Native), other = ifelse(count>5, ceiling(other*perArea/100), other),
                                                                white = ifelse(count>5, ceiling(white*perArea/100), white), Hispanic = ifelse(count>5, ceiling(Hispanic*perArea/100), Hispanic)) %>% select(-NotHispanic)

race <- race %>% group_by(pwsid) %>% summarize(Asian = sum(Asian, na.rm=TRUE), Black = sum(Black, na.rm=TRUE), Native = sum(Native, na.rm=TRUE), Other = sum(other, na.rm=TRUE), 
                                                                       White = sum(white, na.rm=TRUE), Hispanic = sum(Hispanic, na.rm=TRUE), .groups="drop")
race <- race %>% mutate(Total = Asian+Black+Native+White+Other)
race <- race %>% mutate(Asian = round(Asian/Total*100,2), Black = round(Black/Total*100,2), Native = round(Native/Total*100,2), Other = round(Other/Total*100,2), White = round(White/Total*100,2),
                                  Hispanic = round(Hispanic/Total*100,2)) 
race <- race %>% mutate(Total = Asian+Black+Native+White+Other)
race <- race %>% select(-Total)
census.data <- merge(census.data, race, by.x="pwsid", by.y="pwsid", all=TRUE)

#add hh income
hh.inc <- merge(all.block.scores, hh.income, by.x="GEOID", by.y="GEOID", all.x=TRUE)
#if only a few block groups... do not weight... if more than 5, weight age, otherwise just use basic proportions
hh.inc <- hh.inc %>% group_by(pwsid) %>% mutate(count = n()) %>% mutate(d0to24k=ifelse(count>5, ceiling(d0to24k*perArea/100), d0to24k), d25to49k = ifelse(count>5,ceiling(d25to49k*perArea/100), d25to49k),
                                                                        d50to74k=ifelse(count>5, ceiling(d50to74k*perArea/100), d50to74k), d75to100k=ifelse(count>5, ceiling(d75to100k*perArea/100), d75to100k),
                                                                        d100to125k=ifelse(count>5, ceiling(d100to125k*perArea/100), d100to125k), d125to150k=ifelse(count>5, ceiling(d125to150k*perArea/100), d125to150k),
                                                                        d150kmore=ifelse(count>5, ceiling(d150kmore*perArea/100), d150kmore))
#sum and calculate percent
hh.inc <- hh.inc %>% group_by(pwsid, service_area) %>% summarize(d0to24k = sum(d0to24k, na.rm=TRUE), d25to49k = sum(d25to49k, na.rm=TRUE), d50to74k = sum(d50to74k, na.rm=TRUE), d75to100k = sum(d75to100k, na.rm=TRUE),
                                                                 d100to125k = sum(d100to125k, na.rm=TRUE), d125to150k = sum(d125to150k, na.rm=TRUE), d150kmore = sum(d150kmore, na.rm=TRUE), totalhh = sum(totalhh, na.rm=TRUE), .groups="drop")
hh.inc <- hh.inc %>% mutate(totalhh = d0to24k+d25to49k+d50to74k+d75to100k+d100to125k+d125to150k+d150kmore)
hh.inc <- hh.inc %>% mutate(d0to24k = round(d0to24k/totalhh*100,2), d25to49k = round(d25to49k/totalhh*100,2), d50to74k = round(d50to74k/totalhh*100,2),
                                                                 d75to100k = round(d75to100k/totalhh*100,2), d100to125k = round(d100to125k/totalhh*100,2), d125to150k = round(d125to150k/totalhh*100,2),
                                                                 d150kmore = round(d150kmore/totalhh*100,2))
hh.inc <- hh.inc %>% mutate(total = d0to24k+d25to49k+d50to74k+d75to100k+d100to125k+d125to150k+d150kmore)
hh.inc <- hh.inc %>% select(-service_area, -totalhh, -total);
census.data <- merge(census.data, hh.inc, by.x="pwsid", by.y="pwsid", all = TRUE)
summary(census.data)

#add in age of buildings
build.age <- merge(all.block.scores, build.age, by.x="GEOID", by.y="GEOID", all.x=TRUE) %>% distinct()
build.age <- build.age %>% group_by(pwsid) %>% mutate(count=n()) %>% 
  mutate(built_2010later = ifelse(count>5, ceiling(built_2010later*perArea/100), built_2010later), built_2000to2009 = ifelse(count>5, ceiling(built_2000to2009*perArea/100), built_2000to2009),
         built_1990to1999 = ifelse(count>5, ceiling(built_1990to1999*perArea/100), built_1990to1999), built_1980to1989 = ifelse(count>5, ceiling(built_1980to1989*perArea/100), built_1980to1989),
         built_1970to1979 = ifelse(count>5, ceiling(built_1970to1979*perArea/100), built_1970to1979), built_1960to1969 = ifelse(count>5, ceiling(built_1960to1969*perArea/100), built_1960to1969),
         built_1950to1959 = ifelse(count>5, ceiling(built_1950to1959*perArea/100), built_1950to1959), built_1940to1949 = ifelse(count>5, ceiling(built_1940to1949*perArea/100), built_1940to1949),
         built_1939early = ifelse(count>5, ceiling(built_1939early*perArea/100), built_1939early))

build.age <- build.age %>% group_by(pwsid, service_area) %>% summarize(built_2010later = sum(built_2010later, na.rm=TRUE), built_2000to2009 = sum(built_2000to2009, na.rm=TRUE), built_1990to1999 = sum(built_1990to1999, na.rm=TRUE),
                                                                         built_1980to1989 = sum(built_1980to1989, na.rm=TRUE), built_1970to1979 = sum(built_1970to1979, na.rm=TRUE), built_1960to1969 = sum(built_1960to1969, na.rm=TRUE),
                                                                         built_1950to1959 = sum(built_1950to1959, na.rm=TRUE), built_1940to1949 = sum(built_1940to1949, na.rm=TRUE), built_1939early = sum(built_1939early, na.rm=TRUE),
                                                                         totalhh = sum(totalhh, na.rm=TRUE), .groups="drop")
build.age <- build.age %>% mutate(totalhh = built_2010later+built_2000to2009+built_1990to1999+built_1980to1989+built_1970to1979+built_1960to1969+built_1950to1959+built_1940to1949+built_1939early)

build.age <- build.age %>%  mutate(built_2010later = round(built_2010later/totalhh*100,2), built_2000to2009 = round(built_2000to2009/totalhh*100,2), built_1990to1999 = round(built_1990to1999/totalhh*100,2),
                                     built_1980to1989 = round(built_1980to1989/totalhh*100,2), built_1970to1979 = round(built_1970to1979/totalhh*100,2), built_1960to1969 = round(built_1960to1969/totalhh*100,2),
                                     built_1950to1959 = round(built_1950to1959/totalhh*100,2), built_1940to1949 = round(built_1940to1949/totalhh*100,2), built_1939early = round(built_1939early/totalhh*100,2))
build.age <- build.age %>% mutate(total = built_2010later+built_2000to2009+built_1990to1999+built_1980to1989+built_1970to1979+built_1960to1969+built_1950to1959+built_1940to1949+built_1939early)
build.age <- build.age %>% select(-service_area, -totalhh, -total)
census.data <- merge(census.data, build.age, by.x="pwsid", by.y="pwsid", all = TRUE)

#add column if too small or keep
census.data <- merge(census.data, tooSmall %>% select(-n, -totalArea), by=c("pwsid", "service_area"))

write.csv(census.data, paste0(swd_results, "utility_census_summary.csv"), row.names=FALSE)


######################################################################################################################################################################
#
#   Unemployment rates of counties
#
######################################################################################################################################################################
bls.old <- read_excel(paste0(swd_data,"census_time\\county_unemployment.xlsx"), sheet="alldata") %>% as.data.frame()
bls.recent <- read.csv(paste0(swd_data, "census_time\\current_unemploy.csv")) %>% as.data.frame() %>% mutate(stateFips=ifelse(nchar(stateFips)==1, paste0("0", stateFips), stateFips))

#filter to relevant state
bls.old <- bls.old %>% filter(stateFips %in% state.fips); bls.old$year <- as.numeric(bls.old$year)
bls.recent <- bls.recent %>% filter(stateFips %in% state.fips) #keeps ca this way

#summarize bls.recent for 2020
bls.recent <- bls.recent %>% mutate(date = as.character(year)) %>% mutate(year_end = ifelse(is.na(as.numeric(substr(date,1,2))),substr(date,5,6), substr(date,1,2))) %>% 
  mutate(month = ifelse(is.na(as.numeric(substr(date,1,2))), substr(date,1,3), substr(date,4,6)))

table(bls.recent$year_end); table(bls.recent$month)
#bls.recent$year_end = as.numeric(gsub("([0-9]+).*$", "\\1", bls.recent$date))
bls.recent <- bls.recent %>% mutate(year = as.numeric(paste0("20", year_end))) %>% mutate(date = paste0(year_end,"-",month)) %>% select(-year_end, -month)
  
bls.2020 <- bls.recent %>% group_by(LAUSID, stateFips, countyFips, name, year) %>% summarize(labor_force = median(labor_force, na.rm=TRUE), employed = median(employed, na.rm=TRUE),
                                                                                             unemployed = median(unemployed, na.rm=TRUE), unemploy_rate = median(unemploy_rate, na.rm=TRUE), .groups="drop") %>% as.data.frame()
#lets plot only 2020 months
require(zoo)
bls.2020months <- bls.recent %>% filter(year>=2020) %>% mutate(date = as.yearmon(date, format = "%y-%b")) %>% mutate(date = as.Date(date, frac=0.0)) #sets to end date

#add 2020 to end of bls.old
bls.annual <- rbind(bls.old, bls.2020)
bls.annual = bls.annual %>% mutate(countyFips = ifelse(nchar(countyFips)==1, paste0("00",countyFips), ifelse(nchar(countyFips)==2, paste0("0",countyFips), countyFips))) %>% 
  mutate(county = as.character(paste0(stateFips, countyFips))) 
#convert to date - make end of month

#bls
all.county <- all.block.scores %>% select(pwsid, service_area, county) %>% distinct()
bls.annual  <- bls.annual %>% select(county, year, labor_force, employed, unemployed, unemploy_rate)
bls.annual2 <- merge(all.county, bls.annual, by.x="county", by.y="county", all.x=TRUE)

#sum up for those covering more than one county
bls.annual2 <- bls.annual2 %>% group_by(pwsid, year) %>% summarize(labor_force = sum(labor_force, na.rm=TRUE), employed = sum(employed, na.rm=TRUE), unemployed = sum(unemployed, na.rm=TRUE), .groups="drop") %>% 
  mutate(unemploy_rate = round(unemployed/labor_force*100,2))
summary(bls.annual2)
write.csv(bls.annual2, paste0(swd_results, "utility_bls_summary.csv"), row.names=FALSE)

bls.2020months = bls.2020months %>% mutate(county = substr(LAUSID,3,7))
bls.20202 <- merge(all.county, bls.2020months, by.x="county", by.y="county", all.x=TRUE) %>% arrange(pwsid, county, date)

#sum up for those covering more than one county
bls.20202 <- bls.20202 %>% group_by(pwsid, date) %>% summarize(labor_force = sum(labor_force, na.rm=TRUE), employed = sum(employed, na.rm=TRUE), unemployed = sum(unemployed, na.rm=TRUE), .groups="drop") %>% 
  mutate(unemploy_rate = round(unemployed/labor_force*100,2)) %>% as.data.frame();
summary(bls.20202)
subset(bls.20202, is.na(date))
write.csv(bls.20202, paste0(swd_results, "utility_bls_monthly.csv"), row.names=FALSE)



