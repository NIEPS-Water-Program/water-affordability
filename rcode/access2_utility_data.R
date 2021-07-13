#######################################################################################################################################################
#
#
# This script is run as needed to create inside/outside boundaries for analysis. It should be run whenever new rates data are added.
# Created by Lauren Patterson for the Affordability Dashboard in 2021
#
#
########################################################################################################################################################


#read in municipal file to create inside and outside rate areas
muni <- read_sf(paste0(swd_data, "muni.geojson"))

###################################################################################################################################################################
#
# (1) UPDATE UTILITY SPATIAL BOUNDARIES OR ADD NEW STATES: CA
#
####################################################################################################################################################################
# California -- will need to find new api
ca.sys <- read_sf("https://opendata.arcgis.com/datasets/fbba842bf134497c9d611ad506ec48cc_0.geojson"); 
ca.sys <-  ca.sys %>% st_transform(crs = 4326) %>%  rename(pwsid = WATER_SYSTEM_NUMBER, gis_name = WATER_SYSTEM_NAME) %>% mutate(state = "ca") %>% 
   filter(STATE_CLASSIFICATION != "NON-TRANSIENT NON-COMMUNITY") %>% filter(STATE_CLASSIFICATION != "TRANSIENT NON-COMMUNITY") %>% 
   select(pwsid, gis_name, POPULATION, SERVICE_CONNECTIONS) %>% rename(population = POPULATION, connections = SERVICE_CONNECTIONS)
geojson_write(ca.sys, file = paste0(swd_data ,"ca_systems.geojson"))

###################################################################################################################################################################
## INSIDE AND OUTSIDE BOUNDARIES - 
#####################################################################################################################################################################
#Intersect the municipal boundaries with the state to create inside and outside
#simplify a little to avoid a bunch of errors
ca.rates <- read_excel(paste0(swd_data, "rates_data\\rates_ca.xlsx"), sheet="rateTable") %>% 
  filter(other_class == "inside_outside")
ca.rates <- ca.rates %>% filter(pwsid %in% ca.sys$pwsid); #only keep those that are in the shapefiel
ca.muni <- muni %>% filter(state=="ca") #%>% ms_simplify(keep=0.5, keep_shapes=TRUE); simplified earlier to 0.5 in saved file
ca.sys <- ca.sys %>% ms_simplify(keep=0.5, keep_shapes=TRUE)

#fix any corrupt shapefiles
if (FALSE %in% st_is_valid(ca.muni)) {ca.muni <- suppressWarnings(st_buffer(ca.muni[!is.na(st_is_valid(ca.muni)),], 0.0)); print("fixed")}#fix corrupt shapefiles
if (FALSE %in% st_is_valid(ca.sys)) {ca.sys <- suppressWarnings(st_buffer(ca.sys[!is.na(st_is_valid(ca.sys)),], 0.0)); print("fixed")}#fix corrupt shapefiles

#ca muni is to big to union with ca.sys... therefore will loop through and try to do that way.
ca.pwsid <- unique(ca.rates$pwsid)
#all.in.out <- ca.sys %>% filter(pwsid==ca.pwsid[1]) %>% mutate(category = "delete") %>% select(pwsid, gis_name, category, geometry)
all.in.out <- ca.sys %>% filter(pwsid %notin% ca.pwsid) %>% mutate(category = "inside") %>% select(pwsid, gis_name, category, geometry)


