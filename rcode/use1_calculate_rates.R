#######################################################################################################################################################
#
#  This script estimates the bills households will pay for different volumes of water use by service type (drinking water, wastewater, or stormwater),
#  and based on inside and outside rates. The mean bill is calculated for all other spatially distinct rates within a service area
#  Created by Lauren Patterson, 2021
#
########################################################################################################################################################



######################################################################################################################################################################
#
#   Load data and set variables
#
######################################################################################################################################################################
#set variables for stormwater calculations
res.ft <- 2500; #will replace if vol_base is present... otherwise assume residential household size is 2500 for stormwater
res.bedrooms = 2; #again, this variable can be changed
res.person = 3;
tax.based = 200000; #assume property value = 200000
percent.impervious = 50; #assume half of lot is impervious


#read in rates
rates <- read_excel(paste0(swd_data, "rates_data\\rates_", state.list[1], ".xlsx"), sheet="rateTable") %>% mutate(state = state.list[1])
for (i in 2:length(state.list)){
  zt <- read_excel(paste0(swd_data, "rates_data\\rates_", state.list[i], ".xlsx"), sheet="rateTable") %>% mutate(state = state.list[i])
  
  if (state.list[i] == "nc"){
    zt <- zt %>% mutate(pwsid = paste0("NC",str_remove_all(pwsid, "[-]"))) %>% 
           filter(rate_type != "drought_surcharge" & rate_type != "drought_mandatory_surcharge" & rate_type != "drought_voluntary_surcharge" & rate_type != "conservation_surcharge") %>% 
           filter(nchar(pwsid) == 9) %>% filter(pwsid != "NC Aqua NC") %>% filter(pwsid != "NCBayboro")
  }
  rates <- rbind(rates, zt);
  rm(zt)
}
table(rates$state); #check to make sure have data
res.rates <- rates; #do this if you want to update all data OR

#Only calculate for those that have been updated--------------------------------------------------------------------------------------
update.list <- rates %>% filter(update_bill != "no") %>% select(pwsid) %>% distinct()
#always add this pwsid to have an outside rates
keep.pwsid <- as.data.frame(c("NC0363020","NC0136035", "NC0190010")); colnames(keep.pwsid) <- "pwsid"
update.list <- rbind(update.list, keep.pwsid) %>% unique()
table(substr(update.list$pwsid,0,2))
res.rates <- rates %>% filter(pwsid %in% update.list$pwsid)
#------------------------------------------------------------------------------------------------------------------------------------

res.rates <- res.rates %>% mutate_at(c("meter_size", 'value_from', 'value_to', "vol_base", "cost"), as.numeric); #convert to numeric
#data check
table(res.rates$bill_frequency, useNA="ifany");    
#res.rates <- res.rates %>% mutate(rate_type = tolower(rate_type))
table(res.rates$rate_type, useNA="ifany"); #chck for commodity_charge misspellings and service_charge misspellings... also make sure all others have a "surcharge"
table(res.rates$vol_unit)

#Keep only most recent rate years 
res.rates <- res.rates %>% mutate(class_category = ifelse(class_category=="NA", "inside", class_category)) %>% mutate(service = sub("\\_.*","", rate_code))
#at this point this only changes "sewer_septic" to sewer... if want to distinguish or omit in future versions - do so here.
#res.rates <- res.rates %>% mutate(class_category = ifelse(class_category != "outside", "inside", "outside")); #to early to do for averaging... need to do after average and before sum.
res.rates <- res.rates %>% group_by(pwsid, service_area, city_name, utility_name, service) %>%  filter(effective_date == max(effective_date)) %>% as.data.frame()


#remove stormwater and add back later if desire
storm.rates <- res.rates %>% filter(service == "stormwater") %>% rename(category = class_category)
res.rates <- res.rates %>% filter(service != "stormwater") %>% rename(category = class_category)


######################################################################################################################################################################
#
#   CALCULATE RATES
#
######################################################################################################################################################################
#For this version we will eventually summarize the costs. IMPORTANT TO DO SUMMARY BY UTILITY_NAME AND CITY ANT END
#calculate base or minimum charge----------------------------------------------
fixed.charge <- res.rates %>% filter(volumetric =="no") %>% group_by(pwsid, service_area, city_name, utility_name, rate_type, service, bill_frequency, category)  %>%
  mutate(month_base_cost = ifelse(bill_frequency == "quarterly", round(cost/3,2),  ifelse(bill_frequency == "bi-monthly", round(cost/2, 2), 
                                  ifelse(bill_frequency == "semi-annually", round(cost/6, 2), ifelse(bill_frequency=="annually", round(cost/12,2), cost)))))

