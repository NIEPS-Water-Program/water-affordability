/*#######################################################################################################
                                    
                                    LOAD LARGE DATASETS

######################################################################################################-*/
//read in datasets
var utilityScores;
var utilityDetails;
var demData;
var blsData;
var selCSV; //filter once in drawMap() and call repeatedly... except not working
var selFeature;
var select_url;
var oldSystem = "none";

function getSystemData() {
    return $.getJSON("data/simple_water_systems.geojson", function (siteData) {
        gisSystemData = siteData;
    });
}
getSystemData();

// because asynchronous, have to call after function runs
//when javascript loads
function loadData(){
  d3.csv("data/utility_afford_scores.csv").then(function (dataCSV) {
        dataCSV.forEach(function (d) {
            d.HBI = +d.HBI;
            d.PPI = +d.PPI;
            d.TRAD = +d.TRAD;
            d.hh_use = +d.hh_use;
            d.LaborHrs = +d.LaborHrs;
            d.low = +d.low;
            d.low_mod = +d.low_mod;
            d.mod_high = +d.mod_high;
            d.high = +d.high;
            d.very_high = +d.very_high;
        });
        utilityScores = dataCSV;
        //console.log(utilityScores)
        return utilityScores;
    }); //end D3

  d3.csv("data/utility_descriptions.csv").then(function (detailsCSV) {
     utilityDetails = detailsCSV;
     selCSV = utilityDetails;
     setDropdownValues();
     //console.log(utilityDetails)
     return utilityDetails;
  });

    // DEMOGRAPHIC DATA NEXT
    //read in csv
    d3.csv("data/census_summary.csv").then(function (demCSV) {
        demCSV.forEach(function (d) {
            d.pop1990 = +d.pop1990;
            d.pop2000 = +d.pop2000;
            d.pop2010 = +d.pop2010;
            d.pop2018 = +d.cwsPop; //THIS ONE NEEDS TO HAVE LAST DATE UPDATED EACH YEAR
            d.under18 = +d.under18;
            d.age18to34 = +d.age18to34;
            d.age35to59 = +d.age35to59;
            d.age60to64 = +d.age60to64;
            d.over65 = +d.over65;
            d.Asian = +d.Asian;
            d.Black = +d.Black;
            d.Native = +d.Native;
            d.Other = +d.Other;
            d.Hispanic = +d.Hispanic;
            d.White = +d.White;
            d.d0to24k = +d.d0to24k;
            d.d25to49k = +d.d25to49k;
            d.d50to74k = +d.d50to74k;
            d.d75to100k = +d.d75to100k;
            d.d100to125k = +d.d100to125k;
            d.d125to150k = +d.d125to150k;
            d.d150kmore = +d.d150kmore;
            d.built_2010later = +d.built_2010later;
            d.built_2000to2009 = +d.built_2000to2009;
            d.built_1990to1999 = +d.built_1990to1999;
            d.built_1980to1989 = +d.built_1980to1989;
            d.built_1970to1979 = +d.built_1970to1979;
            d.built_1960to1969 = +d.built_1960to1969;
            d.built_1950to1959 = +d.built_1950to1959;
            d.built_1940to1949 = +d.built_1940to1949;
            d.built_1939early = +d.built_1939early;
        });
        demData = demCSV;
        return demCSV;
    }); //end d3

    d3.csv("data/bls_summary.csv").then(function (blsCSV) {
        blsCSV.forEach(function (d) {
            d.year = +d.year;
            d.unemploy_rate = +d.unemploy_rate;
        });
        blsData = blsCSV;
        return blsData;
    });
    //console.log(blsData)
    setTimeout(() => {
        plotDemographics(selectSystem)
    }, 500);
}//end load data function
loadData()  



