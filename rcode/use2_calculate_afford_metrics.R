###############################################################################################################################################################################
#
# Calculates affordability metrics at block group and utility scale - this creates one metric for the utility and block group (mean of bills if differ within service area)
# Created by Lauren Patterson, 2021
#
#####################################################################################################################################################################################

######################################################################################################################################################################
#
#   VARIABLES THAT NEED TO BE CHANGED OVER TIME
#
######################################################################################################################################################################
#federal minimum wage ---------------------------------------------------------------------------------------------------------------------------------
#set up by state wages
n_states = length(state.list)
year  <- rep(seq(1979, folder.year,1),n_states)
state <- c(rep("ca", length(year)/n_states), rep("nc", length(year)/n_states), rep("pa", length(year)/n_states), 
           rep("tx", length(year)/n_states), rep("or", length(year)/n_states), rep("nm", length(year)/n_states),
           rep("nj", length(year)/n_states))
#state min wages
ca.wage <- c(2.9, 3.1, 3.35,3.35,3.35,3.35,3.35,3.35,3.35,3.35,3.35, 3.8, 4.25,4.25,4.25,4.25,4.25, 4.75, 5.15,5.15,5.15,5.15,5.15,5.15,5.15,5.15,5.15,5.15, 
             5.85, 6.55, 7.25,7.25,7.25,7.25,7.25,7.25,7.25,7.25,10.50,11,12,12, 13); 
#these use federal min wage
nc.wage <- pa.wage <- tx.wage <- c(2.9, 3.1, 3.35,3.35,3.35,3.35,3.35,3.35,3.35,3.35,3.35, 3.8, 4.25,4.25,4.25,4.25,4.25, 4.75, 5.15,5.15,5.15,5.15,5.15,5.15,5.15,5.15,5.15,5.15, 
                                   5.85, 6.55, 7.25,7.25,7.25,7.25,7.25,7.25,7.25,7.25,7.25,7.25,7.25, 7.25, 7.25)

#or minimum wage
or.wage <- c(2.9, 3.1, 3.35,3.35,3.35,3.35,3.35,3.35,3.35,3.35,3.80, 4.25, 4.75,4.75,4.75,4.75,4.75, 4.75, 5.50,6.00,6.50,6.50,6.50,6.90,7.05,7.25,7.50, 
             7.80, 7.95, 8.40, 8.40,8.50,8.80,8.95,9.10,9.25,9.25,9.75,10.25,10.75,11.25, 12, 12.75)

#nm minimum wage
nm.wage <- c(2.9, 3.1, 3.35,3.35,3.35,3.35,3.35,3.35,3.35,3.35,3.35, 3.8, 4.25,4.25,4.25,4.25,4.25, 4.75, 5.15,5.15,5.15,5.15,5.15,5.15,5.15,5.15,5.15,5.15,
             5.85, 6.50, 7.50, 7.50, 7.50, 7.50, 7.50, 7.50, 7.50, 7.50, 7.50, 7.50, 7.50, 9.00, 10.50)

#nj minimum wage
nj.wage <- c(2.9, 3.1, 3.35, 3.35, 3.35, 3.35, 3.35, 3.35, 3.35, 3.35, 3.35, 3.80, 4.25, 5.05, 5.05, 5.05, 5.05, 5.05, 5.05, 5.05, 5.15, 5.15,
             5.15, 5.15, 5.15, 5.15, 6.15, 7.15, 7.15, 7.15,  7.25, 7.25, 7.25, 7.25, 7.25, 8.25, 8.38, 8.38, 8.44, 8.6, 10.00, 11.00, 12.00)

all.wage <- c(ca.wage, nc.wage, pa.wage, tx.wage, or.wage, nm.wage, nj.wage)
#combine together - order does matter
min.wage <- cbind(state, year, all.wage) %>% as.data.frame() %>% mutate(year = as.numeric(year), all.wage = as.numeric(all.wage))
rm(list=c('year', 'state', 'n_states', 'ca.wage', 'pa.wage', 'nc.wage', 'or.wage', 'tx.wage', 'nm.wage', 'nj.wage', 'all.wage'))

# block intersection variables
percent.area.threshold <- 0.1; #set very low to make sure block group seleted
moe.threshold = 250;   #For block group data we need to set high or much of it becomes NA


######################################################################################################################################################################
#
#   LOAD DATA
#
######################################################################################################################################################################
#rates data by volume are calculated in "calculate_rates_by_usage_catogery.R
res.rates <- read.csv(paste0(swd_results, "estimated_bills.csv")) %>% mutate(state=tolower(substr(pwsid,0,2)))


##############    
    # Load Spatial Data
##############
#load tract data -----------------------------------------------------------------------------------------------------------------------------------------------------
tract.data <- read.csv(paste0(swd_data, "census_time\\census_tract_",selected.year,".csv"), colClasses=c("GEOID" = "character"))
tract.data <- tract.data %>% mutate(state_fips = substr(GEOID,0,2)) 
tract.data <- merge(tract.data, state.df, by.x="state_fips", by.y="state.fips") %>% select(-state_fips) %>% rename(state = state.list)
table(tract.data$state, useNA = "ifany")

#reshape file
tract.data <- tract.data %>%  mutate(perError = ifelse(estimate==0, 0, round(moe/estimate*100,2))) %>% 
      select(GEOID, state, variable, estimate) %>% spread(variable, estimate) %>%  #reshape the dataset  
      mutate(PPI = round(S1701_C01_042/S0101_C01_001*100,2)) #calculate PPI indicator

colnames(tract.data) <- c("tractID", "state", "tractPop","tractHH","tractMedIncome","tractQ20","nhhSurvey200", "nhhPov200","PPI")
table(tract.data$state, useNA="ifany")