#rename those that are not inside outside to be inside only;
fixed.charge <- fixed.charge %>% mutate(category = ifelse(category != "outside", "inside", "outside"))

#summarize by multiple types of categories
fixed.charge <- fixed.charge %>% group_by(pwsid, service_area, city_name, rate_type, service, category) %>% summarise(base_cost = round(mean(month_base_cost, na.rm=TRUE),2), .groups = "drop") %>% as.data.frame()

fixed.charge <- fixed.charge %>% mutate(rate_type = ifelse(rate_type=="service_charge", "service", "surcharge"))
#summarize by multiple types of surcharges
fixed.charge <- fixed.charge %>% group_by(pwsid, service_area, city_name, rate_type, service, category) %>% summarise(base_cost = round(sum(base_cost, na.rm=TRUE),2), .groups = "drop") %>% as.data.frame()

table(fixed.charge$service, fixed.charge$category)

#for those that had inside / outside rates for one service, apply the inside rate to the outside for the missing service... assumption that service is applied outside
fx <- fixed.charge%>% pivot_wider(id_cols = c("pwsid", "service_area", "city_name", "rate_type"), names_from = c("service", "category"), values_from = base_cost)
#fix if inside rates but not outside rates... not vice versa for NC because shapefile set to outside if only outside
fx <- fx %>% mutate(sewer_outside = ifelse(is.na(water_outside)==FALSE & is.na(sewer_outside)==TRUE, sewer_inside, sewer_outside), 
                    water_outside = ifelse(is.na(water_outside)==TRUE & is.na(sewer_outside)==FALSE, water_inside, water_outside))
#recombine
fx2 <- fx %>%  gather(var, base_cost, -c("pwsid", "service_area", "city_name", "rate_type")) %>% mutate(service = substr(var, 0, 5), category = substr(var, 7, nchar(var)))  %>% select(-var)

#divide service and surcharge into separate columns
service.only <- fx2 %>% filter(rate_type == "service") %>% select(-rate_type)
flat.surcharge <- fx2 %>% filter(rate_type == "surcharge") %>% select(-rate_type) %>% rename(fixed_surcharge = base_cost)
fixed.charge <- merge(service.only, flat.surcharge, by.x=c("pwsid", "service_area", "city_name", "service", "category"), by.y=c("pwsid","service_area","city_name", "service", "category"), all=TRUE)
summary(fixed.charge); #check values for obvious data entry errors


#####################################################################################################################################

#Calculate the volumetric charge---------------------------------------------------------------------------------------------------------------------------------------
gal.month <- c(0, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000, 11000, 12000, 13000, 14000, 15000, 16000)
#calculate volumetric charges ---------------------------------------------------------------------------------------------------------------------------------------
ws.volume <- res.rates %>% filter(volumetric=="yes") #%>%  mutate(rate_type = ifelse(rate_type=="commodity_charge_tier" | rate_type=="commodity_charge_flat", "commodity", "surcharge")) 
#convert everything to mgal
ws.volume <- ws.volume %>% mutate(value_from = ifelse(vol_unit=="gallons", value_from, value_from*7.48052), value_to = ifelse(vol_unit=="gallons", value_to, value_to*7.48052),
                                  vol_base = ifelse(vol_unit=="gallons", vol_base, vol_base*7.48052)) %>% as.data.frame()