for (i in 1:length(ca.pwsid)){
  st_erase = all.in.out %>% filter(category == "blank")
  ca.sel <- ca.sys %>% filter(pwsid==ca.pwsid[i])
  intmunis <- st_intersection(ca.sel, ca.muni) 
  
  if(dim(intmunis)[1] > 0){
    intmunis$muniArea = st_area(intmunis$geometry)
    
    inside <- st_union(intmunis) %>% st_sf() 
  
    st_erase = st_difference(ca.sel, inside) %>% mutate(category = "outside") %>% select(pwsid, gis_name, category, geometry)
      st_erase$area = st_area(st_erase$geometry)
    
    if(dim(st_erase)[1] > 0) {
      st_union <- inside %>% mutate(pwsid = ca.pwsid[i], gis_name = ca.sel$gis_name[1], category = "inside") %>% select(pwsid, gis_name, category, geometry)
        st_union$area = st_area(st_union$geometry)
        
      in.out = rbind(st_erase, st_union) %>% select(pwsid, gis_name, category, geometry)
      perOut = 100*(as.numeric(st_erase$area)/(as.numeric(st_erase$area) + as.numeric(st_union$area)))
      
      #if outside area is less than 1%, just make all insdie
      if(perOut <= 1){
        in.out = ca.sel %>% mutate(category="inside") %>% select(pwsid, gis_name, category, geometry)
      }
    }
  }
  if(dim(st_erase)[1] == 0) {
    in.out = ca.sel %>% mutate(category="inside") %>% select(pwsid, gis_name, category, geometry)
  }
  
  if(dim(intmunis)[1] == 0){
    in.out = ca.sel %>% mutate(category="inside") %>% select(pwsid, gis_name, category, geometry)
  }
  
  #rbind to a full database
  all.in.out <- rbind(all.in.out, in.out)
  print(i)
}
table(all.in.out$category)
geojson_write(all.in.out, file = paste0(swd_data,"ca_in_out_systems.geojson"))

leaflet() %>% addProviderTiles("Stamen.TonerLite") %>% 
  addPolygons(data = all.in.out %>% filter(pwsid %in% ca.pwsid),
              fillOpacity= 0.6,  fillColor = ifelse(subset(all.in.out, pwsid %in% ca.pwsid)$category=="inside", "blue", "red"), #make sure matches data
              color="blue",  weight=1,
              popup=~paste0("pwsid: ", pwsid)) %>% 
  addPolygons(data = muni %>% filter(state=="ca"),
              fillOpacity= 0.3,  fillColor = "white", color="black",  weight=3) 

rm(all.in.out, ca.sel, ca.sys, intmunis, st_erase, st_union, ca.muni, ca.rates, ca.pwsid, in.out, perOut)

###################################################################################################################################################################
#
# (1) UPDATE UTILITY SPATIAL BOUNDARIES OR ADD NEW STATES: NC
#
####################################################################################################################################################################
nc.sys <- read_sf("https://aboutus.internetofwater.dev/geoserver/ows?service=WFS&version=1.0.0&request=GetFeature&typename=geonode%3Anc_statewide_CWS&outputFormat=json&srs=EPSG%3A2264&srsName=EPSG%3A2264")
nc.sys <- nc.sys %>% st_transform(crs = 4326) %>%  rename(pwsid = PWSID, gis_name = SystemName) %>% mutate(state = "nc") %>% mutate(pwsid = paste0("NC", str_remove_all(pwsid, "[-]"))) %>% select(pwsid, gis_name, geometry, state)
nc.sys <- nc.sys %>% ms_simplify(keep=0.5, keep_shapes=TRUE); #file is huge
if (FALSE %in% st_is_valid(nc.sys)) {nc.sys <- suppressWarnings(st_buffer(nc.sys[!is.na(st_is_valid(nc.sys)),], 0.0)); print("fixed")}#fix corrupt shapefiles
nc.sys <- nc.sys %>% mutate(pwsid = ifelse(pwsid == "NC03_63_108", "NC0363108", pwsid))
geojson_write(nc.sys, file = paste0(swd_data, "nc_systems.geojson"))