#load census block data ---------------------------------------------------------------------------------------------------------------------------------
block.group.all <- read.csv(paste0(swd_data, "census_time\\block_group_",selected.year,".csv"), colClasses=c("GEOID" = "character"))
block.group.all <- block.group.all %>% mutate(state_fips = substr(GEOID,0,2)) 
block.group.all <- merge(block.group.all, state.df, by.x="state_fips", by.y="state.fips") %>% select(-state_fips) %>% rename(state = state.list)
table(block.group.all$state, useNA="ifany")
  
#load shapefile data ------------------------------------------------------------------------------------------------------------------------------------------------------------------
#NOTE WE WANT TO LOAD IN THE INSIDE AND OUTSIDE VERSIONS WHERE POSSIBLE
ca.systems <- read_sf(paste0(swd_data, "ca_in_out_systems.geojson")) %>% mutate(systemarea = st_area(geometry)) %>% mutate(state="ca")
nc.systems <- read_sf(paste0(swd_data, "nc_in_out_systems.geojson")) %>% mutate(systemarea = st_area(geometry)) %>% mutate(state="nc")
pa.systems <- read_sf(paste0(swd_data, "pa_systems.geojson")) %>% mutate(systemarea = st_area(geometry)) %>% select(-owner) %>% mutate(state="pa")
tx.systems <- read_sf(paste0(swd_data, "tx_in_out_systems.geojson")) %>%   mutate(systemarea = st_area(geometry)) %>% mutate(state="tx")
or.systems <- read_sf(paste0(swd_data, "or_systems.geojson")) %>% mutate(systemarea = st_area(geometry)) %>% mutate(category = "inside", state="or") %>% select(pwsid, gis_name, category, geometry, systemarea, state)
nm.systems <- read_sf(paste0(swd_data, "nm_in_out_systems.geojson")) %>% mutate(systemarea = st_area(geometry)) %>% mutate(state="nm")
nj.systems <- read_sf(paste0(swd_data, "nj_systems.geojson")) %>% mutate(systemarea = st_area(geometry)) %>% mutate(category = "inside", state="nj") %>% select(pwsid, gis_name, category, geometry, systemarea, state); #not inside/outside because all municipal


gis.systems <- rbind(ca.systems, nc.systems, pa.systems, tx.systems, or.systems, nm.systems, nj.systems)
rm(ca.systems, nc.systems, pa.systems, tx.systems, or.systems, nm.systems, nj.systems)

#load census block group shapefiles -------------------------------------------------------------------------------------------------------------------------------------------------------------------------    
bk.group <- read_sf(paste0(swd_data, "block_groups_", selected.year,".geojson")) %>% mutate(area = st_area(geometry))
if (FALSE %in% st_is_valid(bk.group)) {bk.group <- suppressWarnings(st_buffer(bk.group[!is.na(st_is_valid(bk.group)),], 0.0)); print("fixed")}#fix corrupt shapefiles for block group... takes awhile can try to skip

  

