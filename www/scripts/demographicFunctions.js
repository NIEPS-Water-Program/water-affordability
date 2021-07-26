///////////////////////////////////////////////////////////////////////////////////////////////////
//
//                      DEMOGRAPHICS GRAPHIC SCRIPT                              ///////////////
////                   
///////////////////////////////////////////////////////////////////////////////////////////////////
//############################################################################################
// PLOT DATA USING UTILITY_RATES_TABLE_CURRENT
//############################################################################################
function plotDemographics(selectSystem) {
    //remove too small
    document.getElementById("tooSmall").innerHTML = "";

    document.getElementById("annualBLSTitle").innerHTML =
        "How has unemployment changed over time?";
    document.getElementById("monthBLSTitle").innerHTML =
        "How has COVID-19 affected unemployment?";
    //update title
    if (selectSystem === "none") {
        document.getElementById("popTimeTitle").innerHTML =
            "Is population growing, shrinking, or stable?";
        document.getElementById("ageTitle").innerHTML =
            "What percentage of customers are within working age?";
        document.getElementById("incomeTitle").innerHTML =
            "What is the household income distribution?";

        document.getElementById("monthBLSTitle").innerHTML =
            "How has COVID-19 affected unemployment?";
        document.getElementById("buildTitle").innerHTML =
            "When were houses built (infrastructure age)?";
    }

    var plotHeight = 250;

    //read in csv
    // d3.csv("data/all_utility_census_summary.csv").then(function (demCSV) {
    //     demCSV.forEach(function (d) {
    //         d.pop1990 = +d.pop1990;
    //         d.pop2000 = +d.pop2000;
    //         d.pop2010 = +d.pop2010;
    //         d.pop2018 = +d.cwsPop; //THIS ONE NEEDS TO HAVE LAST DATE UPDATED EACH YEAR
    //         d.under18 = +d.under18;
    //         d.age18to34 = +d.age18to34;
    //         d.age35to59 = +d.age35to59;
    //         d.age60to64 = +d.age60to64;
    //         d.over65 = +d.over65;
    //         d.Asian = +d.Asian;
    //         d.Black = +d.Black;
    //         d.Native = +d.Native;
    //         d.Other = +d.Other;
    //         d.Hispanic = +d.Hispanic;
    //         d.White = +d.White;
    //         d.d0to24k = +d.d0to24k;
    //         d.d25to49k = +d.d25to49k;
    //         d.d50to74k = +d.d50to74k;
    //         d.d75to100k = +d.d75to100k;
    //         d.d100to125k = +d.d100to125k;
    //         d.d125to150k = +d.d125to150k;
    //         d.d150kmore = +d.d150kmore;
    //         d.built_2010later = +d.built_2010later;
    //         d.built_2000to2009 = +d.built_2000to2009;
    //         d.built_1990to1999 = +d.built_1990to1999;
    //         d.built_1980to1989 = +d.built_1980to1989;
    //         d.built_1970to1979 = +d.built_1970to1979;
    //         d.built_1960to1969 = +d.built_1960to1969;
    //         d.built_1950to1959 = +d.built_1950to1959;
    //         d.built_1940to1949 = +d.built_1940to1949;
    //         d.built_1939early = +d.built_1939early;
    //     });

        //filter demCSV and only keep those have enough data
        demCSV = demData.filter(function (d) {
            return d.keep === "keep";
        });

        var selSystem = demData.filter(function (d) {
            return d.pwsid === selectSystem && d.keep === "keep";
        });

        //continue to filter based on selection
        // if (selectState !== "none") {
        //     selCSV = selCSV.filter(function (d) {
        //         return d.state === selectState;
        //     });
        // }
        // if (selectSize !== "none") {
        //     selCSV = selCSV.filter(function (d) {
        //         return d.sizeCategory === selectSize;
        //     });
        // }
        // if (selectOwner !== "none") {
        //     selCSV = selCSV.filter(function (d) {
        //         return d.owner_type === selectOwner;
        //     });
        // }
        //console.log(selCSV)

        demCSV = demCSV.filter(el => {
            return selCSV.find(element => {
               return element.pwsid === el.pwsid;
            });
         });
         //console.log(demCSV);
         
         //pull out details of selected system
         selSystemDetails = utilityDetails.filter(function (d){
             return d.pwsid === oldSystem;   //selectSystem; Need to use old system if change characteristics don't match
         });
         

    //if not enough data - leave a message saying so and pop out of the function
        if ((selectSystem !== "none") & (selSystem.length === 0)) {
            document.getElementById("tooSmall").innerHTML =
                "This system was too small to estimate census characteristics";
            document.getElementById("popTimeTitle").innerHTML =
                "Is population growing, shrinking, or stable?";
            document.getElementById("ageTitle").innerHTML =
                "What percentage of customers are within working age?";
            document.getElementById("incomeTitle").innerHTML =
                "What is the household income distribution?";

            document.getElementById("monthBLSTitle").innerHTML =
                "How has COVID-19 affected unemployment?";
            document.getElementById("buildTitle").innerHTML =
                "When were houses built (infrastructure age)?";
        }

        //###########################################################################################################################
        //                          POPULATION OVER TIME
        //###########################################################################################################################
        //popoverTime
        var maxPop;
        if ((selectSystem !== "none") & (selSystem.length > 0)) {
            maxPop = selSystem[0].pop2018 * 1.5;
            var perChange =
                Math.round(
                    (selSystem[0].pop2018 / selSystem[0].pop1990) * 100 * 10
                ) / 10;
            var direction;
            if (perChange >= 105) {
                direction = " has grown to ";
            }
            if (perChange <= 95) {
                direction = " has shrunk to ";
            }
            if (perChange > 95 && perChange < 105) {
                direction = " has stayed at  ";
            }

            //redo title
            document.getElementById("popTimeTitle").innerHTML =
                selSystemDetails[0].service_area +
                direction +
                perChange +
                "% of 1990 population";
        } //end if selected

        if ((selectSystem === "none") | (selSystem.length === 0)) {
            pop2018all = demCSV.map(function (d) {
                return d.pop2018;
            });
            maxPop = Math.max(pop2018all) * 1.5;
        }

        //PLOTLY BAR CHART OF RATES
        // create all traces
        pwsidAll = demCSV.map(function (d) {
            return d.pwsid;
        });

        //set up variables
        //pop
        var yAll = [];
        var dataPop = [];
        var xYear = [1990, 2000, 2010, Number(currentYear)];
        var allTrace;
        //age
        var dataAge = [];
        var allTrace2;
        var yAll2 = [];
        //race
        var dataRace = [];
        var allTrace3;
        var yAll3 = [];
        //income
        var dataIncome = [];
        var allTrace4;
        var yAll4 = [];
        //building age
        var dataBuild = [];
        var allTrace5;
        var yAll5 = [];

        // loop through and create variables and traces
        for (i = 0; i < pwsidAll.length; i++) {
            tempSelect = pwsidAll[i];
            temp = demCSV.filter(function (d) {
                return d.pwsid === tempSelect;
            });

            //populations-------------------
            yAll = [
                temp[0].pop1990,
                temp[0].pop2000,
                temp[0].pop2010,
                temp[0].pop2018,
            ];
            allTrace = {
                x: xYear,
                y: yAll,
                mode: "lines",
                type: "scatter",
                hoverinfo: "skip",
                opacity: 0.3,
                line: { color: "#c5c5c5", width: 1 },
            };
            dataPop.push(allTrace); //----------------------

            //age ------------------------------------------
            yAll2 = [
                temp[0].under18,
                temp[0].age18to34,
                temp[0].age35to59,
                temp[0].age60to64,
                temp[0].over65,
            ];
            //create individual trace
            allTrace2 = {
                y: [
                    "children <br> (under 18)",
                    "working age <br> (18 to 34)",
                    "working age <br> (35 to 59)",
                    "near retirement <br> (60-64)",
                    "retirement age <br> (over 65)",
                ],
                x: yAll2,
                type: "scatter",
                mode: "lines",
                opacity: 0.3,
                hoverinfo: "skip",
                line: { color: "#c5c5c5" },
            };
            dataAge.push(allTrace2); //--------------------------------------

            //race---------------------------------------------------
            yAll3 = [
                temp[0].Other,
                temp[0].White,
                temp[0].Native,
                temp[0].Black,
                temp[0].Asian,
                temp[0].Hispanic,
            ];
            allTrace3 = {
                y: [
                    "Other ",
                    "White ",
                    "Native ",
                    "Black ",
                    "Asian ",
                    "Hispanic ",
                ],
                x: yAll3,
                type: "box",
                orientation: "h",
                //type: 'scatter', mode: 'lines',
                opacity: 0.3,
                hoverinfo: "skip",
                line: { color: "#c5c5c5" },
            };
            dataRace.push(allTrace3); //-------------------------------------------------

            //income ------------------------------------------------------------------------------
            yAll4 = [
                temp[0].d0to24k,
                temp[0].d25to49k,
                temp[0].d50to74k,
                temp[0].d75to100k,
                temp[0].d100to125k,
                temp[0].d125to150k,
                temp[0].d150kmore,
            ];
            allTrace4 = {
                x: [
                    "$0-<br>24k",
                    "$25-<br>49k",
                    "$50-<br>74k",
                    "$75-<br>99k",
                    "$100-<br>124k",
                    "$125-<br>149k",
                    ">$150k",
                ],
                y: yAll4,
                type: "scatter",
                mode: "lines",
                opacity: 0.3,
                hoverinfo: "skip",
                line: { color: "#c5c5c5" },
            };
            dataIncome.push(allTrace4);

            //build age ------------------------------------------------------------------------------
            yAll5 = [
                temp[0].built_1939early,
                temp[0].built_1940to1949,
                temp[0].built_1950to1959,
                temp[0].built_1960to1969,
                temp[0].built_1970to1979,
                temp[0].built_1980to1989,
                temp[0].built_1990to1999,
                temp[0].built_2000to2009,
                temp[0].built_2010later,
            ];
            allTrace5 = {
                x: [
                    "<1939",
                    "1940-<br>1949",
                    "1950-<br>1959",
                    "1960-<br>1969",
                    "1970-<br>1979",
                    "1980-<br>1989",
                    "1990-<br>1999",
                    "2000-<br>2009",
                    ">2010",
                ],
                y: yAll5,
                type: "scatter",
                mode: "lines",
                opacity: 0.3,
                hoverinfo: "skip",
                line: { color: "#c5c5c5" },
            };
            dataBuild.push(allTrace5);
        } // end for loop

        //####################################### POPULATION #############################################
        if (selectSystem !== "none" && selSystem.length > 0) {
            //selectBurden !== "Unknown" |
            var popTrace = {
                x: [1990, 2000, 2010, Number(currentYear)],
                y: [
                    selSystem[0].pop1990,
                    selSystem[0].pop2000,
                    selSystem[0].pop2010,
                    selSystem[0].pop2018,
                ],
                type: "scatter",
                mode: "lines+markers",
                text: selectSystem,
                name: "selected<br>utility",
                marker: {
                    color: "#00578a",
                    size: 10,
                    line: { color: "black", width: 2 },
                },
                line: { color: "black", width: 2 },
                hovertemplate:
                    "Population: " + numberWithCommas("%{y}") + " in %{x}",
            };
            dataPop.push(popTrace);
        } //

        var layoutPop = {
            yaxis: {
                title: "Population",
                titlefont: { color: "rgb(0, 0, 0)", size: 13 },
                tickfont: { color: "rgb(0, 0, 0)", size: 11 },
                showline: false,
                showgrid: true,
                showticklabels: true,
                range: [0, maxPop],
            },
            xaxis: {
                showline: false,
                showgrid: false,
                showticklabels: true,
                title: "",
                titlefont: { color: "rgb(0, 0, 0)", size: 13 },
                tickfont: { color: "rgb(0, 0, 0)", size: 11 },
            },
            height: plotHeight,
            showlegend: false,
            // legend: {x: 0, y: 0, xanchor: 'left', orientation: "h" },
            margin: { t: 30, b: 40, r: 30, l: 50 },
        };

        Plotly.newPlot("popTimeChart", dataPop, layoutPop, configNoAutoDisplay);
        //###########################################################################################################################

        //###########################################################################################################################
        //                          AGE BREAKOUT OVER TIME
        //###########################################################################################################################
        if (selectSystem !== "none" && selSystem.length > 0) {
            var working =
                selSystem[0].age18to34 +
                selSystem[0].age35to59 +
                selSystem[0].age60to64;
            document.getElementById("ageTitle").innerHTML =
                Math.round(working) +
                "% of " +
                selSystemDetails[0].service_area +
                " population is within working age";

            ageColor = ["#8a3300", "#00578a", "#00578a", "#cd8536", "#8a3300"];
            var ageTrace = {
                x: [
                    selSystem[0].under18.toFixed(1),
                    selSystem[0].age18to34.toFixed(1),
                    selSystem[0].age35to59.toFixed(1),
                    selSystem[0].age60to64.toFixed(1),
                    selSystem[0].over65.toFixed(1),
                ],
                y: [
                    "children <br> (under 18)",
                    "working age <br> (18 to 34)",
                    "working age <br> (35 to 59)",
                    "near retirement <br> (60-64)",
                    "retirement age <br> (over 65)",
                ],
                //type: "bar",
                type: "scatter",
                mode: "lines+markers",
                name: "selected<br>utility",
                marker: {
                    color: ageColor,
                    size: 12,
                    line: { color: "black", width: 2 },
                },
                line: { color: "black", width: 2 },
                hovertemplate: "%{x}% of population %{y}",
            };
            dataAge.push(ageTrace);
        } //end if

        var layoutAge = {
            yaxis: {
                title: "",
                titlefont: { color: "rgb(0, 0, 0)", size: 13 },
                tickfont: { color: "rgb(0, 0, 0)", size: 11 },
                showline: false,
                showgrid: false,
                showticklabels: true,
            },
            xaxis: {
                showline: false,
                showgrid: true,
                showticklabels: true,
                title: "Percent of Population (%)",
                titlefont: { color: "rgb(0, 0, 0)", size: 13 },
                tickfont: { color: "rgb(0, 0, 0)", size: 11 },
                range: [0, 80],
            },
            height: plotHeight,
            showlegend: false,
            margin: { t: 30, b: 40, r: 40, l: 100 },
        };
        Plotly.newPlot("ageChart", dataAge, layoutAge, configNoAutoDisplay);

        //###########################################################################################################################
        //                          RACIAL BREAKOUT OVER TIME
        //###########################################################################################################################
        //PLOTLY BAR CHART OF RATES
        if (selectSystem !== "none" && selSystem.length > 0) {
            raceColor = [
                "#00578a",
                "#00578a",
                "#00578a",
                "#00578a",
                "#00578a",
                "#8a3300",
            ];
            var raceTrace = {
                x: [
                    selSystem[0].Other.toFixed(1),
                    selSystem[0].White.toFixed(1),
                    selSystem[0].Native.toFixed(1),
                    selSystem[0].Black.toFixed(1),
                    selSystem[0].Asian.toFixed(1),
                    selSystem[0].Hispanic.toFixed(1),
                ],
                y: [
                    "Other ",
                    "White ",
                    "Native ",
                    "Black ",
                    "Asian ",
                    "Hispanic ",
                ],
                type: "scatter",
                mode: "markers",
                name: "selected<br>utility",
                hovertemplate: "%{x}% of population<br>identified as %{y}",
                marker: {
                    color: raceColor,
                    size: 12,
                    line: { color: "black", width: 2 },
                },
            };
            dataRace.push(raceTrace);
            //console.log("race = ", selSystem[0].Other + selSystem[0].White + selSystem[0].Native + selSystem[0].Hispanic + selSystem[0].Black + selSystem[0].Asian)
        } //end if

        var layoutRace = {
            yaxis: {
                title: "",
                titlefont: { color: "rgb(0, 0, 0)", size: 13 },
                tickfont: { color: "rgb(0, 0, 0)", size: 11 },
                showline: false,
                showgrid: true,
                showticklabels: true,
            },
            xaxis: {
                showline: false,
                showgrid: false,
                showticklabels: true,
                title: "Percent of Population (%)",
                titlefont: { color: "rgb(0, 0, 0)", size: 13 },
                tickfont: { color: "rgb(0, 0, 0)", size: 11 },
                range: [0, 100],
            },
            height: plotHeight,
            showlegend: false,
            margin: { t: 30, b: 30, r: 40, l: 70 },
        };

        Plotly.newPlot("raceChart", dataRace, layoutRace, configNoAutoDisplay);

        //###########################################################################################################################
        //                          INCOME BREAKOUT OVER TIME
        //###########################################################################################################################
        if (selectSystem !== "none" && selSystem.length > 0) {
            //var morethan75 = selSystem[0].d75to100k + selSystem[0].d100to125k + selSystem[0].d125to150k + selSystem[0].d150kmore;
            var lessthan75 =
                100 -
                (selSystem[0].d75to100k +
                    selSystem[0].d100to125k +
                    selSystem[0].d125to150k +
                    selSystem[0].d150kmore);
            document.getElementById("incomeTitle").innerHTML =
                Math.round(lessthan75) +
                "% of " +
                selSystemDetails[0].service_area +
                " households earn less than $75,000";

            var incomeTrace = {
                y: [
                    selSystem[0].d0to24k.toFixed(1),
                    selSystem[0].d25to49k.toFixed(1),
                    selSystem[0].d50to74k.toFixed(1),
                    selSystem[0].d75to100k.toFixed(1),
                    selSystem[0].d100to125k.toFixed(1),
                    selSystem[0].d125to150k.toFixed(1),
                    selSystem[0].d150kmore.toFixed(1),
                ],
                x: [
                    "$0-<br>24k",
                    "$25-<br>49k",
                    "$50-<br>74k",
                    "$75-<br>99k",
                    "$100-<br>124k",
                    "$125-<br>149k",
                    ">$150k",
                ],
                text: [
                    "less than $24k",
                    "$25k to $49k",
                    "$50k to $74k",
                    "$75k to $99k",
                    "$100k to $124k",
                    "$125k to $149k",
                    "more than $150k",
                ],
                //type: "bar",
                type: "scatter",
                mode: "lines+markers",
                name: "selected<br>utility",
                marker: {
                    color: "#00578a",
                    size: 10,
                    line: { color: "black", width: 2 },
                },
                line: { color: "black", width: 2 },
                hovertemplate: "%{y}% of households<br>earn %{text}",
            };
            dataIncome.push(incomeTrace);
        } //end if

        var layoutIncome = {
            yaxis: {
                title: "Percent Households (%)",
                titlefont: { color: "rgb(0, 0, 0)", size: 13 },
                tickfont: { color: "rgb(0, 0, 0)", size: 11 },
                showline: false,
                showgrid: true,
                showticklabels: true,
                range: [0, 50],
            },
            xaxis: {
                showline: false,
                showgrid: false,
                showticklabels: true,
                title: "Income Range",
                titlefont: { color: "rgb(0, 0, 0)", size: 13 },
                tickfont: { color: "rgb(0, 0, 0)", size: 11 },
                bargap: 0,
            },
            height: plotHeight,
            showlegend: false,
            margin: { t: 30, b: 45, r: 40, l: 35 },
        };

        Plotly.newPlot(
            "incomeChart",
            dataIncome,
            layoutIncome,
            configNoAutoDisplay
        );

        //###########################################################################################################################
        //                          BUILDING AGE BREAKOUT OVER TIME
        //###########################################################################################################################
        if (selectSystem !== "none" && selSystem.length > 0) {
            //console.log(selSystem);
            var olderthan70 =
                selSystem[0].built_1940to1949 + selSystem[0].built_1939early;
            var olderthan30 =
                selSystem[0].built_1990to1999 +
                selSystem[0].built_2000to2009 +
                selSystem[0].built_2010later;
            //console.log("Total Building: " + olderthan30 + olderthan70 + selSystem[0].built_1950to1959 + selSystem[0].built_1960to1969 +
            // selSystem[0].built_1970to1979 + selSystem[0].built_1980to1989);
            document.getElementById("buildTitle").innerHTML =
                Math.round(olderthan70) +
                "% of " +
                selSystemDetails[0].service_area +
                " households are more than 70 years old (pre-1950) and " +
                Math.round(100 - olderthan30) +
                "% are more than 30 years old (pre-1990)";

            var buildTrace = {
                y: [
                    selSystem[0].built_1939early.toFixed(1),
                    selSystem[0].built_1940to1949.toFixed(1),
                    selSystem[0].built_1950to1959.toFixed(1),
                    selSystem[0].built_1960to1969.toFixed(1),
                    selSystem[0].built_1970to1979.toFixed(1),
                    selSystem[0].built_1980to1989.toFixed(1),
                    selSystem[0].built_1990to1999.toFixed(1),
                    selSystem[0].built_2000to2009.toFixed(1),
                    selSystem[0].built_2010later.toFixed(1),
                ],
                x: [
                    "<1939",
                    "1940-<br>1949",
                    "1950-<br>1959",
                    "1960-<br>1969",
                    "1970-<br>1979",
                    "1980-<br>1989",
                    "1990-<br>1999",
                    "2000-<br>2009",
                    ">2010",
                ],
                text: [
                    "before 1939",
                    "1940 to 1949",
                    "1950 to 1959",
                    "1960 to 1969",
                    "1970 to 1979",
                    "1980 to 1989",
                    "1990 to 1999",
                    "2000 to 2009",
                    ">2010",
                ],
                //type: "bar",
                type: "scatter",
                mode: "lines+markers",
                name: "selected<br>utility",
                marker: {
                    color: "#00578a",
                    size: 10,
                    line: { color: "black", width: 2 },
                },
                line: { color: "black", width: 2 },
                hovertemplate: "%{y}% of households<br>built %{text}",
            };
            dataBuild.push(buildTrace);
        } //end if

        var layoutBuild = {
            yaxis: {
                title: "Percent Households (%)",
                titlefont: { color: "rgb(0, 0, 0)", size: 13 },
                tickfont: { color: "rgb(0, 0, 0)", size: 11 },
                showline: false,
                showgrid: true,
                showticklabels: true,
                range: [0, 60],
            },
            xaxis: {
                showline: false,
                showgrid: false,
                showticklabels: true,
                title: "Decade Households Built",
                titlefont: { color: "rgb(0, 0, 0)", size: 12 },
                tickfont: { color: "rgb(0, 0, 0)", size: 10 },
                bargap: 0,
            },
            height: plotHeight,
            showlegend: false,
            margin: { t: 15, b: 50, r: 40, l: 35 },
        };

        Plotly.newPlot(
            "buildChart",
            dataBuild,
            layoutBuild,
            configNoAutoDisplay
        );
    //}); //endD3

    //########################################################################
    //Unemployment data - call in variable blsCSV
        var yAllBLS = [];        var allBLSTrace;
        var xAll;                var dataBLS = [];
        
        // loop through and create variables and traces
        //as long as loop through same pwsidAll list as above, I don't need to add state, owner, etc.
        for (i = 0; i < pwsidAll.length; i++) {
            tempSelect = pwsidAll[i];
            temp = blsData.filter(function (d) {
                return d.pwsid === tempSelect;
            });

            xAll = temp.map(function (d) {
                return d.year;
            });
            yAllBLS = temp.map(function (d) {
                return d.unemploy_rate;
            });
            allBLSTrace = {
                x: xAll,
                y: yAllBLS,
                mode: "lines",
                type: "scatter",
                hoverinfo: "skip",
                opacity: 0.3,
                line: { color: "#c5c5c5", width: 1 },
            };
            dataBLS.push(allBLSTrace); //----------------------
        } //end for loop

        if (selectSystem !== "none") {
            var selSystem2 = blsData.filter(function (d) {
                return d.pwsid === selectSystem;
            });
            var xYear = selSystem2.map(function (d) {
                return d.year;
            });
            var yRate = selSystem2.map(function (d) {
                return d.unemploy_rate.toFixed(1);
            });

            var blsTrace = {
                x: xYear,
                y: yRate,
                type: "scatter",
                mode: "lines",
                name: "selected<br>utility",
                text: selectSystem,
                marker: { color: "#00578a" },
                hovertemplate: "%{y}% unemployed in %{x}",
            };
            dataBLS.push(blsTrace);
        } //end if

        //PLOTLY BAR CHART OF RATES
        var layoutBLS = {
            yaxis: {
                title: "Unemployment Rate (%)",
                titlefont: { color: "rgb(0, 0, 0)", size: 13 },
                tickfont: { color: "rgb(0, 0, 0)", size: 11 },
                showline: false,
                showgrid: true,
                showticklabels: true,
                range: [0, 30],
            },
            xaxis: {
                showline: false,
                showgrid: false,
                showticklabels: true,
                title: "",
                titlefont: { color: "rgb(0, 0, 0)", size: 13 },
                tickfont: { color: "rgb(0, 0, 0)", size: 11 },
            },
            height: plotHeight,
            showlegend: false,
            margin: { t: 30, b: 40, r: 30, l: 50 },
        };

        Plotly.newPlot(
            "annualBLSChart",
            dataBLS,
            layoutBLS,
            configNoAutoDisplay
        );
//    }); end d3

    //read in csv #############################################################################
    var parseDate = d3.timeParse("%Y-%m-%d");
    if (selectSystem === "none") {
        document.getElementById("monthBLSChart").innerHTML = "Select a system";
    }
    d3.csv("data/bls_monthly.csv").then(function (blsCSV2) {
        blsCSV2.forEach(function (d) {
            //d.date = parseDate(d.date);
            d.unemploy_rate = +d.unemploy_rate;
        });

        var selSystem3 = blsCSV2.filter(function (d) {
            return d.pwsid === selectSystem;
        });
        var xMonth = selSystem3.map(function (d) {
            return d.date;
        });
        var yRate2 = selSystem3.map(function (d) {
            return d.unemploy_rate.toFixed(1);
        });

        //PLOTLY BAR CHART OF RATES
        var blsTrace2 = {
            x: xMonth,
            y: yRate2,
            type: "bar",
            name: "",
            //type: "scatter", mode: "lines",
            marker: { color: "#00578a" },
            hovertemplate: "%{y}% unemployed in %{x}",
        };

        //console.log(blsTrace2);
        var layoutBLS = {
            yaxis: {
                title: "Unemployment Rate (%)",
                titlefont: { color: "rgb(0, 0, 0)", size: 13 },
                tickfont: { color: "rgb(0, 0, 0)", size: 11 },
                showline: false,
                showgrid: true,
                showticklabels: true,
                range: [0, 30],
            },
            xaxis: {
                showline: false,
                showgrid: false,
                showticklabels: true,
                title: "",
                titlefont: { color: "rgb(0, 0, 0)", size: 13 },
                tickfont: { color: "rgb(0, 0, 0)", size: 11 },
                tickformat: "%b-%Y",
                //range: [parseDate("2020-01-01"), parseDate("2020-04-01")]
            },
            height: plotHeight,
            showlegend: false,
            // legend: {x: 0, y: 0, xanchor: 'left', orientation: "h" },
            margin: { t: 30, b: 40, r: 40, l: 50 },

            shapes: [
                {
                    type: "line",
                    xref: "x",
                    yref: "y",
                    x0: parseDate("2020-03-01"),
                    y0: 0,
                    x1: parseDate("2020-03-01"),
                    y1: 30, //date is march 11 but way box draws it - make earlier
                    //x0: "Mar 2020", y0: 0, x1: "Mar 2020", y1: 30,
                    line: { width: 1, color: "black", dash: "dashdot" },
                    layer: "below", // draws layer below trace
                },
            ],

            annotations: [
                {
                    xref: "x",
                    yref: "y", //ref is assigned to x values
                    x: parseDate("2020-03-01"),
                    y: 20,
                    //x: "Mar 2020", y: 20,
                    xanchor: "left",
                    yanchor: "bottom",
                    text: "Global Pandemic <br> (March 11)",
                    font: { family: "verdana", size: 11, color: "black" },
                    showarrow: false,
                },
            ],
        };

        dataBLS2 = [blsTrace2];
        if (selectSystem !== "none") {
            document.getElementById("monthBLSChart").innerHTML = "";
            Plotly.newPlot(
                "monthBLSChart",
                dataBLS2,
                layoutBLS,
                configNoAutoDisplay
            );
        }
    });
} // end function