###################################################################################################################################################################
## INSIDE AND OUTSIDE BOUNDARIES - 
#####################################################################################################################################################################
#Intersect the municipal boundaries with the state to create inside and outside
#simplify a little to avoid a bunch of errors
nc.muni <- muni %>% filter(state=="nc") #%>% ms_simplify(keep=0.5, keep_shapes=TRUE); simplified earlier to 0.5 in saved file
nc.rates <- read_excel(paste0(swd_data, "\\rates_data\\rates_nc.xlsx"), sheet="rateTable") %>% mutate(adjustment = 1, state = "nc") %>% select(-notes) %>% 
  filter(rate_type != "drought_surcharge" & rate_type != "drought_mandatory_surcharge" & rate_type != "drought_voluntary_surcharge" & rate_type != "conservation_surcharge") %>% 
  mutate(pwsid = paste0("NC",str_remove_all(pwsid, "[-]"))) %>% filter(other_class=="inside_outside") %>% 
  filter(pwsid != "NC0392010Wendell") %>% filter(pwsid != "NC0392010Zebulon") %>% filter(pwsid != "NC0276035Highway22")
  #Spruce pine is an empty shapefile

#fix corrupt shapfiles
nc.sys <- nc.sys %>% ms_simplify(keep=0.8, keep_shapes=TRUE); #file is still huge and super slow. gets bogged down on pwsid 127
if (FALSE %in% st_is_valid(nc.muni)) {nc.muni <- suppressWarnings(st_buffer(nc.muni[!is.na(st_is_valid(nc.muni)),], 0.0)); print("fixed")}#fix corrupt shapefiles

#ca muni is to big to union with ca.sys... therefore will loop through and try to do that way.
nc.rates <- nc.rates %>% filter(pwsid %in% nc.sys$pwsid); #only keep those that are in the shapefiel
nc.pwsid <- unique(nc.rates$pwsid)
`%notin%` = function(x,y) !(x %in% y); #function to get what is not in the list

all.in.out <- nc.sys %>% filter(pwsid %notin% nc.pwsid) %>% mutate(category = "inside") %>% select(pwsid, gis_name, category, geometry)

for (i in 312:length(nc.pwsid)){; #highpoint is very slow to run
  st_erase = all.in.out %>% filter(category == "blank")
  nc.sel <- nc.sys %>% filter(pwsid==nc.pwsid[i])
  #nc.sel <- nc.sys %>% filter(pwsid==nc.pwsid[i]) %>% ms_simplify(keep=0.5, keep_shapes=TRUE); #use when errors emerge
  
  if(nc.sel$pwsid != "NC0241020") {
  intmunis <- st_intersection(nc.sel, nc.muni) %>% ms_simplify(keep = 0.9, keep_shapes=TRUE)
  
  if(dim(intmunis)[1] > 0){
    intmunis$muniArea = st_area(intmunis$geometry) 
    inside <- st_union(intmunis) %>% st_sf() 
    
    st_erase = st_difference(nc.sel, inside) %>% mutate(category = "outside") %>% select(pwsid, gis_name, category, geometry)
    st_erase$area = st_area(st_erase$geometry)
    
    if(dim(st_erase)[1] > 0) {
      st_union <- inside %>% mutate(pwsid = nc.pwsid[i], gis_name = nc.sel$gis_name[1], category = "inside") %>% select(pwsid, gis_name, category, geometry)
      st_union$area = st_area(st_union$geometry)
      
      in.out = rbind(st_erase, st_union) %>% select(pwsid, gis_name, category, geometry)
      perOut = 100*(as.numeric(st_erase$area)/(as.numeric(st_erase$area) + as.numeric(st_union$area)))
      
      #if outside area is less than 1%, just make all insdie
      if(perOut <= 1){
        in.out = nc.sel %>% mutate(category="inside") %>% select(pwsid, gis_name, category, geometry)
      }
    }
  }
  } #end if statement for High Point because breaks R
  if(dim(st_erase)[1] == 0) {
    in.out = nc.sel %>% mutate(category="inside") %>% select(pwsid, gis_name, category, geometry)
  }
  
  if(dim(intmunis)[1] == 0){
    in.out = nc.sel %>% mutate(category="inside") %>% select(pwsid, gis_name, category, geometry)
  }
  
  #rbind to a full database
  all.in.out <- rbind(all.in.out, in.out)
  print(i)
}
table(all.in.out$category)
all.in.out <- all.in.out %>% filter(category != "delete")
geojson_write(all.in.out, file = paste0(swd_data, "nc_in_out_systems.geojson"))