##########################################################################################################################################################################
#
# FUNCTIONS TO DO THINGS
#
############################################################################################################################################################################
#######################################---------------------------------------------------------------------------------------------------------------------------------
# INTERSECTION FUNCTION
#######################################---------------------------------------------------------------------------------------------------------------------------------
intersect_features <- function(system, census){
  if (FALSE %in% st_is_valid(system)) {system <- suppressWarnings(st_buffer(system[!is.na(st_is_valid(system)),], 0.0)); print("fixed")}#fix corrupt shapefiles
  
  census.int <- st_intersection(system, census);
  census.int$newArea <- st_area(census.int$geometry)
  census.int$perArea <- as.numeric(round(census.int$newArea/census.int$area*100,2))
  #Keep those covering more area than the percent threshold set up top
  if(max(census.int$perArea > percent.area.threshold)){
    census.int <- subset(census.int, perArea >= percent.area.threshold); #remove areas with less than threshold coverage
  }
  
  return(census.int)
}
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
################################################################################################################################################
#
# CALCULATE AFFORDABILITY METRICS AT SERVICE LEVEL
#
################################################################################################################################################
#ESTIMATE BLOCK GROUP METRICS FOLLOWING RECOMMENDATIONS FROM AWWA 2019 REPORT
#The population-weighted average LQI can be calculated by multiplying the ratio of the population for a given geographic area to the total geographic area by the LQI upper limit 
#for the geographic area before summing these products across geographies, or using a refined approach based on census track matching to respective utility service areas. 
service_area_method <- function(block.data){
  #weight the population of each tract by the total population in the service area  and weight the income ratio based on population weighting
   weight.block.data <- block.data %>% mutate(popArea = round(totalpop * (perArea/100),4)) %>% 
     group_by(pwsid, service_area, hh_use) %>% mutate(totalPopArea = round(sum(popArea, na.rm=TRUE),2), popRatio = popArea/totalPopArea, HBIratio = HBI*popRatio, tradRatio = TRAD*popRatio) #have to group by hh_use or counts all
   foo <- weight.block.data %>% group_by(hh_use) %>% summarize(HBI = round(sum(HBIratio, na.rm=TRUE),2), TRAD = round(sum(tradRatio, na.rm=TRUE),2), .groups="drop") %>% 
     mutate(hh_use = as.numeric(as.character(hh_use))) %>% arrange(hh_use) %>% as.data.frame(); foo
    
   #weighted PPI for service area
    weight.block.data <- weight.block.data %>% ungroup() %>% distinct() %>% 
      mutate(totalPov =  round(nhhSurvey200*popRatio,0), pov200 = round(nhhPov200*popRatio,0)) %>% summarize(pov200 = sum(pov200, na.rm=TRUE), totalPov = sum(totalPov, na.rm=TRUE)) %>% 
      mutate(PPI_method1 = round(pov200/totalPov*100,2)) 
    #bind these together to return single result
    service.area.results <- foo %>% mutate(pwsid = as.character(selected.pwsid), service_area = as.character(sel.cost$service_area[1])) %>% mutate(PPI = weight.block.data$PPI_method1) %>% 
      select(pwsid, service_area, hh_use, HBI, TRAD, PPI)
    
    #LETS ALSO CALCULATE IDWS AND GET DISTRIBUTIONS READY
    #convert to percent area
    hh.per <- block.data %>% select(GEOID, hh10, hh15, hh20, hh25, hh30, hh35, hh40, hh45, hh50, hh60, hh75, hh100, hh125, hh150, hh200, hh200more, perArea, category, totalhh) %>% distinct()
    hh.per[,c(2:17)] <- round(hh.per[,c(2:17)]*(hh.per$perArea/100),2)
    #sum total number of hh in each bracket
    unique.category <- unique(hh.per$category)
    hh.total <- subset(hh.per, category==as.character(unique.category[1]))
    hh.total <- colSums(hh.total[,c(2:17)], na.rm=TRUE) %>% as.data.frame() %>% setNames(paste0("nhh_",as.character(unique.category[1]))) %>% rownames_to_column(var="names")
    
    if(length(unique.category) >=2 ){
      for (u in 2:length(unique.category)){  
        zt.total <- subset(hh.per, category==as.character(unique.category[u]))
        zt.total <- colSums(zt.total[,c(2:17)], na.rm=TRUE) %>% as.data.frame() %>% setNames(paste0("nhh_",as.character(unique.category[u]))) %>% rownames_to_column(var="names")
        zt.total <- zt.total %>% select(-names)
        
        hh.total <- cbind(hh.total, zt.total)
      }
    }
    hh.total
    
    #create dataframe
    hh.quintile <- as.data.frame(matrix(nrow=0,ncol=4));  colnames(hh.quintile) <- c("category", "nhh", "inc20", "inc50")
    dist.entire <- NA; dist.inside <- NA; dist.outside <- NA;
    #generate random numbers within a range then combine into a single list
    for (u in 1:length(unique.category)){  
      hh.total$nhh <- ceiling(hh.total[,u+1])
      hh10 <- sample(1:10000, subset(hh.total, names=="hh10")$nhh, replace=T);           hh15 <- sample(10001:15000, subset(hh.total, names=="hh15")$nhh, replace=T);
      hh20 <- sample(15001:20000, subset(hh.total, names=="hh20")$nhh, replace=T);       hh25 <- sample(20001:25000, subset(hh.total, names=="hh25")$nhh, replace=T);
      hh30 <- sample(25001:30000, subset(hh.total, names=="hh30")$nhh, replace=T);       hh35 <- sample(30001:35000, subset(hh.total, names=="hh35")$nhh, replace=T);
      hh40 <- sample(35001:40000, subset(hh.total, names=="hh40")$nhh, replace=T);       hh45 <- sample(40001:45000, subset(hh.total, names=="hh45")$nhh, replace=T);
      hh50 <- sample(45001:50000, subset(hh.total, names=="hh50")$nhh, replace=T);       hh60 <- sample(50001:60000, subset(hh.total, names=="hh60")$nhh, replace=T);
      hh75 <- sample(60001:75000, subset(hh.total, names=="hh75")$nhh, replace=T);       hh100 <- sample(75001:100000, subset(hh.total, names=="hh100")$nhh, replace=T);
      hh125 <- sample(100001:125000, subset(hh.total, names=="hh125")$nhh, replace=T);   hh150 <- sample(125001:150000, subset(hh.total, names=="hh150")$nhh, replace=T);
      hh200 <- sample(150001:200000, subset(hh.total, names=="hh200")$nhh, replace=T);   hh250 <- sample(200001:250000, subset(hh.total, names=="hh200more")$nhh, replace=T);
      dist <- c(hh10, hh15, hh20, hh25, hh30, hh35, hh40, hh45, hh50, hh60, hh75, hh100, hh125, hh150, hh200, hh250)
      
      #save out for cost_to_bill or call function here
      if(as.character(unique.category[u]=="inside")){ dist.inside = dist;}
      if(as.character(unique.category[u]=="outside")){ dist.outside = dist;}
    }
    
    #for some systems, the outside block dominates... here dist inside to dist outside
    #if (length(dist.inside) == 1 & length(dist.outside) > 1) { dist.inside = dist.outside; }
    
    #to return multiple times in a list
    newList <- list("results" = service.area.results, "dist.inside" = dist.inside, "dist.outside" = dist.outside)
    rm(weight.block.data, hh.per, hh.total, foo, hh.quintile, dist.inside, dist.outside, service.area.results)
    return(newList)
} # END FUNCTION
## ------------------------------------------------------------------------------------------------------------------------------------------------------------------------   



################################################################################################################################################
#
# VISUALIZE FUNCTIONS
#
################################################################################################################################################      
 #PLOT MAP OF WATER SYSTEM SELECTED TRACTS, SELECTED BLOCK GROUPS##########################################################################################################
    plot_system_map <- function(){
      leaflet() %>%
        addProviderTiles("Stamen.TonerLite") %>% 
        addPolygons(data = water.system,
                    fillOpacity= 0.8, fillColor = water.system$categoryCol,
                    color="black", weight=0) %>% 
        addPolygons(data = selected.bk,
                    fillOpacity= 0.0, fillColor = "red",
                    color="darkred",  weight=2, 
                    popup = paste0("GEOID: ", selected.bk$GEOID)) %>% 
        addLegend("bottomright", 
                  colors = c("darkgray", "black", "darkred"),
                  labels= c("Water System (entire or inside rates)", "Water System (outside rates)", "Selected Block Groups"),
                  title= paste0("Selected Tracts for ", sel.cost$utility_name[1]),
                  opacity = 1)
    } #end plot_system_map
################################################################################################################################################      