#unique pwsid - pull all of them for merging later
unique.pwsid <- unique(res.rates$pwsid) #build in pwsid for those without commodity charge
#create dataframe for tiers
volume <- as.data.frame(matrix(nrow=0, ncol=9)); colnames(volume) <- c("pwsid","service_area","city_name","service","rate_type","hh_use","category", "unit_price", "vol_cost")
for(i in 1:length(unique.pwsid)){
#for(i in 1:400){
  zt <- subset(ws.volume, pwsid==as.character(unique.pwsid[i]));
  zt2 = NA;
  zt3 = NA;
  #how many values should there be?
  nval = res.rates %>% filter(pwsid==as.character(unique.pwsid[i])) %>% select(pwsid, service_area, city_name) %>% distinct()
  nval = dim(nval)[1]

  for (j in 1:length(gal.month)){
    if(dim(zt)[1]>0){
      zt$hh_use <- gal.month[j];
      #adjust for bill frequency
      zt2 <- zt %>% mutate(hh_use_adj = hh_use * adjustment) %>% mutate(value_from = ifelse(bill_frequency == "quarterly", value_from/3, ifelse(bill_frequency == "bi-monthly", value_from/2, 
                                                                                   ifelse(bill_frequency == "semi-annually", value_from/6, ifelse(bill_frequency=="annually", value_from/12, value_from))))) %>% 
              mutate(value_to = ifelse(bill_frequency == "quarterly", value_to/3, ifelse(bill_frequency == "bi-monthly", value_to/2,ifelse(bill_frequency == "semi-annually", value_to/6, 
                                                                                                                                     ifelse(bill_frequency=="annually", value_to/12, value_to)))))
      #subset to appropriate tier and calcualte cost
      zt2 <- zt2 %>% filter(value_from <= hh_use_adj) %>% mutate(vol_cost = ifelse(value_to <= hh_use_adj, round((value_to - value_from)*cost/vol_base,2), round((hh_use_adj - value_from)*cost/vol_base, 2)))
      #for those with the same class but multiple categories
      zt2 <- zt2 %>%  group_by(pwsid, service_area, city_name, utility_name, service, bill_frequency, category, rate_type, hh_use) %>% 
        summarize(vol_cost = sum(vol_cost, na.rm=TRUE), .groups="drop")
      
      #now mutate to inside outside category only for adding
      zt2 = zt2 %>% mutate(category = ifelse(category != "outside", "inside", "outside"))
      
      #summarize tiers into a single cost
      zt2 <- zt2 %>% group_by(pwsid, service_area, city_name, service, bill_frequency, category, rate_type, hh_use) %>% summarize(vol_cost = mean(vol_cost, na.rm=TRUE), .groups="drop")
      
      #zt2 <- zt2 %>% mutate(category = ifelse(category != "outside", "inside", "outside"))
      zt2 <- zt2 %>% select(pwsid, service_area, city_name, rate_type, service, category, hh_use, vol_cost) %>% group_by(pwsid, service_area, city_name, rate_type, service, category, hh_use) %>% 
        summarize(vol_cost=round(mean(vol_cost, na.rm=TRUE),2), .groups="drop") %>% mutate(unit_price = round(vol_cost/hh_use*1000,2))
      
      #sumarize by adding cost
      zt2 <- zt2 %>% mutate(rate_type = ifelse(rate_type=="commodity_charge_tier" | rate_type=="commodity_charge_flat", "commodity", "surcharge")) 
      zt2 <- zt2 %>% select(pwsid, service_area, city_name, rate_type, service, category, hh_use, vol_cost) %>% group_by(pwsid, service_area, city_name, rate_type, service, category, hh_use) %>% 
        summarize(vol_cost=round(sum(vol_cost, na.rm=TRUE),2), .groups="drop") %>% mutate(unit_price = round(vol_cost/hh_use*1000,2))
      
      #if have only one service
      if (length(unique(zt2$service)) == 1){
        miss_serv = NA
        if(zt2$service == "water") { miss_serv = "sewer" }
        if(zt2$service == "sewer") { miss_serv = "water" }
        zt3 <- zt2 %>% select(pwsid, service_area, city_name, rate_type, service, category, hh_use) %>% distinct() %>% mutate(vol_cost = 0, unit_price=0, service = miss_serv)
        zt2 <- rbind(zt2, zt3)
      }
      
      #if missing a city or if only volume charge partially still need to create parts of the dataframe
      if (length(unique(zt2$city_name)) < nval){
        zt4 <- res.rates %>% filter(pwsid==as.character(unique.pwsid[i])) %>% select(pwsid, service_area, city_name) %>% distinct()
        #if missing a city, create two values for each service
        if(length(unique(zt2$city_name)) < length(unique(zt4$city_name))){
          zt3 <- zt4 %>% filter(city_name %notin% zt2$city_name) %>% mutate(rate_type = "commodity", service = "water", category = "inside", hh_use = gal.month[j], vol_cost=0, unit_price=0)
          zt5 <- zt3 %>% mutate(service = "sewer");
          zt2 <- rbind(zt2, zt3, zt5)
        }
      }

    }# end if volumetric
    
    #if not volumetric
    if(dim(zt)[1] == 0){
      zt3 <- subset(res.rates, pwsid==as.character(unique.pwsid[i])) %>% mutate(rate_type = "commodity") %>% mutate(category = ifelse(category != "outside", "inside", "outside")) %>%  select(pwsid, service_area, city_name, rate_type, service, category) %>% distinct()
      zt2 <- zt3 %>% mutate(hh_use = gal.month[j], vol_cost = 0, unit_price = 0)
    }
    
    volume <- rbind(volume, zt2)
  }
  print(paste0(i, ": ", unique.pwsid[i]));
}
summary(volume);  #check for data entry errors
bk.up <- volume;
#foo <- (table(volume$pwsid))
volume <- volume %>% distinct()
table(volume$hh_use) #check for data entry errors

