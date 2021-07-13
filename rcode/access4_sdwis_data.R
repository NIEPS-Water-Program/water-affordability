#######################################################################################################################################################
#
# Downloads and Updates EPA SDWIS data for utilities... useful for basic info about utility and making a list to build rates database
# CREATED BY LAUREN PATTERSON
# 2021
#
########################################################################################################################################################


######################################################################################################################################################################
#
#   CALL API FOR SYSTEMS
#
######################################################################################################################################################################
#THIS IS NEEDED TO GET DETAILS ABOUT SYSTEMS - SUCH AS OWNERSHIP AND SIZE
baseURL = 'https://data.epa.gov/efservice/WATER_SYSTEM/STATE_CODE/'
fileType = '/EXCEL'

# This is loads in the locations and the urls for other data accessible via web services
state.code <- toupper(state.list)
i=1
projectsURL = paste0(baseURL,state.code[i],fileType)
#projectsURL = paste0(baseURL,pwsidList[i],fileType)
df <- read.csv(url(projectsURL))

#convert all columns into characters instead of factors. Removes error in loop and converting variables to NA
df <- df %>% mutate_all(as.character)
#Loop through the rest of the states
for (i in 2:length(state.code)){
  projectsURL = paste0(baseURL,state.code[i],fileType)
  foo <- read.csv(url(projectsURL))
  foo <- foo %>% mutate_all(as.character)
  
  df <- rbind(df, foo)
  print(paste0("Percent Done: ", round(i/length(state.code)*100,2)))
}

#rename headers
df.headers <- gsub("^.*\\.","",colnames(df)); #remove "WATER_SYSTEM."
colnames(df) <- df.headers

df$PWSID_STATE <- tolower(substr(df$PWSID,0,2))

#remove columns that are not needed
df <- df %>% select(-c(ADMIN_NAME, EMAIL_ADDR, PHONE_NUMBER, ADDRESS_LINE1, ADDRESS_LINE2, POP_CAT_2_CODE, POP_CAT_3_CODE, POP_CAT_4_CODE, 
                               POP_CAT_5_CODE, POP_CAT_11_CODE, X, LT2_SCHEDULE_CAT_CODE, DBPR_SCHEDULE_CAT_CODE, FAX_NUMBER, PHONE_EXT_NUMBER, ALT_PHONE_NUMBER))

#limit to active systems
df2 <- df %>% filter(PWS_TYPE_CODE == "CWS") %>% filter(PWSID_STATE %in% state.list) %>% filter(PWS_ACTIVITY_CODE != "I")

#save out files by cws, NTNCWS and TNCWS
write.csv(df2, paste0(swd_data,"sdwis\\cws_systems.csv"), row.names = FALSE)
#################################################################################################################################################################################################################


rm(baseURL, fileType, state.code, projectsURL, df, foo, df2)