#plot cost to bill ##########################################################################################################
plot_cost_to_bill <- function(){
  cost.zt <- cost_to_bill %>% select(category, hh_use, percent_income, percent_pays_more) %>% filter(hh_use == 4000) %>% spread(category, percent_pays_more)
  if(sum(cost.zt$outside)==0){ cost.zt <- cost.zt %>%  select(-outside) }
  
    p <-  plot_ly(cost.zt, x=~percent_income, y = ~inside, name="inside", type="scatter", mode="lines+markers", marker = list(size=4, color="#008b8b"), line = list(color = '#008b8b', width = 3)) %>% 
        layout(margin = list(l = 50, r = 50, b = 50, t = 50, pad = 2),
           yaxis = list(title = 'Percent of households paying more than x% annual income', range=c(0,100)), 
           title = paste0(sel.cost$utility_name[1], " Annual Bill"),
           xaxis=list(title="Percent of annual income spent on water/wastewater/stormwater"),
           shapes = list(list(type = "line", y0 = 0, y1 = 100, x0 = 4.5, x1 = 4.5, line = list(color = "black", dash = 'dash', width=0.75)),
                         list(type = "line", y0 = 0, y1 = 100, x0 = 7, x1 = 7, line = list(color = "black", dash = 'dash', width=0.75)),
                         list(type = "line", y0 = 0, y1 = 100, x0 = 10, x1 = 10, line = list(color = "black", dash = 'dash', width=0.75)),
                         list(type = "line", y0 = 0, y1 = 100, x0 = 20, x1 = 20, line = list(color = "black", dash = 'dash', width=0.75))
           ),
           annotations = list(list(xref = 'x', yref = 'y', x = 4.5, y = 98, xanchor = 'left', yanchor = 'middle', text = "TRAD Threshold",  font = list(family = 'Arial', size = 14),  showarrow = FALSE),
                              list(xref = 'x', yref = 'y', x = 7.0, y = 95, xanchor = 'left', yanchor = 'middle', text = "HBI Moderate Threshold",  font = list(family = 'Arial', size = 14),  showarrow = FALSE),
                              list(xref = 'x', yref = 'y', x = 10.0, y = 92, xanchor = 'left', yanchor = 'middle', text = "HBI High Threshold",  font = list(family = 'Arial', size = 14),  showarrow = FALSE)
           ),
           legend = list(x=0.80, y=0.95)
    )
  
  if("outside" %in% colnames(cost.zt)){
    p <- p %>%  add_trace(cost.zt, y = ~outside, name="outside", type="scatter", mode="lines+markers", marker = list(size=4, color="darkred"), line = list(color = 'darkred', width = 3))
  }

  return (p)
}
################################################################################################################################################    
    
#plot burden by tract ##########################################################################################################
plot_burden_by_tract <- function(){
    block.scores <- block.data %>% select(GEOID, category, hh_use, totalpop, totalhh, medianIncome, quintile20, hhsize, HBI, PPI, burden, TRAD) %>% filter(hh_use==4000);   
    
    # Map Burden Matrix ------------------------------------------------------------------------------------------------------------------------------------------  
    block.map <- sp::merge(selected.bk[,c("GEOID", "geometry")], block.scores, by.x="GEOID", by.y="GEOID", all.x=TRUE)  
    block.map <- block.map %>% mutate(burdenCol = ifelse(burden=="Low", "#3680cd", ifelse(burden=="Low-Moderate", "#36bdcd", ifelse(burden=="Moderate-High", "#cd8536", 
                                                  ifelse(burden=="High","#ea3119", ifelse(burden=="Very High", "#71261c", "white"))))))
    block.map$burdenCol <- ifelse(is.na(block.map$burden) ==TRUE, "white", block.map$burdenCol)  ;     table(block.map$burdenCol, useNA="ifany")
    
    #make outside colors less opaque
    block.map$opacityLevel <- ifelse(block.map$category == "outside", 0.3, 0.6)
    
    leaflet() %>% addProviderTiles("Stamen.TonerLite") %>% 
      addPolygons(data = water.system,
                  fillOpacity= 0.8,  fillColor = water.system$categoryCol,
                  color="black",  weight=0) %>% 
      addPolygons(data = block.map,
                  fillOpacity= block.map$opacityLevel,  fillColor = block.map$burdenCol, #make sure matches data
                  color="black",  weight=1,
                  popup=~paste0("GEOID: ", GEOID,
                                "<br>Rate Category: ", category,
                                "<br>HBI: ", HBI,
                                "<br>PPI: ", PPI,
                                "<br>TRAD: ", TRAD,
                                "<br>Burden: ", burden)) %>% 
      addLegend("bottomright", 
                colors = c("#3680cd","#36bdcd","#cd8536","#ea3119","#71261c","white"), labels= c("Low", "Low-Moderate", "Moderate-High", "High", "Very High", "Poor Data"),
                title = paste0("Affordability Burden: ", sel.cost$city_name[1]), opacity = 1)
} #end plot_burden_by_tract()    
################################################################################################################################################   
    
    

       
#########################################################################################################################################################################################################
#
#                                                    LOOP THROUGH ALL UTILITIES AND SAVE FILE
#
#########################################################################################################################################################################################################
#state <- var.state <- "nc";
#lower list to those with rates data and with shapefile
combo <- res.rates %>% filter(state==state) %>% select(pwsid, service_area) %>% distinct()
#gis.systems <- get(paste0(state,".systems")); #dynamically calls state data
rates.pwsid <- merge(combo, gis.systems, by.x="pwsid", by.y="pwsid", all=FALSE); 
rates.pwsid <- rates.pwsid %>% select(pwsid, state) %>% distinct(); table(rates.pwsid$state)
rates.pwsid <- unique(rates.pwsid)