table(volume$service, volume$category) #check for data entry errors
#for those that had inside / outside rates for one service, apply the inside rate to the outside for the missing service... assumption that service is applied outside
fx <- volume %>% select(-unit_price) %>%   pivot_wider(id_cols = c("pwsid", "service_area", "city_name", "rate_type","hh_use"), names_from = c("service", "category"), values_from = vol_cost)
#fix if inside rates but not outside rates... not vice versa for NC because shapefile set to outside if only outside
  if("water_outside" %in% colnames(fx)){}else{fx$water_outside = NA; }
  if("sewer_outside" %in% colnames(fx)){}else{fx$sewer_outside = NA; }
fx <- fx %>% mutate(sewer_outside = ifelse(is.na(water_outside)==FALSE & is.na(sewer_outside)==TRUE & is.na(sewer_inside)==FALSE, sewer_inside, sewer_outside), 
                    water_outside = ifelse(is.na(water_outside)==TRUE & is.na(sewer_outside)==FALSE & is.na(water_inside)==FALSE, water_inside, water_outside))

fx3 <- volume %>% pivot_wider(id_cols = c("pwsid", "service_area", "city_name", "rate_type","hh_use"), names_from = c("service", "category"), values_from = unit_price)
  if("water_outside" %in% colnames(fx3)){}else{fx3$water_outside = NA; }
  if("sewer_outside" %in% colnames(fx3)){}else{fx3$sewer_outside = NA; }
#fix if inside rates but not outside rates... not vice versa for NC because shapefile set to outside if only outside
fx3 <- fx3 %>% mutate(sewer_outside = ifelse(is.na(water_outside)==FALSE & is.na(sewer_outside)==TRUE & is.na(sewer_inside)==FALSE, sewer_inside, sewer_outside), 
                    water_outside = ifelse(is.na(water_outside)==TRUE & is.na(sewer_outside)==FALSE & is.na(water_inside)==FALSE, water_inside, water_outside))

#recombine
fx2 <- fx %>%  gather(var, vol_cost, -c("pwsid", "service_area", "city_name", "rate_type", "hh_use")) %>% mutate(service = substr(var, 0, 5), category = substr(var, 7, nchar(var)))  %>% select(-var)
fx3 <- fx3 %>%  gather(var, unit_price, -c("pwsid", "service_area", "city_name", "rate_type", "hh_use")) %>% mutate(service = substr(var, 0, 5), category = substr(var, 7, nchar(var)))  %>% select(-var)

fx2 <- merge(fx2, fx3, by.x=c("pwsid", "service_area", "city_name", "rate_type", "hh_use", "service", "category"), by.y=c("pwsid", "service_area", "city_name", "rate_type", "hh_use", "service", "category"), all=TRUE)

commod.volume <- fx2 %>% filter(rate_type=="commodity") %>% select(-rate_type) %>% rename(commodity_unit_price = unit_price)
surcharge.volume <- fx2 %>% filter(rate_type=="surcharge") %>% select(-rate_type) %>% rename(vol_surcharge = vol_cost) %>% select(-unit_price)
volume <- merge(commod.volume, surcharge.volume, by.x=c("pwsid", "service_area", "city_name", "service", "hh_use", "category"), by.y=c("pwsid","service_area","city_name", "service", "hh_use", "category"), all=TRUE)