zt <- all.in.out %>% mutate(colorCategory = ifelse(category=="inside", "blue", "red")) %>% filter(pwsid %in% nc.pwsid)
leaflet() %>% addProviderTiles("Stamen.TonerLite") %>% 
  addPolygons(data = zt,
              fillOpacity= 0.5,  fillColor = zt$colorCategory, #make sure matches data
              color="blue",  weight=1,
              popup=~paste0("pwsid: ", pwsid))# %>% 
  #addPolygons(data = muni %>% filter(state=="nc"),
  #            fillOpacity= 0.3,  fillColor = "white", color="black",  weight=3) 

rm(all.in.out, nc.sel, nc.sys, intmunis, st_erase, st_union, nc.muni, nc.rates, nc.pwsid, in.out, perOut)

###################################################################################################################################################################
#
# (1) UPDATE UTILITY SPATIAL BOUNDARIES OR ADD NEW STATES: TX
#
####################################################################################################################################################################
#THe shapefile has to be manually downloaded from here and unzipped: https://www3.twdb.texas.gov/apps/WaterServiceBoundaries
tx.sys <- readOGR("C:\\Users\\lap19\\Downloads\\PWS_shapefile", "PWS_Export")
tx.sys <- tx.sys %>% st_as_sf %>% st_transform(crs = 4326) %>%  rename(pwsid = PWSId, gis_name = pwsName) %>% mutate(state = "tx") %>% select(pwsid, gis_name, geometry, state)
if (FALSE %in% st_is_valid(tx.sys)) {tx.sys <- suppressWarnings(st_buffer(tx.sys[!is.na(st_is_valid(tx.sys)),], 0.0)); print("fixed")}#fix corrupt shapefiles
geojson_write(tx.sys, file = paste0(swd_data, "tx_systems.geojson"))


###################################################################################################################################################################
## INSIDE AND OUTSIDE BOUNDARIES - 
#####################################################################################################################################################################
#Intersect the municipal boundaries with the state to create inside and outside
#simplify a little to avoid a bunch of errors
tx.muni <- muni %>% filter(state=="tx") #%>% ms_simplify(keep=0.5, keep_shapes=TRUE); simplified earlier to 0.5 in saved file
tx.rates <- read_excel(paste0(swd_data, "rates_data//rates_tx.xlsx"), sheet="rateTable") %>%  filter(other_class=="inside_outside")

#fix corrupt shapfiles
if (FALSE %in% st_is_valid(tx.muni)) {tx.muni <- suppressWarnings(st_buffer(tx.muni[!is.na(st_is_valid(tx.muni)),], 0.0)); print("fixed")}#fix corrupt shapefiles

tx.rates <- tx.rates %>% filter(pwsid %in% tx.sys$pwsid); #only keep those that are in the shapefiel
tx.pwsid <- unique(tx.rates$pwsid)
`%notin%` = function(x,y) !(x %in% y); #function to get what is not in the list
all.in.out <- tx.sys %>% filter(pwsid %notin% tx.pwsid) %>% mutate(category = "inside") %>% select(pwsid, gis_name, category, geometry)