###########################################################################################################################
#
# IF YOU ONLY WANT TO UPDATE A PORTION OF THE DATA.... SHORTEN THE LIST
#
############################################################################################################################
ca.meta <- read_excel(paste0(swd_data, "rates_data\\rates_ca.xlsx"), sheet="rateTable") %>% mutate(state = "ca")
or.meta <- read_excel(paste0(swd_data, "rates_data\\rates_or.xlsx"), sheet="rateTable") %>% mutate(state = "or")
pa.meta <- read_excel(paste0(swd_data, "rates_data\\rates_pa.xlsx"), sheet="rateTable") %>% mutate(state = "pa")
nc.meta <- read_excel(paste0(swd_data, "rates_data\\rates_nc.xlsx"), sheet="rateTable") %>% mutate(state = "nc") %>% mutate(pwsid = paste0("NC",str_remove_all(pwsid, "[-]")))
tx.meta <- read_excel(paste0(swd_data, "rates_data\\rates_tx.xlsx"), sheet="rateTable") %>% mutate(state = "tx")
nm.meta <- read_excel(paste0(swd_data, "rates_data\\rates_nm.xlsx"), sheet="rateTable") %>% mutate(state = "nm")
nj.meta <- read_excel(paste0(swd_data, "rates_data\\rates_nj.xlsx"), sheet="rateTable") %>% mutate(state = "nj")
rates.meta <- rbind(or.meta, ca.meta, pa.meta, nc.meta, tx.meta, nm.meta, nj.meta) %>% filter(update_bill == "yes") %>% select(pwsid) %>% distinct() ; #filter is optional

rates.pwsid <- rates.meta$pwsid
update.list <- rates.pwsid
rm(ca.meta, or.meta, pa.meta, nc.meta, tx.meta, nm.meta, nj.meta)
##############################################################################################################################

#shapefile problems for the following nc: NC0161010 shapefile problem, 
rates.pwsid <- rates.pwsid[rates.pwsid != c("NC0161010")];
rates.pwsid <- rates.pwsid[rates.pwsid != c("CA3301428")];
rates.pwsid <- rates.pwsid[rates.pwsid != c("CA3010023")]; #city of Newport Beach has an empty geometry... still true June 2021

rates.pwsid <- unique(rates.pwsid)

#set up data frames
all.block.scores <- as.data.frame(matrix(nrow=0, ncol=15)); 
  colnames(all.block.scores) <- c("GEOID","pwsid", "service_area", "hh_use", "totalpop", "totalhh","perArea", "hhsize", "medianIncome", "income20", "HBI","PPI","burden","TRAD", "hhbelow45")
all.service.scores <- as.data.frame(matrix(nrow=0, ncol=9)); colnames(all.service.scores) = c("pwsid","service_area", "hh_use","HBI", "PPI","TRAD", "LaborHrsMin","LaborHrsMax","burden")
all.cost.to.bill <- as.data.frame(matrix(nrow=0, ncol=8));    colnames(all.cost.to.bill) <- c("pwsid", "service_area", "category", "hh_use","percent_income", "annual_cost", "annual_income", "percent_pays_more")

#set hbi levels for burden
hbi_mod = 4.6; #4.6% is ~ 1 day of work. AWWA recommended 7%. EPA is considering lower.
hbi_high = hbi_mod*2; #AWWA recommended 10%

