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
tx.rates <- read_excel(paste0(swd_data, "rates_data//rates_tx.xlsx"), sheet="rateTable") %>% filter(other_class=="inside_outside")

#fix corrupt shapfiles
#New SF package is breaking this:
tx.muni$geometry <- tx.muni$geometry %>% s2::s2_rebuild() %>% sf::st_as_sfc()
sf::sf_use_s2(FALSE)
if (FALSE %in% st_is_valid(tx.muni)) {tx.muni <- suppressWarnings(st_buffer(tx.muni[!is.na(st_is_valid(tx.muni)),], 0.0)); print("fixed")}#fix corrupt shapefiles
#for (i in 1:dim(tx.muni)[1]){
#  if(st_is_valid(tx.muni[i,])){
#    tx.muni[i,] = st_make_valid(tx.muni[i,])
#    print(paste0(i, ": ", st_is_valid(tx.muni[i,])))
#  }
#  if(i %in% seq(0,2000,50))
#    print(paste0(i, ": ", round(i/dim(tx.muni)[1]*100,2), " done"))
#}


tx.rates <- tx.rates %>% filter(pwsid %in% tx.sys$pwsid); #only keep those that are in the shapefiel
tx.pwsid <- unique(tx.rates$pwsid)
`%notin%` = function(x,y) !(x %in% y); #function to get what is not in the list
all.in.out <- tx.sys %>% filter(pwsid %notin% tx.pwsid) %>% mutate(category = "inside") %>% select(pwsid, gis_name, category, geometry)