#Miguel Water has a person surcharge... manually add for now... $12.72 per person... assuming 3 persons
volume <- volume %>% mutate(vol_surcharge = ifelse(pwsid=="CA3010073" & service=="sewer" & category=="inside", 3*12.72, vol_surcharge))

foo <- merge(fixed.charge, volume, by.x=c("pwsid", "service_area", "city_name", "service","category"), by.y=c("pwsid","service_area","city_name", "service","category"), all=TRUE) %>% arrange(pwsid, service, category, hh_use)
summary(foo)


# calculate zone commodity charges ---------------------------------------------------------------------------------------------------------------------------------
#volumetric charges - flat - some utilities charge a flat amount if you fall within a tier
ws.zone <- res.rates %>% filter(volumetric=="zone") %>% mutate(value_from = ifelse(vol_unit=="gallons", value_from, value_from*7.48052), value_to = ifelse(vol_unit=="gallons", value_to, value_to*7.48052))
ws.zone <- ws.zone %>% mutate(zone_type = ifelse(rate_type=="commodity_charge_zone", "commodity", "surcharge"))

#create dataframe
zone <- as.data.frame(matrix(nrow=0, ncol=9)); colnames(zone) <- c("pwsid","service_area","city_name", "service","category", "zone_type","hh_use","zone_cost")
unique.pwsid <- unique(ws.zone$pwsid)
for(i in 1:length(unique.pwsid)){
  zt <- subset(ws.zone, pwsid==as.character(unique.pwsid[i]));
  zt2 = NA;
  for (j in 1:length(gal.month)){
    zt$hh_use <- ifelse(zt$vol_unit=="person", 3, gal.month[j]);
    zt$hh_use <- ifelse(zt$vol_unit=="tax-based", tax.based, gal.month[j]);
    zt$hh_use <- ifelse(zt$vol_unit=="percent impervious surface", percent.impervious, gal.month[j]); 
    
    #hh use should be multiplied based on bill frequency to get cost... then divide
    #except for zones will charge x number of times each year
    zt2 <- zt %>% mutate(hh_use_adj = hh_use * adjustment) %>% mutate(bill2months = ifelse(bill_frequency == "quarterly", 4, ifelse(bill_frequency == "bi-monthly", 2, ifelse(bill_frequency == "semi-annually", 6, ifelse(bill_frequency=="annually", 12, 1)))))
    
    #zt2 <- zt %>% mutate(hh_use_adj = hh_use * adjustment) %>% mutate(value_from = ifelse(bill_frequency == "quarterly", value_from/3, ifelse(bill_frequency == "bi-monthly", value_from/2, 
    #                                                                               ifelse(bill_frequency == "semi-annually", value_from/6, ifelse(bill_frequency=="annually", value_from/12, value_from))))) %>% 
    #  mutate(value_to = ifelse(bill_frequency == "quarterly", value_to/3, ifelse(bill_frequency == "bi-monthly", value_to/2,ifelse(bill_frequency == "semi-annually", value_to/6, 
    #                                                                               ifelse(bill_frequency=="annually", value_to/12, value_to)))))
    
    zt2 <- zt2  %>% filter(value_from <= hh_use_adj & value_to >= hh_use_adj) %>% 
      group_by(pwsid, service_area, service, city_name, utility_name, category, zone_type, bill_frequency, hh_use, bill2months) %>% summarise(zone_cost = round(mean(cost, na.rm=TRUE),2), .groups="drop") %>% 
      mutate(zone_cost = zone_cost/bill2months)
    
    zt2 <- zt2 %>% mutate(category = ifelse(category != "outside", "inside", "outside"))
    zt2 <- zt2 %>% select(pwsid, service_area, city_name, zone_type, service, category, hh_use, zone_cost) %>% group_by(pwsid, service_area, city_name, zone_type, service, category, hh_use) %>% 
      summarize(zone_cost=round(mean(zone_cost, na.rm=TRUE),2), .groups="drop")
    zt2 <- zt2 %>% select(pwsid, service_area, city_name, service, category, zone_type, hh_use, zone_cost)
    
    #if only volume charge partially still need to create dataframe
    if (dim(zt2)[1]==0){
      zt2 <- zt %>% select(pwsid, service_area, city_name, service, category, zone_type, hh_use) %>% distinct() %>% mutate(zone_cost = 0)
    }
    #bind onto volume dataframe  
    zone <- rbind(zone, zt2)
  }
  print(paste0(i, ": ", unique.pwsid[i]));
}
zone <- zone %>% distinct()
summary(zone)
table(zone$service, zone$category)