for (i in 1:length(rates.pwsid)){
#for (i in 501:700){
  #select utility
  selected.pwsid = as.character(rates.pwsid[i]);
  
  #get estimated bill
  sel.cost <- res.rates %>% filter(pwsid == as.character(selected.pwsid))
  
  #Calculate an annual household bill - total bill (adds stormwater to water and wastewater (which is current total))
  annual.hh.cost <- sel.cost %>% filter(service != "total") %>% group_by(pwsid, service_area, category, hh_use) %>% summarize(annual_cost = sum(total, na.rm=TRUE)*12, .groups="drop")
    #zt <- annual.hh.cost %>% filter(category=="inside")
    #plot_ly(zt, x= ~hh_use, y= ~annual_cost/12, name = "", type='scatter', mode = 'lines+markers', marker = list(size=4, color="rgb(0,0,0,0.8)"), line = list(color = 'black', width = 1)) %>% 
    #  layout(margin = list(l = 50, r = 50, b = 50, t = 50, pad = 2), yaxis = list(title = 'Monthly Bill ($)', range=c(0,400)),  xaxis=list(title="Volume of Water (gallons)"))

########################################
  #clip census data to selected pwsid ---------------------------------------------------------------------------------------------------
  water.system <- gis.systems %>% filter(pwsid==selected.pwsid) %>% mutate(categoryCol = ifelse(category=="outside", "black", "#5a5a5a"))
  
  #if no shapefile then skip. If no geometry then skip
  if (dim(water.system)[1] == 0){
    print(paste0("No shapefile for ", selected.pwsid));
    next
  }
  
  if(is.na(st_dimension(water.system))){
    print(paste0("No geometry in shapefile for ", selected.pwsid));
    next  
  }

  #run intersection function-
  bk.int <- intersect_features(water.system, bk.group); #double counts if inside/outside - weight later
  selected.bk <- bk.group[bk.group$GEOID %in% bk.int$GEOID,]  #grabs anything that intersects
  #plot_system_map();
  #for very small systems with inside and outside rates (but no muni) - set to inside rates
  if(dim(subset(bk.int, category == "inside"))[1] == 0 & dim(subset(bk.int, category == "outside"))[1] > 0){
    bk.int <- bk.int %>% mutate(category = "inside");
  }
  
    #grab census data and calculate metrics ----------------------------------------------------------------------------------------------------
  block.data <- block.group.all %>% filter(GEOID %in% selected.bk$GEOID)
  block.data <- merge(block.data, bk.int[,c("GEOID","perArea")], by.x="GEOID", by.y="GEOID", all.x=TRUE) %>% mutate(geometry = NA) %>% distinct()
  
  #method recommends excluding those census tracts with a large margin of error
  block.data <- block.data %>% mutate(perError = ifelse(estimate==0, 0, round(moe/estimate*100,2))) %>% mutate(keepEst=ifelse(perError <= moe.threshold, estimate, NA))
  
  #reshape dataframe
  block.data <- block.data %>% select(GEOID, variable, perArea, keepEst) %>% spread(variable, keepEst) %>% as.data.frame(); #reshape the dataset
    colnames(block.data) <- c("GEOID", "perArea", "totalpop", "totalhh", "hh10","hh15","hh20","hh25","hh30","hh35","hh40","hh45","hh50","hh60","hh75","hh100","hh125","hh150","hh200","hh200more","medianIncome")
  
  #calculate hh size - to look for odd blocks (universities, airports, prisons, etc)
  block.data <- block.data %>% mutate(hhsize = ifelse(totalhh>0, round(totalpop/totalhh,2), NA)) %>% mutate(hhsize = ifelse(hhsize > 8, NA, hhsize), tractID = substr(GEOID, 0, 11))
  
  #For this method... lots of high percent error. Need to keep all to do calculate
  block.data$quintile20 = NA;    block.data$quintile50 = NA;   # block.data$nhhFed200 = NA

  #estimate 20th quintile
  for (j in 1:dim(block.data)[1]){
    #generate random numbers within a range then combine into a single list
    hh.total <- block.data[j,];
    #if estimate is NA - set to zero;
    hh.total[is.na(hh.total)] <- 0
    
    hh10 <- sample(1:10000, hh.total$hh10, replace=T);           hh15 <- sample(10001:15000, hh.total$hh15, replace=T);    hh20 <- sample(15001:20000, hh.total$hh20, replace=T);
    hh25 <- sample(20001:25000, hh.total$hh25, replace=T);       hh30 <- sample(25001:30000, hh.total$hh30, replace=T);    hh35 <- sample(30001:35000, hh.total$hh35, replace=T);
    hh40 <- sample(35001:40000, hh.total$hh40, replace=T);       hh45 <- sample(40001:45000, hh.total$hh45, replace=T);    hh50 <- sample(45001:50000, hh.total$hh50, replace=T);       
    hh60 <- sample(50001:60000, hh.total$hh60, replace=T);       hh75 <- sample(60001:75000, hh.total$hh75, replace=T);    hh100 <- sample(75001:100000, hh.total$hh100, replace=T);
    hh125 <- sample(100001:125000, hh.total$hh125, replace=T);   hh150 <- sample(125001:150000, hh.total$hh150, replace=T);
    hh200 <- sample(150001:200000, hh.total$hh200, replace=T);   hh250 <- sample(200001:250000, hh.total$hh200more, replace=T);
    dist <- c(hh10, hh15, hh20, hh25, hh30, hh35, hh40, hh45, hh50, hh60, hh75, hh100, hh125, hh150, hh200, hh250)
    
    block.data$quintile20[j] <- round(as.numeric(quantile(dist, 0.20)),0);    
    block.data$quintile50[j] <- round(as.numeric(quantile(dist, 0.50)),0);    
  }                                     
  
  #merge in the PPI value from tract data
  block.data <- merge(block.data, tract.data[,c("tractID", "nhhSurvey200", "nhhPov200", "PPI")], by.x="tractID", by.y="tractID", all.x=TRUE)
  block.data  <- block.data %>% mutate(medianIncome = ifelse(is.na(medianIncome)==TRUE, quintile50, medianIncome))
  #head(block.data)  
  
  #Calculate metrics  #add service area calculation back in
  block.data <- merge(block.data, bk.int[,c("GEOID","category","perArea")], by.x=c("GEOID","perArea"), by.y=c("GEOID","perArea"), all.x=TRUE)
  all.cost <- annual.hh.cost %>% mutate(hh_use = paste0("vol_", hh_use)) %>% pivot_wider(names_from = hh_use, values_from = annual_cost)
  block.data <- merge(block.data, all.cost, by.x=c("category"), by.y=c("category"), all.x=TRUE)
  
  #reshape back to long
  block.data <- block.data %>% pivot_longer(cols = starts_with("vol"),  names_to = "hh_use", names_prefix = "vol", values_to = "annual_cost", values_drop_na = FALSE) %>% mutate(hh_use = substr(hh_use, 2, nchar(hh_use)))
  
  #calculate metrics
  block.data <- block.data %>% mutate(HBI = ifelse(is.na(hhsize)==TRUE, NA, round(annual_cost/quintile20*100,2)), 
                                      TRAD = ifelse(is.na(hhsize)==TRUE, NA, round(annual_cost/medianIncome*100,2))) %>% #Traditional has lots of missing values for median
    mutate(burden = ifelse(PPI >= 35 & HBI >= hbi_high, "Very High", ifelse(PPI >=35 & HBI < hbi_high & HBI >= hbi_mod, "High", ifelse(PPI >= 35 & HBI < hbi_mod, "Moderate-High", 
                                               ifelse(PPI >= 20 & PPI < 35 & HBI >= hbi_high, "High", ifelse(PPI >=20 & PPI < 35 & HBI >= hbi_mod & HBI < hbi_high, "Moderate-High", ifelse(PPI >=20 & PPI < 35 & HBI < hbi_mod, "Low-Moderate", 
                                               ifelse(PPI < 20 & HBI >= hbi_high, "Moderate-High", ifelse(PPI < 20 & HBI >= hbi_mod & HBI < hbi_high, "Low-Moderate", ifelse(PPI < 20 & HBI < hbi_mod, "Low", "Unknown")))))))))) %>% 
    mutate(burden = ifelse(is.na(burden)==TRUE, "unknown", burden))
  #table(block.data$hh_use, block.data$burden, useNA="ifany")
  #  plot_burden_by_tract();  


################################################################################################################################################
#Calculate service area metrics - call functions
list.results <- service_area_method(block.data);
  service.area.results <- list.results$results; summary(service.area.results)
  dist.inside <- list.results$dist.inside;  dist.outside <- list.results$dist.outside
 rm(list.results) 

 #calculate labor hrs
 state.var <- tolower(substr(service.area.results$pwsid[1],0,2))
 service.area.results <- service.area.results %>% mutate(min_wage = subset(min.wage, year==selected.year & state == state.var)$all.wage)
 wage.cost <- annual.hh.cost %>% spread(category, annual_cost) %>% select(hh_use, inside, outside) %>% mutate(outside = ifelse(outside==0, inside, outside)) %>% 
   mutate(cheap = ifelse(inside <= outside, inside, outside), expense = ifelse(inside <= outside, outside, inside)) %>% select(hh_use, cheap, expense)
 
 service.area.results <- merge(service.area.results, wage.cost, by.x="hh_use", by.y="hh_use", all.x=TRUE)
 service.area.results <- service.area.results %>% mutate(LaborHrsMin = round(cheap/12/min_wage,2), LaborHrsMax = round(expense/12/min_wage,2)) %>% select(-cheap, -expense, -min_wage)
 
 
 #calculate the cost to bill----------------------------------------------------------------------------------------------------------------------------------------------------------
 rep.per.cost <- length(unique(annual.hh.cost$hh_use))*length(unique(annual.hh.cost$category))
 cost_to_bill <- bind_rows(replicate(21, annual.hh.cost, simplify = FALSE))
 cost_to_bill <- cost_to_bill %>% mutate(percent_income = c(rep(0,rep.per.cost), rep(1,rep.per.cost), rep(2, rep.per.cost), rep(3, rep.per.cost), rep(4, rep.per.cost), rep(5, rep.per.cost),
                                                             rep(6, rep.per.cost), rep(7, rep.per.cost), rep(8, rep.per.cost), rep(9, rep.per.cost), rep(10, rep.per.cost), rep(11, rep.per.cost),
                                                             rep(12, rep.per.cost), rep(13, rep.per.cost), rep(14, rep.per.cost), rep(15, rep.per.cost), rep(16, rep.per.cost), rep(17, rep.per.cost),
                                                             rep(18, rep.per.cost), rep(19, rep.per.cost), rep(20, rep.per.cost)))
 cost_to_bill <- cost_to_bill %>% mutate(annual_income = round(annual_cost/(percent_income/100),0)) %>% mutate(annual_income = ifelse(percent_income==0, annual_cost/0.001, annual_income),
                                                                                                               percent_pays_more = NA);
                                                                           
  for (k in 1:dim(cost_to_bill)[1]){
    foo.zt <- cost_to_bill[k,]   
      #select correct dist  
      if(as.character(foo.zt$category=="inside")){ foo = dist.inside; zt.length = length(dist.inside); }
      if(as.character(foo.zt$category=="outside")){ foo = dist.outside; zt.length = length(dist.outside); }

    zt <- foo %>% as.data.frame() %>% filter(. <= foo.zt$annual_income);
    cost_to_bill$percent_pays_more[k] <- round(dim(zt)[1]/zt.length*100,2);
    
  }#end category loop
    head(cost_to_bill) %>% as.data.frame();
#  plot_cost_to_bill();
  

#############################################################################################################################################################################################################################################
#
#   #FILL DATA FRAMES TO SAVE OUT OF LOOP
#
#############################################################################################################################################################################################################################################
#Block Scores Table
    #Calculate a single score for each block
    block.scores <- block.data %>% mutate(popArea = round(totalpop * (perArea/100),2)) %>% group_by(GEOID, pwsid, service_area, hh_use) %>% 
      mutate(totalPopArea = round(sum(popArea, na.rm=TRUE),0), popRatio = popArea/totalPopArea, HBIratio = HBI*popRatio, tradRatio = TRAD*popRatio) %>% ungroup()
    block.scores <- block.scores %>%  group_by(pwsid, GEOID, service_area, hh_use, totalpop, totalhh, hhsize, medianIncome, PPI) %>% 
      summarize(HBI = round(sum(HBIratio, na.rm=TRUE),2), TRAD = round(sum(tradRatio, na.rm=TRUE),2), perArea = sum(perArea, na.rm=TRUE), income20 = round(mean(quintile20, na.rm=TRUE),0), .groups="drop") %>% 
      mutate(hh_use = as.numeric(as.character(hh_use))) %>% arrange(hh_use)

    #reset NAs to zero if needed
    block.scores <- block.scores %>% mutate(HBI = ifelse(HBI==0, NA, HBI), PPI = ifelse(PPI==0, NA, PPI), TRAD = ifelse(TRAD==0, NA, TRAD), perArea = ifelse(perArea>100, 100, perArea))
    block.scores <- block.scores %>% mutate(burden = ifelse(PPI >= 35 & HBI >= hbi_high, "Very High", ifelse(PPI >=35 & HBI < hbi_high & HBI >= hbi_mod, "High", ifelse(PPI >= 35 & HBI < hbi_mod, "Moderate-High", 
                                                    ifelse(PPI >= 20 & PPI < 35 & HBI >= hbi_high, "High", ifelse(PPI >=20 & PPI < 35 & HBI >= hbi_mod & HBI < hbi_high, "Moderate-High", ifelse(PPI >=20 & PPI < 35 & HBI < hbi_mod, "Low-Moderate", 
                                                    ifelse(PPI < 20 & HBI >= hbi_high, "Moderate-High", ifelse(PPI < 20 & HBI >= hbi_mod & HBI < hbi_high, "Low-Moderate", ifelse(PPI < 20 & HBI < hbi_mod, "Low", "Unknown"))))))))))
    block.scores <- block.scores %>% mutate(burden = ifelse(is.na(burden)==TRUE, "unknown", burden)) %>% 
      select(GEOID, pwsid, service_area, hh_use, totalpop, totalhh, perArea, hhsize, medianIncome, income20, HBI, PPI, burden, TRAD)
    all.block.scores <- rbind(all.block.scores, block.scores)
    
#Service Scores
    service.area.results <- service.area.results %>% select(pwsid, service_area, hh_use, HBI, PPI, TRAD, LaborHrsMin, LaborHrsMax) %>% arrange(as.numeric(as.character(hh_use))) %>% 
      mutate(burden = ifelse(PPI >= 35 & HBI >= hbi_high, "Very High", ifelse(PPI >=35 & HBI < hbi_high & HBI >= hbi_mod, "High", ifelse(PPI >= 35 & HBI < hbi_mod, "Moderate-High", ifelse(PPI >= 20 & PPI < 35 & HBI >= hbi_high, "High", 
                       ifelse(PPI >=20 & PPI < 35 & HBI >= hbi_mod & HBI < hbi_high, "Moderate-High", ifelse(PPI >=20 & PPI < 35 & HBI < hbi_mod, "Low-Moderate",  ifelse(PPI < 20 & HBI >= hbi_high, "Moderate-High", 
                       ifelse(PPI < 20 & HBI >= hbi_mod & HBI < hbi_high, "Low-Moderate", ifelse(PPI < 20 & HBI < hbi_mod, "Low", "Unknown")))))))))) %>% mutate(burden = ifelse(is.na(burden)==TRUE, "Unknown", burden))
    all.service.scores <- rbind(all.service.scores, service.area.results)
#cost to bill Scores
    all.cost.to.bill <- rbind(all.cost.to.bill, cost_to_bill)
    
    print(paste0(i, ": ", sel.cost$service_area[1], ", ", substr(sel.cost$pwsid[1],0,2)))
} #end master loop    

