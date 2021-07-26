///////////////////////////////////////////////////////////////////////////////////////////////////
//
//                      SUMMARIZE RESULTS BY VOLUME SCRIPT                               ///////////////
////                   
///////////////////////////////////////////////////////////////////////////////////////////////////

function createSummary() {
//read in csv 
//filter by map selections
dataCSV = utilityScores.filter(el => {
  return selCSV.find(element => { return element.pwsid === el.pwsid; });
});


var xVolume = [0,1000,2000,3000,4000,5000, 6000, 7000, 8000, 9000, 10000,  11000, 12000, 13000, 14000, 15000, 16000];
var yLow = []; var yLowMod = []; var yModHigh = []; var yHigh = []; var yVHigh = [];

var totalSystems = dataCSV.filter(function(d){return d.hh_use===4000; }).length;

var colorVLow = "#007aa5"; var colorLow = "#99badd"; var colorMod = "#e4d00a"; 
var colorHigh = "#ed9121"; var colorVHigh = "#b31b1b";


for (i=0; i < xVolume.length; i++){
  var temp = dataCSV.filter(function(d){ return d.burden === "Low" && d.hh_use === xVolume[i]; });
  yLow.push((temp.length/totalSystems*100).toFixed(1));

  temp = dataCSV.filter(function(d){ return d.burden === "Low-Moderate" && d.hh_use === xVolume[i]; });
  yLowMod.push((temp.length/totalSystems*100).toFixed(1));

  temp = dataCSV.filter(function(d){ return d.burden === "Moderate-High" && d.hh_use === xVolume[i]; });
  yModHigh.push((temp.length/totalSystems*100).toFixed(1));

  temp = dataCSV.filter(function(d){ return d.burden === "High" && d.hh_use === xVolume[i]; });
  yHigh.push((temp.length/totalSystems*100).toFixed(1));

  temp = dataCSV.filter(function(d){ return d.burden === "Very High" && d.hh_use === xVolume[i]; });
  yVHigh.push((temp.length/totalSystems*100).toFixed(1));

}

//create plotly trace
var lowTrace = {
  x: xVolume, y: yLow, name: "Low",
  type: 'bar',  marker: {color: "#3b80cd"},
  hovertemplate: '%{y}% of utilities have a Low<br>affordability burden at %{x} gallons'
};

var lowModTrace = {
  x: xVolume, y: yLowMod, name: "Low-Moderate",
  type: 'bar',  marker: {color: "#36bdcd"},
  hovertemplate: '%{y}% of utilities have a Low-Moderate<br>affordability burden at %{x} gallons'
};

var modHighTrace = {
  x: xVolume, y: yModHigh, name: "Moderate-High",
  type: 'bar',  marker: {color: "#cd8536"},
  hovertemplate: '%{y}% of utilities have a Moderate-High<br>affordability burden at %{x} gallons'
};

var highTrace = {
  x: xVolume, y: yHigh, name: "High",
  type: 'bar',  marker: {color: "#ea3119"},
  hovertemplate: '%{y}% of utilities have a High<br>affordability burden at %{x} gallons'
};

var vHighTrace = {
  x: xVolume, y: yVHigh, name: "Very High",
  type: 'bar',  marker: {color: "#71261c"},
  hovertemplate: '%{y}% of utilities have a Very High<br>affordability burden at %{x} gallons'
};


var layout = {
  barmode: 'stack',
    yaxis: {
        title: 'Percent of Utilities (%)',
        titlefont: {color: 'rgb(0, 0, 0)', size: 14 },
        tickfont: {color: 'rgb(0, 0, 0)', size: 12},
        showline: false,    showgrid: false,   showticklabels: true,
        range: [0, 100], 
    },
    xaxis: {
      showline: false,   showgrid: false,   showticklabels: true,
      title: 'Volume of water used (gallons)',
      titlefont: {color: 'rgb(0, 0, 0)', size: 14},
      tickfont: {color: 'rgb(0, 0, 0)', size: 12},
    },
    height: 350,
    showlegend: true,
    legend: {x: 1, xanchor: 'left', y: 1, 
              //orientation: "h", x:0, y:1, yanchor: 'bottom',
              bgcolor: 'rgba(255,255,255,0.7)', borderwidth: 0, bordercolor: 'gray',
              title: { text: '<b>Burden: </b>'}, font: {size: 10 }
            },
    margin: { t: 30,   b: 30,  r: 120,   l: 50  },
  };
//colors = c("#3b80cd","#36bdcd","#cd8536","#ea3119","#71261c")) %>% 
var data = [lowTrace, lowModTrace, modHighTrace, highTrace, vHighTrace];
Plotly.newPlot('summaryBurdenChart', data, layout, config);

//###################################################################################################
//          NOW LET US REPEAT BUT FOR HOUSEHOLD BURDEN INDICATOR ONLY                //
//###################################################################################################
var hbi2 = []; var hbi4 = []; var hbi7 = []; var hbi10 = []; var hbi20 = [];
for (i=0; i < xVolume.length; i++){
  temp = dataCSV.filter(function(d){ return d.HBI <= day1/2 && d.hh_use === xVolume[i]; });
  hbi2.push((temp.length/totalSystems*100).toFixed(1));

  temp = dataCSV.filter(function(d){ return d.HBI > day1/2 && d.HBI <= day1 && d.hh_use === xVolume[i]; });
  hbi4.push((temp.length/totalSystems*100).toFixed(1));

  temp = dataCSV.filter(function(d){ return d.HBI > day1 && d.HBI <= day1*2 && d.hh_use === xVolume[i]; });
  hbi7.push((temp.length/totalSystems*100).toFixed(1));

  temp = dataCSV.filter(function(d){ return d.HBI > day1*2 && d.HBI <= day1*3 && d.hh_use === xVolume[i]; });
  hbi10.push((temp.length/totalSystems*100).toFixed(1));

  temp = dataCSV.filter(function(d){ return d.HBI > day1*3 && d.hh_use === xVolume[i]; });
  hbi20.push((temp.length/totalSystems*100).toFixed(1));
}

//create plotly trace
var hbi2Trace = {
  x: xVolume, y: hbi2, name: "< 0.5 day",
  type: 'bar',  marker: {color: colorVLow},
  hovertemplate: '%{y}% of utilities serve low-income<br>households spending less than half a work day<br>each month at %{x} gallons'
};

var hbi4Trace = {
  x: xVolume, y: hbi4, name: "0.5-1 day",
  type: 'bar',  marker: {color: colorLow},
  hovertemplate: '%{y}% of utilities serve low-income<br>households spending 0.5 to 1 work days<br>each month at %{x} gallons'
};

var hbi7Trace = {
  x: xVolume, y: hbi7, name: "1.1-2 days",
  type: 'bar',  marker: {color: colorMod},
  hovertemplate: '%{y}% of utilities serve low-income<br>households spending 1.1 to 2 work days<br>each month at %{x} gallons'
};

var hbi10Trace = {
  x: xVolume, y: hbi10, name: "2.1-3 days",
  type: 'bar',  marker: {color: colorHigh},
  hovertemplate: '%{y}% of utilities serve low-income<br>households spending 2.1 to 3 work days<br>each month at %{x} gallons'
};

var hbi20Trace = {
  x: xVolume, y: hbi20, name: "> 3 days",
  type: 'bar',  marker: {color: colorVHigh},
  hovertemplate: '%{y}% of utilities serve low-income<br>households spending more than 3 work days<br>each month at %{x} gallons'
};


var layout2 = {
  barmode: 'stack',
    yaxis: {
        title: 'Percent of Utilities (%)',
        titlefont: {color: 'rgb(0, 0, 0)', size: 14 },
        tickfont: {color: 'rgb(0, 0, 0)', size: 12},
        showline: false,    showgrid: false,   showticklabels: true,
        range: [0, 100], 
    },
    xaxis: {
      showline: false,   showgrid: false,   showticklabels: true,
      title: 'Volume of water used (gallons)',
      titlefont: {color: 'rgb(0, 0, 0)', size: 14},
      tickfont: {color: 'rgb(0, 0, 0)', size: 12},
    },
    height: 350,
    showlegend: true,
    legend: { orientation: "h", x:0, y:1, yanchor: 'bottom',
              bgcolor: 'rgba(255,255,255,0.7)', borderwidth: 0, bordercolor: 'gray',
              title: { text: '<b>HB:</b>'}, font: {size: 10 }
            },
    margin: { t: 70,   b: 30,  r: 20,   l: 50  },
  };
var data2 = [hbi2Trace, hbi4Trace, hbi7Trace, hbi10Trace, hbi20Trace];
Plotly.newPlot('summaryHBIChart', data2, layout2, config);

//###################################################################################################
// PPI -----------------------------------------------------------------------///////////////
//###################################################################################################
var ppi10 = []; var ppi20 = []; var ppi35 = []; var ppi50 = []; var ppi100 = [];
for (i=0; i < xVolume.length; i++){
  temp = dataCSV.filter(function(d){ return d.PPI <=10 && d.hh_use === xVolume[i]; });
  ppi10.push((temp.length/totalSystems*100).toFixed(1));

  temp = dataCSV.filter(function(d){ return d.PPI > 10 && d.PPI <= 20 && d.hh_use === xVolume[i]; });
  ppi20.push((temp.length/totalSystems*100).toFixed(1));

  temp = dataCSV.filter(function(d){ return d.PPI > 20 && d.PPI <= 35 && d.hh_use === xVolume[i]; });
  ppi35.push((temp.length/totalSystems*100).toFixed(1));

  temp = dataCSV.filter(function(d){ return d.PPI > 35 && d.PPI <= 50 && d.hh_use === xVolume[i]; });
  ppi50.push((temp.length/totalSystems*100).toFixed(1));

  temp = dataCSV.filter(function(d){ return d.PPI > 50 && d.hh_use === xVolume[i]; });
  ppi100.push((temp.length/totalSystems*100).toFixed(1));
}

//create plotly trace
var ppi10Trace = {
  x: xVolume, y: ppi10, name: "0-10%",
  type:'bar', marker: {color: colorVLow},
  hovertemplate: '%{y}% of utilities serve a community with<br>with less than 10% of households below<br>200% of FPL at %{x} gallons'
};

var ppi20Trace = {
  x: xVolume, y: ppi20, name: "11-20%",
  type: 'bar',  marker: {color: colorLow},
  hovertemplate: '%{y}% of utilities serve a community with<br>10.1 to 20% of households below<br>200% of FPL at %{x} gallons'
};

var ppi35Trace = {
  x: xVolume, y: ppi35, name: "21-35%",
  type: 'bar',  marker: {color: colorMod},
  hovertemplate: '%{y}% of utilities serve a community with<br>20.1 to 35% of households below<br>200% of FPL at %{x} gallons'
};

var ppi50Trace = {
  x: xVolume, y: ppi50, name: "36-50%",
  type: 'bar',  marker: {color: colorHigh},
  hovertemplate: '%{y}% of utilities serve a community with <br>35.1 to 50% of households below<br>200% of FPL at %{x} gallons'
};

var ppi100Trace = {
  x: xVolume, y: ppi100, name: ">50%",
  type: 'bar',  marker: {color: colorVHigh},
  hovertemplate: '%{y}% of utilities serve a community with<br>more than 50% of households below<br>200% of FPL at %{x} gallons'
};


var layout3 = {
  barmode: 'stack',
    yaxis: {
        title: 'Percent of Utilities (%)',
        titlefont: {color: 'rgb(0, 0, 0)', size: 14 },
        tickfont: {color: 'rgb(0, 0, 0)', size: 12},
        showline: false,    showgrid: false,   showticklabels: true,
        range: [0, 100], 
    },
    xaxis: {
      showline: false,   showgrid: false,   showticklabels: true,
      title: 'Volume of water used (gallons)',
      titlefont: {color: 'rgb(0, 0, 0)', size: 14},
      tickfont: {color: 'rgb(0, 0, 0)', size: 12},
    },
    height: 400,
    showlegend: true,
    legend: { orientation: "h", x:0, y:1, yanchor: 'bottom',
              bgcolor: 'rgba(255,255,255,0.7)', borderwidth: 0, bordercolor: 'gray',
              title: { text: '<b>PP:</b>'}, font: {size: 10 }
            },
    margin: { t: 70,   b: 30,  r: 20,   l: 50  },
  };
var data3 = [ppi10Trace, ppi20Trace, ppi35Trace, ppi50Trace, ppi100Trace];
Plotly.newPlot('summaryPPIChart', data3, layout3, config);

//###################################################################################################
// LABOR HOURS AT MINIMUM WAGE -----------------------------------------------------------------------///////////////
//###################################################################################################
//dataCSV.forEach(function(d){ d.days = +d.LaborHrs*12/8;          });

var days10 = []; var days20 = []; var days30 = []; var days40 = []; var days50 = [];
for (i=0; i < xVolume.length; i++){
  temp = dataCSV.filter(function(d){ return d.LaborHrs <= day1*0.5 && d.hh_use === xVolume[i]; });
  days10.push((temp.length/totalSystems*100).toFixed(1));

  temp = dataCSV.filter(function(d){ return d.LaborHrs > day1*0.5 && d.LaborHrs <= day1 && d.hh_use === xVolume[i]; });
  days20.push((temp.length/totalSystems*100).toFixed(1));

  temp = dataCSV.filter(function(d){ return d.LaborHrs > day1 && d.LaborHrs <= day1*2 && d.hh_use === xVolume[i]; });
  days30.push((temp.length/totalSystems*100).toFixed(1));

  temp = dataCSV.filter(function(d){ return d.LaborHrs > day1*2 && d.LaborHrs <= day1*3 && d.hh_use === xVolume[i]; });
  days40.push((temp.length/totalSystems*100).toFixed(1));

  temp = dataCSV.filter(function(d){ return d.LaborHrs > day1*3 && d.hh_use === xVolume[i]; });
  days50.push((temp.length/totalSystems*100).toFixed(1));
}

//create plotly trace
var days10Trace = {
  x: xVolume, y: days10, name: "<0.5 days",  type: 'bar',  marker: {color: colorVLow},
  hovertemplate: '%{y}% of utilities serve minimum wage<br>earners spending less than 0.5 work days<br>each month %{x} gallons'
};

var days20Trace = {
  x: xVolume, y: days20, name: "0.5-1 day",  type: 'bar',  marker: {color: colorLow},
  hovertemplate: '%{y}% of utilities serve minimum wage<br>earners spending 0.5-1 work day<br>each month at %{x} gallons'
};

var days30Trace = {
  x: xVolume, y: days30, name: "1.1-2 days",  type: 'bar',  marker: {color: colorMod},
  hovertemplate: '%{y}% of utilities serve minimum wage<br>earners spending 1.1-2 work days<br>each month at %{x} gallons'
};

var days40Trace = {
  x: xVolume, y: days40, name: "2.1-3 days",  type: 'bar',  marker: {color: colorHigh},
  hovertemplate: '%{y}% of utilities serve minimum wage<br>earners spending 2.1-3 work days<br>each month at %{x} gallons'
};

var days50Trace = {
  x: xVolume, y: days50, name: ">3 days",  type: 'bar',  marker: {color: colorVHigh},
  hovertemplate: '%{y}% of utilities serve minimum wage<br>earners spending more than 3 work days<br>each month at %{x} gallons'
};


var layout4 = {
  barmode: 'stack',
    yaxis: {
        title: 'Percent of Utilities (%)',
        titlefont: {color: 'rgb(0, 0, 0)', size: 14 },
        tickfont: {color: 'rgb(0, 0, 0)', size: 12},
        showline: false,    showgrid: false,   showticklabels: true,
        range: [0, 100], 
    },
    xaxis: {
      showline: false,   showgrid: false,   showticklabels: true,
      title: 'Volume of water used (gallons)',
      titlefont: {color: 'rgb(0, 0, 0)', size: 14},
      tickfont: {color: 'rgb(0, 0, 0)', size: 12},
    },
    height: 400,
    showlegend: true,
    //legend: {x: 1, xanchor: 'left', y: 1, 
    legend: { orientation: "h", x:0, y:1, yanchor: 'bottom',
              bgcolor: 'rgba(255,255,255,0.7)', borderwidth: 0, bordercolor: 'gray',
              title: { text: '<b>Days Labor:</b>'}, font: {size: 10 }
            },
    margin: { t: 70,   b: 30,  r: 20,   l: 50  },
  };
var data4 = [days10Trace, days20Trace, days30Trace, days40Trace, days50Trace];
Plotly.newPlot('summaryWageChart', data4, layout4, config);


//###################################################################################################
//          NOW LET US REPEAT BUT FOR HOUSEHOLD BURDEN INDICATOR ONLY                //
//###################################################################################################
var mhi1 = []; var mhi2 = []; var mhi3 = []; var mhi4 = []; var mhi5 = [];
for (i=0; i < xVolume.length; i++){
  temp = dataCSV.filter(function(d){ return d.TRAD <= day1/2 && d.hh_use === xVolume[i]; });
  mhi1.push((temp.length/totalSystems*100).toFixed(1));

  temp = dataCSV.filter(function(d){ return d.TRAD > day1/2 && d.TRAD <= day1 && d.hh_use === xVolume[i]; });
  mhi2.push((temp.length/totalSystems*100).toFixed(1));

  temp = dataCSV.filter(function(d){ return d.TRAD > day1 && d.TRAD <= day1*2 && d.hh_use === xVolume[i]; });
  mhi3.push((temp.length/totalSystems*100).toFixed(1));

  temp = dataCSV.filter(function(d){ return d.TRAD > day1*2 && d.TRAD <= day1*3  && d.hh_use === xVolume[i]; });
  mhi4.push((temp.length/totalSystems*100).toFixed(1));

  temp = dataCSV.filter(function(d){ return d.TRAD > day1*3 && d.hh_use === xVolume[i]; });
  mhi5.push((temp.length/totalSystems*100).toFixed(1));
}

//create plotly trace
var mhi1Trace = {
  x: xVolume, y: mhi1, name: "<0.5 days",
  type: 'bar',  marker: {color: colorVLow},
  hovertemplate: '%{y}% of utilities serve median income<br>households spending less than half a work day<br>each month at %{x} gallons'
};

var mhi2Trace = {
  x: xVolume, y: mhi2, name: "0.5-1 day",
  type: 'bar',  marker: {color: colorLow},
  hovertemplate: '%{y}% of utilities serve median income<br>households spending 0.5 to 1 work day<br>each month at %{x} gallons'
};

var mhi3Trace = {
  x: xVolume, y: mhi3, name: "1.1-2 days",
  type: 'bar',  marker: {color: colorMod},
  hovertemplate: '%{y}% of utilities serve median income<br>households spend 1.1 to 2 work days<br>each month at %{x} gallons'
};

var mhi4Trace = {
  x: xVolume, y: mhi4, name: "2.1-3 days",
  type: 'bar',  marker: {color: colorHigh},
  hovertemplate: '%{y}% of utilities serve median income<br>households spend 2.1 to 3 work days<br>each month at %{x} gallons'
};

var mhi5Trace = {
  x: xVolume, y: mhi5, name: "> 3 days",
  type: 'bar',  marker: {color: colorVHigh},
  hovertemplate: '%{y}% of utilities serve median income<br>households spending more than 3 work days<br>each month at %{x} gallons'
};


var layout5 = {
  barmode: 'stack',
    yaxis: {
        title: 'Percent of Utilities (%)',
        titlefont: {color: 'rgb(0, 0, 0)', size: 14 },
        tickfont: {color: 'rgb(0, 0, 0)', size: 12},
        showline: false,    showgrid: false,   showticklabels: true,
        range: [0, 100], 
    },
    xaxis: {
      showline: false,   showgrid: false,   showticklabels: true,
      title: 'Volume of water used (gallons)',
      titlefont: {color: 'rgb(0, 0, 0)', size: 14},
      tickfont: {color: 'rgb(0, 0, 0)', size: 12},
    },
    height: 350,
    showlegend: true,
    legend: { orientation: "h", x:0, y:1, yanchor: 'bottom',
              bgcolor: 'rgba(255,255,255,0.7)', borderwidth: 0, bordercolor: 'gray',
              title: { text: '<b>Traditional:</b>'}, font: {size: 10 }
            },
    margin: { t: 70,   b: 30,  r: 20,   l: 50  },
  };
var data5 = [mhi1Trace, mhi2Trace, mhi3Trace, mhi4Trace, mhi5Trace];
Plotly.newPlot('summaryMHIChart', data5, layout5, config);


}//end function