#for those that had inside / outside rates for one service, apply the inside rate to the outside for the missing service... assumption that service is applied outside
fx <- zone %>% pivot_wider(id_cols = c("pwsid", "service_area", "city_name", "zone_type","hh_use"), names_from = c("service", "category"), values_from = zone_cost)
#fix if inside rates but not outside rates... not vice versa for NC because shapefile set to outside if only outside
  fx <- fx %>% mutate(sewer_outside = ifelse(is.na(water_outside)==FALSE & is.na(sewer_outside)==TRUE & is.na(sewer_inside)==FALSE, sewer_inside, sewer_outside), 
                      water_outside = ifelse(is.na(water_outside)==TRUE & is.na(sewer_outside)==FALSE & is.na(water_inside)==FALSE, water_inside, water_outside))

#recombine
fx2 <- fx %>%  gather(var, zone_cost, -c("pwsid", "service_area", "city_name", "zone_type", "hh_use")) %>% mutate(service = substr(var, 0, 5), category = substr(var, 7, nchar(var)))  %>% select(-var)
commod.zone <- fx2 %>% filter(zone_type=="commodity") %>% select(-zone_type)
surcharge.zone <- fx2 %>% filter(zone_type=="surcharge") %>% select(-zone_type) %>% rename(zone_surcharge = zone_cost)
zone <-  merge(commod.zone, surcharge.zone, by.x=c("pwsid", "service_area", "city_name", "service", "category", "hh_use"), by.y=c("pwsid","service_area","city_name", "service", "category", "hh_use"), all=TRUE)

df <- merge(foo, zone, by.x=c("pwsid", "service_area", "service", "city_name", "category", "hh_use"), by.y=c("pwsid", "service_area", "service", "city_name", "category", "hh_use"), all=TRUE)
df <- unique(df)

#Fixes for specific systems with difficult rates
zt <- df %>% filter(pwsid=="NC0229025"); #service area has two names
df <- df %>% mutate(service_area = ifelse(pwsid=="NC0229025", "Davidson Water", service_area)) %>% filter(is.na(hh_use)==FALSE)
df <- df %>% mutate(service_area = ifelse(pwsid=="NC0472015", "Perquimans County/Winfall", service_area)) %>% mutate(service_area = ifelse(pwsid=="NC1014001", "Caldwell County/Gamewell", service_area))
df <- df %>% mutate(base_cost = ifelse((pwsid=="CA3110003" & service == "water" & category == "inside"), 90.54, base_cost))
#df %>% filter(pwsid=="CA3110003" & category=="inside")

df[is.na(df)] <- 0;
df <- df %>% mutate(total = base_cost + fixed_surcharge + vol_cost + vol_surcharge + zone_cost + zone_surcharge)

#set NA to zero for averaging
df <- df %>%  mutate(total = na_if(total, 0), base_cost = na_if(base_cost, 0), vol_cost = na_if(vol_cost, 0), commodity_unit_price = na_if(commodity_unit_price, 0), zone_cost = na_if(zone_cost, 0))
df2 <- df %>% group_by(pwsid, service_area, service, category, hh_use) %>% summarize(base_cost = round(mean(base_cost, na.rm=TRUE),2), fixed_surcharge = round(mean(fixed_surcharge, na.rm=TRUE),2), commodity_unit_price = round(mean(commodity_unit_price, na.rm=TRUE),2),
                                                                           vol_cost = round(mean(vol_cost, na.rm=TRUE),2), vol_surcharge = round(mean(vol_surcharge, na.rm=TRUE),2), zone_cost = round(mean(zone_cost, na.rm=TRUE),2), zone_surcharge = round(mean(zone_surcharge, na.rm=TRUE),2),
                                                                           total = round(mean(total, na.rm=TRUE),2), .groups="drop")
#TOTAL HERE MAKES A BIG DIFFERENCE FOR PA
df2 <- df2 %>% distinct()
summary(df2)

zt <- as.data.frame(table(df2$pwsid))
subset(zt, Freq>72)