bk.up1 <- all.service.scores;   bk.up2 <- all.block.scores; bk.up3 <- all.cost.to.bill

summary(all.service.scores);  #summary(all.cost.to.bill);
table(as.numeric(as.character(all.service.scores$hh_use)), all.service.scores$burden, useNA="ifany");

#NC2036024 Dallas NC ... suburb section? has a problem with rates or no rates data --> remove for now
#all.service.scores %>% filter(pwsid=="NC2036024")
all.service.scores <- all.service.scores %>% filter(pwsid != "NC2036024")
all.block.scores <- all.block.scores %>% filter(pwsid != "NC2036024")

#for block scores where incomes are NA - set HBI to NA  and burden to NA
summary(all.block.scores); 
all.block.scores <- all.block.scores %>% mutate(HBI = ifelse(is.infinite(HBI), NA, HBI), TRAD = ifelse(is.infinite(TRAD), NA, TRAD))
table(as.numeric(as.character(all.block.scores$hh_use)), all.block.scores$burden, useNA="ifany");


#NOW IF WE WANT TO ONLY UPDATE OR ADD NEW FILES - DO THE FOLLOWING...#####################################################################################################################################
#spread resrates data (do outside of loop)
rates.table <- res.rates %>% mutate(variable_cost = vol_cost + zone_cost, surcharge_cost = vol_surcharge + zone_surcharge + fixed_surcharge) %>% filter(service != "total") %>% 
  pivot_wider(id_cols = c("pwsid", "service_area", "category", "hh_use"), names_from = service, values_from = c("base_cost", "variable_cost", "surcharge_cost", "total"))