for (i in 1:length(tx.pwsid)){
#for (i in 101:110){
  st_erase = all.in.out %>% filter(category == "blank")
  tx.sel <- tx.sys %>% filter(pwsid==tx.pwsid[i])
  intmunis <- st_intersection(tx.sel, tx.muni)

  if(dim(intmunis)[1] > 0){
    intmunis$muniArea = st_area(intmunis$geometry)
    inside <- st_union(intmunis) %>% st_sf() 
    
    st_erase = st_difference(tx.sel, inside) %>% mutate(category = "outside") %>% select(pwsid, gis_name, category, geometry)
    st_erase$area = st_area(st_erase$geometry)
    st_erase <- st_cast(st_erase); #TX2270033 wants to be a GEOMETRYCOLLECTION
    
    if(dim(st_erase)[1] > 0) {
      st_union <- inside %>% mutate(pwsid = tx.pwsid[i], gis_name = tx.sel$gis_name[1], category = "inside") %>% select(pwsid, gis_name, category, geometry)
      st_union$area = st_area(st_union$geometry)
      
      in.out = rbind(st_erase, st_union) %>% select(pwsid, gis_name, category, geometry)
      perOut = 100*(as.numeric(st_erase$area)/(as.numeric(st_erase$area) + as.numeric(st_union$area)))
      
      #if outside area is less than 1%, just make all inside
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
  #print(summary(in.out))
  
  all.in.out <- rbind(all.in.out, in.out)
  print(i)
}
table(all.in.out$category)
summary(all.in.out)
bk.up <- all.in.out

geojson_write(all.in.out, file = paste0(swd_data, "tx_in_out_systems.geojson"))

leaflet() %>% addProviderTiles("Stamen.TonerLite") %>% 
  addPolygons(data = all.in.out %>% filter(pwsid %in% tx.pwsid),
              fillOpacity= 0.6,  fillColor = ifelse(subset(all.in.out, pwsid %in% tx.pwsid)$category=="inside", "blue", "red"), #make sure matches data
              color="blue",  weight=1,
              popup=~paste0("pwsid: ", pwsid)) 
  
rm(all.in.out, tx.sel, tx.sys, intmunis, st_erase, st_union, tx.muni, tx.rates, ca.pwsid, in.out, perOut, inside, muni)


###################################################################################################################################################################
#
# (1) UPDATE UTILITY SPATIAL BOUNDARIES OR ADD NEW STATES: NM
#
####################################################################################################################################################################
##nm.sys2 <- read_sf("https://catalog.newmexicowaterdata.org/dataset/5d069bbb-1bfe-4c83-bbf7-3582a42fce6e/resource/ccb9f5ce-aed4-4896-a2f1-aba39953e7bb/download/pws_nm.geojson")
#points - had to manually download polygon file
nm.sys <- readOGR("C:\\Users\\lap19\\Downloads","nm_pws")
nm.sys <- spTransform(nm.sys, CRS("+init=epsg:4326")) %>% st_as_sf()
nm.sys <- nm.sys %>% select(Wt_S_ID, PblcSyN) %>% rename(pwsid = Wt_S_ID, gis_name = PblcSyN) %>% mutate(state = "nm") %>% select(pwsid, gis_name, geometry, state)
if (FALSE %in% st_is_valid(nm.sys)) {nm.sys <- suppressWarnings(st_buffer(nm.sys[!is.na(st_is_valid(nm.sys)),], 0.0)); print("fixed")}#fix corrupt shapefiles
#nm has some additional letters in their pwsid and a couple that don't match EPA
subset(nm.sys, nchar(pwsid) != 9)
nm.sys <- nm.sys %>% mutate(pwsid = substr(pwsid, 1,9))
nm.sys <- nm.sys %>% mutate(pwsid = ifelse(gis_name == "SANTA FE SOUTH WATER COOP", "NM3500826", pwsid))
geojson_write(nm.sys, file = paste0(swd_data, "nm_systems.geojson"))


###################################################################################################################################################################
## INSIDE AND OUTSIDE BOUNDARIES - 
#####################################################################################################################################################################
#Intersect the municipal boundaries with the state to create inside and outside
#simplify a little to avoid a bunch of errors
nm.muni <- muni %>% filter(state=="nm") #%>% ms_simplify(keep=0.5, keep_shapes=TRUE); simplified earlier to 0.5 in saved file
nm.rates <- read_excel(paste0(swd_data, "rates_data//rates_nm.xlsx"), sheet="rateTable") %>% filter(other_class=="inside_outside")

#fix corrupt shapfiles
#New SF package is breaking this:
nm.muni$geometry <- nm.muni$geometry %>% s2::s2_rebuild() %>% sf::st_as_sfc()
sf::sf_use_s2(FALSE)
if (FALSE %in% st_is_valid(nm.muni)) {nm.muni <- suppressWarnings(st_buffer(nm.muni[!is.na(st_is_valid(nm.muni)),], 0.0)); print("fixed")}#fix corrupt shapefiles

#set up loop
nm.rates <- nm.rates %>% filter(pwsid %in% nm.sys$pwsid); #only keep those that are in the shapefiel
nm.pwsid <- unique(nm.rates$pwsid)
all.in.out <- nm.sys %>% filter(pwsid %notin% nm.pwsid) %>% mutate(category = "inside") %>% select(pwsid, gis_name, category, geometry)

for (i in 1:length(nm.pwsid)){
  #for (i in 101:110){
  st_erase = all.in.out %>% filter(category == "blank")
  nm.sel <- nm.sys %>% filter(pwsid==nm.pwsid[i])
  intmunis <- st_intersection(nm.sel, nm.muni)
  
  if(dim(intmunis)[1] > 0){
    intmunis$muniArea = st_area(intmunis$geometry)
    inside <- st_union(intmunis) %>% st_sf() 
    
    st_erase = st_difference(nm.sel, inside) %>% mutate(category = "outside") %>% select(pwsid, gis_name, category, geometry)
    st_erase$area = st_area(st_erase$geometry)
    st_erase <- st_cast(st_erase); #TX2270033 wants to be a GEOMETRYCOLLECTION
    
    if(dim(st_erase)[1] > 0) {
      st_union <- inside %>% mutate(pwsid = nm.pwsid[i], gis_name = nm.sel$gis_name[1], category = "inside") %>% select(pwsid, gis_name, category, geometry)
      st_union$area = st_area(st_union$geometry)
      
      in.out = rbind(st_erase, st_union) %>% select(pwsid, gis_name, category, geometry)
      perOut = 100*(as.numeric(st_erase$area)/(as.numeric(st_erase$area) + as.numeric(st_union$area)))
      
      #if outside area is less than 1%, just make all inside
      if(perOut <= 1){
        in.out = nm.sel %>% mutate(category="inside") %>% select(pwsid, gis_name, category, geometry)
      }
    }
  }
  if(dim(st_erase)[1] == 0) {
    in.out = nm.sel %>% mutate(category="inside") %>% select(pwsid, gis_name, category, geometry)
  }
  
  if(dim(intmunis)[1] == 0){
    in.out = nm.sel %>% mutate(category="inside") %>% select(pwsid, gis_name, category, geometry)
  }
  
  #rbind to a full database
  all.in.out <- rbind(all.in.out, in.out)
  print(i)
}
table(all.in.out$category)
summary(all.in.out)

geojson_write(all.in.out, file = paste0(swd_data, "nm_in_out_systems.geojson"))

leaflet() %>% addProviderTiles("Stamen.TonerLite") %>% 
  addPolygons(data = all.in.out %>% filter(pwsid %in% nm.pwsid),
              fillOpacity= 0.6,  fillColor = ifelse(subset(all.in.out, pwsid %in% nm.pwsid)$category=="inside", "blue", "red"), #make sure matches data
              color="blue",  weight=1,
              popup=~paste0("pwsid: ", pwsid)) 

rm(all.in.out, nm.sel, nm.sys, intmunis, st_erase, st_union, nm.muni, nm.rates, nm.pwsid, in.out, perOut, inside)



###################################################################################################################################################################
#
# (1) UPDATE UTILITY SPATIAL BOUNDARIES OR ADD NEW STATES: NJ
#
####################################################################################################################################################################
nj.sys <- read_sf("https://opendata.arcgis.com/datasets/00e7ff046ddb4302abe7b49b2ddee07e_13.geojson") %>% st_transform(crs = 4326)
nj.sys <- nj.sys %>% select(PWID, SYS_NAME, geometry) %>% rename(pwsid = PWID, gis_name = SYS_NAME) %>% mutate(state = "nj") %>% select(pwsid, gis_name, geometry, state)
if (FALSE %in% st_is_valid(nj.sys)) {nj.sys <- suppressWarnings(st_buffer(nj.sys[!is.na(st_is_valid(nj.sys)),], 0.0)); print("fixed")}#fix corrupt shapefiles
geojson_write(nj.sys, file = paste0(swd_data, "nj_systems.geojson"))

#All of NJ is a municipality so no inside / outside rates


###################################################################################################################################################################
#
# (1) UPDATE UTILITY SPATIAL BOUNDARIES OR ADD NEW STATES: CT
#
####################################################################################################################################################################
#All of CT is a municipality so no inside/outside rates
#CT systems - https://portal.ct.gov/DPH/Drinking-Water/DWS/Public-Water-Supply-Map
ct.sys <- readOGR("C:\\Users\\lap19\\Downloads\\Buffered_Community_PWS_Service_Areas", "Buffered_Community_PWS_Service_Areas") %>% 
  spTransform(ct.sys, CRS("+init=epsg:4326")) %>% st_as_sf()

ct.sys <- read_sf("new_states/ct_systems.geojson")
ct.sys <- ct.sys  %>% select(pwsid, pws_name) %>% rename(gis_name = pws_name)
if (FALSE %in% st_is_valid(ct.sys)) {ct.sys <- suppressWarnings(st_buffer(ct.sys[!is.na(st_is_valid(ct.sys)),], 0.0)); print("fixed")}#fix corrupt shapefiles

#CT merged several pswid together
aquarion <- c("CT1350011", "CT0150011", "CT1370011", "CT1240011", "CT1280021", "CT0900011",
              "CT0570011", "CT0350011", "CT0960011", "CT1180011", "CT0970011", "CT0180071", 
              "CT0180141", "CT0189961", "CT1220011", "CT1000011", "CT1180021", "CT0980011",
              "CT0098011", "CT1390021", "CT1680011", "CT0910011", "CT0680011", "CT0740011",
              "CT0378011", "CT1180081", "CT0189791")

#Greenwhich, Stanford, Ridgefield and New Canaan are all merged together
ct.muni <- muni %>% filter(state=="CT")
main.aq <- ct.sys %>% filter(pwsid=="CT0150011"); mapview::mapview(main.aq)
int.sel <- st_intersection(main.aq, ct.muni);
mapview::mapview(int.sel)
green <- int.sel %>% filter(city_name=="Greenwich") %>% mutate(pwsid="CT0570011", gis_name="AQUARION WATER CO - GREENWICH") %>% 
  select(pwsid, gis_name) %>% group_by(pwsid, gis_name) %>% summarize(n=n(), .groups="drop") %>% select(-n); mapview::mapview(green)
stam <- int.sel %>% filter(city_name=="Stamford") %>% mutate(pwsid="CT1350011", gis_name="AQUARION WATER CO - STAMFORD") %>% 
  select(pwsid, gis_name) %>% group_by(pwsid, gis_name) %>% summarize(n=n(), .groups="drop") %>% select(-n); mapview::mapview(stam)
new.can <- int.sel %>% filter(city_name=="New Canaan") %>% mutate(pwsid="CT0900011", gis_name="AQURAION WATER CO - NEW CANAAN") %>% 
  select(pwsid, gis_name) %>% group_by(pwsid, gis_name) %>% summarize(n=n(), .groups="drop") %>% select(-n); mapview::mapview(new.can)

main <- int.sel %>% filter(city_name %notin% c("Greenwich", "Stamford", "New Canaan", "Ridgefield")) %>% 
  select(pwsid, gis_name) %>% group_by(pwsid, gis_name) %>% summarize(n=n(), .groups="drop") %>% select(-n); mapview::mapview(main)

ct.sys = ct.sys %>% filter(pwsid != "CT0150011") %>% group_by(pwsid, gis_name) %>% summarize(n=n(), .groups="drop") %>% select(-n)
ct.sys <- rbind(ct.sys, main, green, stam, new.can)
mapview::mapview(ct.sys)

geojson_write(ct.sys, file=paste0(swd_data, "ct_systems.geojson"))

rm(ct.sys)

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



###################################################################################################################################################################
#
# (1) UPDATE UTILITY SPATIAL BOUNDARIES OR ADD NEW STATES: KS
#
####################################################################################################################################################################
#ks.sys <- read_sf("https://services.kansasgis.org/arcgis15/rest/services/admin_boundaries/KS_RuralWaterDistricts/MapServer")
ks.sys <- readOGR("C://Users//lap19//Documents//GIS//Utilities//KS","PWS_bnd_2021_0430")
ks.sys <- spTransform(ks.sys, CRS("+init=epsg:4326")) %>% st_as_sf()
ks.sys <- ks.sys  %>% select(FED_ID, NAMEWCPSTA) %>% rename(pwsid = FED_ID, gis_name = NAMEWCPSTA)
if (FALSE %in% st_is_valid(ks.sys)) {ks.sys <- suppressWarnings(st_buffer(ks.sys[!is.na(st_is_valid(ks.sys)),], 0.0)); print("fixed")}#fix corrupt shapefiles
geojson_write(ks.sys, file=paste0(swd_data, "ks_systems.geojson"))


#simplify a little to avoid a bunch of errors
ks.muni <- muni %>% filter(state=="ks") #%>% ms_simplify(keep=0.5, keep_shapes=TRUE); simplified earlier to 0.5 in saved file
ks.rates <- read_excel(paste0(swd_data, "rates_data//rates_ks.xlsx"), sheet="rateTable") %>% filter(other_class=="inside_outside")

#fix corrupt shapfiles
ks.muni$geometry <- ks.muni$geometry %>% s2::s2_rebuild() %>% sf::st_as_sfc()
sf::sf_use_s2(FALSE)
if (FALSE %in% st_is_valid(ks.muni)) {ks.muni <- suppressWarnings(st_buffer(ks.muni[!is.na(st_is_valid(ks.muni)),], 0.0)); print("fixed")}#fix corrupt shapefiles

#set up loop
ks.rates <- ks.rates %>% filter(pwsid %in% ks.sys$pwsid); #only keep those that are in the shapefiel
ks.pwsid <- unique(ks.rates$pwsid)
all.in.out <- ks.sys %>% filter(pwsid %notin% ks.pwsid) %>% mutate(category = "inside") %>% select(pwsid, gis_name, category, geometry)

for (i in 1:length(ks.pwsid)){
  #for (i in 101:110){
  st_erase = all.in.out %>% filter(category == "blank")
  ks.sel <- ks.sys %>% filter(pwsid==ks.pwsid[i])
  intmunis <- st_intersection(ks.sel, ks.muni)
  
  if(dim(intmunis)[1] > 0){
    intmunis$muniArea = st_area(intmunis$geometry)
    inside <- st_union(intmunis) %>% st_sf() 
    
    st_erase = st_difference(ks.sel, inside) %>% mutate(category = "outside") %>% select(pwsid, gis_name, category, geometry)
    st_erase$area = st_area(st_erase$geometry)
    st_erase <- st_cast(st_erase); 
    
    if(dim(st_erase)[1] > 0) {
      st_union <- inside %>% mutate(pwsid = ks.pwsid[i], gis_name = ks.sel$gis_name[1], category = "inside") %>% select(pwsid, gis_name, category, geometry)
      st_union$area = st_area(st_union$geometry)
      
      in.out = rbind(st_erase, st_union) %>% select(pwsid, gis_name, category, geometry)
      perOut = 100*(as.numeric(st_erase$area)/(as.numeric(st_erase$area) + as.numeric(st_union$area)))
      
      #if outside area is less than 1%, just make all inside
      if(perOut <= 1){
        in.out = ks.sel %>% mutate(category="inside") %>% select(pwsid, gis_name, category, geometry)
      }
    }
  }
  if(dim(st_erase)[1] == 0) {
    in.out = ks.sel %>% mutate(category="inside") %>% select(pwsid, gis_name, category, geometry)
  }
  
  if(dim(intmunis)[1] == 0){
    in.out = ks.sel %>% mutate(category="inside") %>% select(pwsid, gis_name, category, geometry)
  }
  
  #rbind to a full database
  all.in.out <- rbind(all.in.out, in.out)
  print(i)
}
table(all.in.out$category)
summary(all.in.out)

geojson_write(all.in.out, file = paste0(swd_data, "ks_in_out_systems.geojson"))

leaflet() %>% addProviderTiles("Stamen.TonerLite") %>% 
  addPolygons(data = all.in.out %>% filter(pwsid %in% ks.pwsid),
              fillOpacity= 0.6,  fillColor = ifelse(subset(all.in.out, pwsid %in% ks.pwsid)$category=="inside", "blue", "red"), #make sure matches data
              color="blue",  weight=1,
              popup=~paste0("pwsid: ", pwsid)) 

rm(all.in.out, ks.sel, ks.sys, intmunis, st_erase, st_union, ks.muni, ks.rates, ks.pwsid, in.out, perOut, inside)





###################################################################################################################################################################
#
# (1) UPDATE UTILITY SPATIAL BOUNDARIES OR ADD NEW STATES: WA
#
####################################################################################################################################################################
#https://www.doh.wa.gov/DataandStatisticalReports/DataSystems/GeographicInformationSystem/DownloadableDataSets
#https://fortress.wa.gov/doh/base/gis/ServiceAreas.zip
# Download the shapefile. (note that I store it in a folder called DATA. You have to change that if needed.)
download.file("https://fortress.wa.gov/doh/base/gis/ServiceAreas.zip" , destfile="C://Users//lap19//Downloads//ServiceAreas.zip")
# You now have it in your current working directory, have a look!
# Unzip this file. You can do it with R (as below), or clicking on the object you downloaded.
wa.sys <- readOGR("C://Users//lap19//Documents//WaterUtilities//UtilityData//WA", "wa_systems")
wa.sys <- spTransform(wa.sys, CRS("+init=epsg:4326")) %>% st_as_sf()
wa.sys <- wa.sys %>% select(WS_Name, WS_ID, OwnerID, Total_Conn, WS_Status, WS_Type)
#st_geometry(wa.sys) <- NULL;
#write.csv(wa.sys, "new_states/wa_systems_match_all.csv")

#washington does not have pwsid's. Manually linked rates pwsid to values in this shapefile and municipal shapefile. Then merged together.
wa.muni <- muni %>% filter(state=="wa")
wa.rates <- read_excel(paste0(swd_data, "rates_data\\rates_wa.xlsx"), sheet="PWSID_to_Shapefile")
wa.sys2 <- merge(wa.sys, wa.rates, by.x="WS_ID", by.y="WS_ID") %>% select(pwsid, service_area, geometry)
wa.sys3 <- merge(wa.muni, wa.rates, by.x="city_name", by.y="MUNI_Name") %>% select(pwsid, service_area, geometry)

wa.sys <- rbind(wa.sys2, wa.sys3)
#group duplicates
wa.sys <- wa.sys %>% group_by(pwsid, service_area) %>% summarize(n=n())
#clark public utilities is duplicated with Clark Public - Utilities - Amboy
wa.sys <- wa.sys %>% select(-n) %>% filter(pwsid != "WA5304625") %>% rename(gis_name = service_area)

if (FALSE %in% st_is_valid(wa.sys)) {wa.sys <- suppressWarnings(st_buffer(wa.sys[!is.na(st_is_valid(wa.sys)),], 0.0)); print("fixed")}#fix corrupt shapefiles
geojson_write(wa.sys, file=paste0(swd_data, "wa_systems.geojson"))

#fix corrupt shapfiles
wa.muni$geometry <- wa.muni$geometry %>% s2::s2_rebuild() %>% sf::st_as_sfc()
if (FALSE %in% st_is_valid(wa.muni)) {wa.muni <- suppressWarnings(st_buffer(wa.muni[!is.na(st_is_valid(wa.muni)),], 0.0)); print("fixed")}#fix corrupt shapefiles
wa.rates <- read_excel(paste0(swd_data, "rates_data//rates_wa.xlsx"), sheet="rateTable") %>% filter(other_class=="inside_outside")

#set up loop
wa.rates <- wa.rates %>% filter(pwsid %in% wa.sys$pwsid); #only keep those that are in the shapefiel
wa.pwsid <- unique(wa.rates$pwsid)
all.in.out <- wa.sys %>% filter(pwsid %notin% wa.pwsid) %>% mutate(category = "inside") %>% select(pwsid, gis_name, category, geometry)

for (i in 1:length(wa.pwsid)){
  #for (i in 101:110){
  st_erase = all.in.out %>% filter(category == "blank")
  wa.sel <- wa.sys %>% filter(pwsid==wa.pwsid[i])
  intmunis <- st_intersection(wa.sel, wa.muni)
  
  if(dim(intmunis)[1] > 0){
    intmunis$muniArea = st_area(intmunis$geometry)
    inside <- st_union(intmunis) %>% st_sf() 
    
    st_erase = st_difference(wa.sel, inside) %>% mutate(category = "outside") %>% select(pwsid, gis_name, category, geometry)
    st_erase$area = st_area(st_erase$geometry)
    st_erase <- st_cast(st_erase); 
    
    if(dim(st_erase)[1] > 0) {
      st_union <- inside %>% mutate(pwsid = wa.pwsid[i], gis_name = wa.sel$gis_name[1], category = "inside") %>% select(pwsid, gis_name, category, geometry)
      st_union$area = st_area(st_union$geometry)
      
      in.out = rbind(st_erase, st_union) %>% select(pwsid, gis_name, category, geometry)
      perOut = 100*(as.numeric(st_erase$area)/(as.numeric(st_erase$area) + as.numeric(st_union$area)))
      
      #if outside area is less than 1%, just make all inside
      if(perOut <= 1){
        in.out = wa.sel %>% mutate(category="inside") %>% select(pwsid, gis_name, category, geometry)
      }
    }
  }
  if(dim(st_erase)[1] == 0) {
    in.out = wa.sel %>% mutate(category="inside") %>% select(pwsid, gis_name, category, geometry)
  }
  
  if(dim(intmunis)[1] == 0){
    in.out = wa.sel %>% mutate(category="inside") %>% select(pwsid, gis_name, category, geometry)
  }
  
  #rbind to a full database
  all.in.out <- rbind(all.in.out, in.out)
  print(i)
}
table(all.in.out$category)
summary(all.in.out)

st_geometry_type(all.in.out)
#drop line geometry
all.in.out <- all.in.out %>% filter(st_geometry_type(all.in.out) != "LINESTRING")

geojson_write(all.in.out, file = paste0(swd_data, "wa_in_out_systems.geojson"))

leaflet() %>% addProviderTiles("Stamen.TonerLite") %>% 
  addPolygons(data = all.in.out %>% filter(pwsid %in% wa.pwsid),
              fillOpacity= 0.6,  fillColor = ifelse(subset(all.in.out, pwsid %in% wa.pwsid)$category=="inside", "blue", "red"), #make sure matches data
              color="blue",  weight=1,
              popup=~paste0("pwsid: ", pwsid)) 

rm(all.in.out, wa.sel, wa.sys, intmunis, st_erase, st_union, wa.muni, wa.rates, wa.pwsid, wa.sys2, wa.sys3, in.out, perOut, inside)