#Now lets add a third column for those that are both water and sewer to get teh total price
df.ws <- df2 %>% pivot_wider(id_cols = c("pwsid", "service_area", "hh_use", "category"), names_from = service, values_from = c("base_cost", "vol_cost","zone_cost","fixed_surcharge","vol_surcharge", "zone_surcharge", "total", "commodity_unit_price"))
#fill NA's with previous value in group
df.ws <- df.ws %>%  group_by(pwsid, service_area, category) %>% fill(base_cost_sewer, base_cost_water, vol_cost_sewer, vol_cost_water, zone_cost_sewer, zone_cost_water, fixed_surcharge_sewer, 
                                                                   fixed_surcharge_water, vol_surcharge_sewer, vol_surcharge_water, zone_surcharge_sewer, zone_surcharge_water,
                                                                   total_sewer, total_water, .direction = "down")
#now add a flag for water and sew
df.ws <- df.ws %>% mutate(nwat = ifelse(is.na(total_water)==FALSE, 1, 0), nsew = ifelse(is.na(total_sewer)==FALSE, 1, 0)) %>% mutate(n_services = nwat+nsew) %>% select(-nwat, -nsew)

#add total
df.ws <- df.ws %>% mutate(base_cost_total = base_cost_water + base_cost_sewer, vol_cost_total = vol_cost_water + vol_cost_sewer, zone_cost_total = zone_cost_water + zone_cost_sewer, 
                          fixed_surcharge_total = fixed_surcharge_sewer + fixed_surcharge_water, vol_surcharge_total = vol_surcharge_water + vol_surcharge_sewer, zone_surcharge_total = zone_surcharge_water + zone_surcharge_sewer,
                          total_total = total_sewer + total_water)

#make long again
df.ws2 <- df.ws %>%  gather(var, val, -c("pwsid", "service_area", "category", "hh_use", "n_services")) %>% mutate(service = substr(var, nchar(var)-4, nchar(var)), var = substr(var, 0, nchar(var)-6)) %>% spread(var, val)
summary(df.ws2)
table(df.ws2$n_services, useNA="ifany")
df.ws2[is.na(df.ws2)] <- 0;


#LETS ADD IN STORMWATER
#calculate base or minimum charge----------------------------------------------
fixed.charge <- storm.rates %>% mutate(rate_type = ifelse(rate_type=="service_charge", "service", "surcharge"))
fixed.charge <- fixed.charge %>% filter(volumetric =="no") %>% group_by(pwsid, service_area, rate_type, service, bill_frequency, category)  %>%
  mutate(base_cost = ifelse(bill_frequency == "quarterly", round(cost/3,2),  ifelse(bill_frequency == "bi-monthly", round(cost/2, 2), 
                                 ifelse(bill_frequency == "semi-annually", round(cost/6, 2), ifelse(bill_frequency=="annually", round(cost/12,2), cost)))))

#assume always inside rates
#fixed.charge <- fixed.charge %>% mutate(category = "inside")
fixed.charge <- fixed.charge %>% group_by(pwsid, service_area, service, category) %>% summarise(base_cost = round(mean(base_cost, na.rm=TRUE),2), .groups = "drop") %>% as.data.frame()
#take average cost by category
fixed.charge <- fixed.charge %>% mutate(category = ifelse(category=="outside", "outside", "inside")) %>% 
  group_by(pwsid, service_area, service, category) %>% summarise(base_cost = round(mean(base_cost, na.rm=TRUE),2), .groups = "drop") %>% as.data.frame()

#For stormwater - set anticipated tier
storm.volume <- storm.rates %>% filter(rate_type=="commodity_charge_flat" | rate_type=="commodity_charge_tier") %>% filter(volumetric=="yes") %>% mutate(hh_use = ifelse(vol_unit=="ERU", 1, ifelse(vol_unit=="square feet", res.ft, NA)))
  storm.volume <- storm.volume %>% mutate(hh_use = ifelse(vol_base==1 & vol_unit == "square feet", res.ft, hh_use))
storm.volume <- storm.volume %>% filter(value_from <= hh_use) %>% mutate(volCost = ifelse(value_to <= hh_use, round((value_to - value_from)*cost/vol_base,2),
                                                                                          round((hh_use - value_from)*cost/vol_base, 2)))