rates.table <- rates.table %>% mutate(percent_fixed_sewer = round(base_cost_sewer/total_sewer*100,2), percent_fixed_water = round(base_cost_water/total_water*100,2),
                                      percent_variable_sewer = round(variable_cost_sewer/total_sewer*100,2), percent_variable_water = round(variable_cost_water/total_water*100,2),
                                      percent_surcharge_sewer = round(surcharge_cost_sewer/total_sewer*100, 2), percent_surcharge_water = round(surcharge_cost_water/total_water*100,2))
rates.table[is.na(rates.table)] <- 0; #set rates that are NA to zero

#Read in the full table. Remove those with pwsid in this list. Add new rates here.
if(exists("update.list")){
  orig.scores <- read.csv(paste0(swd_results,"utility_service_scores_",selected.year,".csv")) %>% filter(pwsid %notin% rates.pwsid)
  orig.blocks <- read.csv(paste0(swd_results,"utility_block_scores_",selected.year,".csv")) %>% filter(pwsid %notin% rates.pwsid)
  orig.cost.bill <- read.csv(paste0(swd_results,"utility_idws.csv")) %>% filter(pwsid %notin% rates.pwsid)
  
  orig.scores <- rbind(orig.scores, all.service.scores)
  orig.blocks <- rbind(orig.blocks, all.block.scores)
  orig.cost.bill <- rbind(orig.cost.bill, all.cost.to.bill)
  
  rates.table <- rates.table %>% filter(pwsid %in% orig.scores$pwsid)
  write.csv(rates.table,  paste0(swd_results, "utility_rates_table.csv"), row.names=FALSE)
  
  write.csv(orig.scores, paste0(swd_results,"utility_service_scores_",selected.year,".csv"), row.names=FALSE)
  write.csv(orig.blocks,  paste0(swd_results,"utility_block_scores_", selected.year, ".csv"), row.names=FALSE)
  write.csv(orig.cost.bill,  paste0(swd_results, "utility_idws.csv"), row.names=FALSE)
} else {
  #SAVE OUT FILES
  #Write These out##################################################
  write.csv(all.service.scores, paste0(swd_results,"utility_service_scores_",selected.year,".csv"), row.names=FALSE)
  write.csv(all.block.scores,  paste0(swd_results,"utility_block_scores_", selected.year, ".csv"), row.names=FALSE)
  write.csv(all.cost.to.bill,  paste0(swd_results, "utility_idws.csv"), row.names=FALSE)
  
  rates.table <- rates.table %>% filter(pwsid %in% all.service.scores$pwsid)
  write.csv(rates.table,  paste0(swd_results, "utility_rates_table.csv"), row.names=FALSE)
}

rm(rates.meta, rates.table, sel.cost, selected.bk, orig.cost.bill, orig.scores, orig.blocks, all.service.scores, all.block.scores, all.cost.to.bill, gis.systems, hh.total, min.wage)
rm(dist, dist.inside, dist.outside, hh10, hh100, hh125, foo, service.area.results, tract.data, wage.cost, water.system, block.scores, combo, res.rates, gis.systems, bk.group, bk.int)
rm(all.cost, annual.hh.cost, block.data, block.group.all, cost_to_bill, foo.zt, zt, hh15, hh150, hh20, hh200, hh25, hh250, hh30, hh35, hh40, hh45,hh50, hh60, hh75, moe.threshold, i, j, k, percent.area.threshold)
rm(update.list, hh75, rates.pwsid, rep.per.cost, selected.pwsid, state.var)
rm(bk.up1, bk.up2, bk.up3)