for (i in 1:length(tx.pwsid)){
  st_erase = all.in.out %>% filter(category == "blank")
  tx.sel <- tx.sys %>% filter(pwsid==tx.pwsid[i])
  intmunis <- st_intersection(tx.sel, tx.muni) 
  
  if(dim(intmunis)[1] > 0){
    intmunis$muniArea = st_area(intmunis$geometry)
    inside <- st_union(intmunis) %>% st_sf() 
    
    st_erase = st_difference(tx.sel, inside) %>% mutate(category = "outside") %>% select(pwsid, gis_name, category, geometry)
    st_erase$area = st_area(st_erase$geometry)
    
    if(dim(st_erase)[1] > 0) {
      st_union <- inside %>% mutate(pwsid = tx.pwsid[i], gis_name = tx.sel$gis_name[1], category = "inside") %>% select(pwsid, gis_name, category, geometry)
      st_union$area = st_area(st_union$geometry)
      
      in.out = rbind(st_erase, st_union) %>% select(pwsid, gis_name, category, geometry)
      perOut = 100*(as.numeric(st_erase$area)/(as.numeric(st_erase$area) + as.numeric(st_union$area)))
      
      #if outside area is less than 1%, just make all insdie
      if(perOut <= 1){
        in.out = tx.sel %>% mutate(category="inside") %>% select(pwsid, gis_name, category, geometry)
      }
    }
  }
  if(dim(st_erase)[1] == 0) {
    in.out = tx.sel %>% mutate(category="inside") %>% select(pwsid, gis_name, category, geometry)
  }
  
  if(dim(intmunis)[1] == 0){
    in.out = tx.sel %>% mutate(category="inside") %>% select(pwsid, gis_name, category, geometry)
  }
  
  #rbind to a full database
  all.in.out <- rbind(all.in.out, in.out)
  print(i)
}
table(all.in.out$category)
geojson_write(all.in.out, file = paste0(swd_data, "tx_in_out_systems.geojson"))

leaflet() %>% addProviderTiles("Stamen.TonerLite") %>% 
  addPolygons(data = all.in.out %>% filter(pwsid %in% tx.pwsid),
              fillOpacity= 0.6,  fillColor = ifelse(subset(all.in.out, pwsid %in% tx.pwsid)$category=="inside", "blue", "red"), #make sure matches data
              color="blue",  weight=1,
              popup=~paste0("pwsid: ", pwsid)) 
  
rm(all.in.out, tx.sel, tx.sys, intmunis, st_erase, st_union, tx.muni, tx.rates, ca.pwsid, in.out, perOut, inside, muni)



###################################################################################################################################################################
#
# (1) UPDATE UTILITY SPATIAL BOUNDARIES OR ADD NEW STATES: PA & OR --> NO INSIDE OR OUTSIDE
#
####################################################################################################################################################################
# Pennsyvlania -- will need to find new api
tmp <- tempfile()
curl_download("https://www.pasda.psu.edu/json/PublicWaterSupply2020_04.geojson", tmp); 
#mapview::mapview(pa.sys)
pa.sys <-  read_sf(tmp) 
pa.sys <- pa.sys %>% st_transform(crs = 4326) %>%  rename(pwsid =PWS_ID, gis_name = NAME, owner = OWNERSHIP) %>% mutate(state = "pa", pwsid = paste0("PA", pwsid)) %>% 
  mutate(category = "inside") %>% select(pwsid, gis_name, owner, category, geometry)
geojson_write(pa.sys, file = paste0(swd_data, "pa_systems.geojson"))
unlink(tmp)

# Oregon
or.sys <- read_sf(paste0(swd_data, folder.year, "\\or_systems.geojson"))
#A spreadsheet must be created that links the utility pwsid to the GEOID of the city. This is a manual process
or.rates <- read_excel(paste0(swd_data, folder.year, "\\rates_data\\rates_or.xlsx"), sheet="ratesMetadata") %>% select(GEOID, pwsid, service_area) %>% distinct()

or.sys <- merge(or.sys, or.rates, by.x="GEOID", by.y="GEOID") %>% rename(gis_name = service_area) %>% select(pwsid, gis_name, geometry, state, GISJOIN, GEOID, city_name, STATEFP)
geojson_write(or.sys, file = paste0(swd_data, "or_systems.geojson"))


rm(tmp, pa.sys, or.sys, or.rates)