storm.volume <- storm.volume %>% mutate(category = ifelse(category=="outside", "outside", "inside"))
storm.volume <- storm.volume %>% group_by(pwsid, service_area, service, category, bill_frequency) %>% summarize(volCost = sum(volCost, na.rm=TRUE), .groups="drop") %>% 
  mutate(vol_cost = ifelse(bill_frequency == "quarterly", round(volCost/3,2), ifelse(bill_frequency == "bi-monthly", round(volCost/2, 2), 
                                ifelse(bill_frequency == "semi-annually", round(volCost/6, 2), ifelse(bill_frequency=="annually", round(volCost/12,2), volCost))))) %>% as.data.frame()

storm.zone <- storm.rates %>% filter(volumetric=="zone") %>% mutate(category = ifelse(category=="outside", "outside", "inside")) %>%  
  mutate(hh_use = ifelse(vol_unit=="ERU", 1, ifelse(vol_unit=="square feet", res.ft, 
                  ifelse(vol_unit=="percent impervious surface", percent.impervious, 
                  ifelse(vol_unit=="tax-based", tax.based, NA)))))

storm.zone <- storm.zone  %>% filter(value_from <= hh_use & value_to >= hh_use) %>% 
  group_by(pwsid, service_area, service, category, bill_frequency) %>% summarise(zoneCost = mean(cost, na.rm=TRUE), .groups='drop') %>% 
  mutate(zone_cost = ifelse(bill_frequency == "quarterly", round(zoneCost/3,2), ifelse(bill_frequency == "bi-monthly", round(zoneCost/2, 2), 
                      ifelse(bill_frequency == "semi-annually", round(zoneCost/6, 2), ifelse(bill_frequency=="annually", round(zoneCost/12,2), zoneCost))))) %>% as.data.frame()

#combine into a single stormwater fee for all volumes
df.storm <-  merge(fixed.charge, storm.volume, by.x=c("pwsid","service_area","service","category"), by.y=c("pwsid","service_area","service","category"), all=TRUE) %>% select(-bill_frequency, -volCost)
df.storm <- merge(df.storm, storm.zone, by.x=c("pwsid","service_area","service","category"), by.y=c("pwsid","service_area","service","category"), all=TRUE) %>% select(-bill_frequency, -zoneCost)
df.storm[is.na(df.storm)] <- 0
df.storm <- df.storm %>% mutate(total_storm = base_cost + vol_cost + zone_cost) %>% select(-base_cost, -vol_cost, -zone_cost, -service) %>% group_by(pwsid, service_area, category) %>% 
  summarize(total_storm = mean(total_storm, na.rm=TRUE), .groups="drop")

#add last column to df.ws2
df.all <- merge(df.ws, df.storm, by.x=c("pwsid","service_area","category"), by.y=c("pwsid","service_area","category"), all.x=TRUE)
df.all[is.na(df.all)] <- 0

df.all <- df.all %>%  gather(var, val, -c("pwsid", "service_area", "category", "hh_use", "n_services")) %>% mutate(service = substr(var, nchar(var)-4, nchar(var)), var = substr(var, 0, nchar(var)-6)) %>% spread(var, val)
#notice that the total does NOT include stormwater... will need to be added later... I think keep separate since such a hard one to find and so different
summary(df.all)


#Read in the full table. Remove those with pwsid in this list. Add new rates here.
if(exists("update.list")){
  orig.data <- read.csv(paste0(swd_results, "estimated_bills.csv"))
  '%!in%' <- function(x,y)!('%in%'(x,y)); #create function to remove bills that need to be updated
  orig.data <- orig.data %>% filter(pwsid %!in% df.all$pwsid)
  orig.data <- rbind(orig.data, df.all)
  write.csv(orig.data, paste0(swd_results, "estimated_bills.csv"), row.names=FALSE); #if you redid part of the file
} else {
  write.csv(df.all, paste0(swd_results, "estimated_bills.csv"), row.names=FALSE); #if you redid the full file
}

rm(storm.rates, storm.volume, storm.zone, orig.data, rates, res.rates, service.only, fx, fx2, fx3, keep.pwsid, flat.surcharge, fixed.charge, df2, df.ws2, df.ws, df.storm, df.all, bk.up, commod.volume, commod.zone, df)
rm(surcharge.volume, surcharge.zone, update.list, volume, ws.volume, zt2, zt3, ws.zone, zone, zt, i, j, gal.month, unique.pwsid)
