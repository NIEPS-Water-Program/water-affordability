///////////////////////////////////////////////////////////////////////////////////////////////////
//
//                      COMPARE METRICS  GRAPHIC SCRIPT                              ///////////////
////                   
///////////////////////////////////////////////////////////////////////////////////////////////////
//Load Data and get correct########################################################
function allScores(selectSystem) {

//read in csv 
dataCSV = utilityScores.filter(function(d){ return d.hh_use === selectVolume; });

var xLabor = dataCSV.map(function(d) {return d.LaborHrs; });
var xHBI = dataCSV.map(function(d) {return d.HBI; });

//create max min for all data to hold constant axis
var maxXAxis = d3.max(xLabor);
var maxXAxis1 = d3.max(xHBI);

//filter by map selections
dataCSV = dataCSV.filter(el => {
  return selCSV.find(element => {
     return element.pwsid === el.pwsid;
  });
});  

//pull out selected system
var selMatrix = utilityScores.filter(function(d){ return d.pwsid === selectSystem & d.hh_use===selectVolume; });

    xHBI = dataCSV.map(function(d) {return d.HBI; });
var selHBI = selMatrix.map(function(d) { return d.HBI.toFixed(1); });

var xPPI = dataCSV.map(function(d) {return d.PPI; });
var selPPI = selMatrix.map(function(d) { return d.PPI.toFixed(1); });

var xTRAD = dataCSV.map(function(d) {return d.TRAD; });
var selTRAD = selMatrix.map(function(d) { return d.TRAD.toFixed(1); });

    xLabor = dataCSV.map(function(d) {return d.LaborHrs; });
var selLabor = selMatrix.map(function(d) { return d.LaborHrs.toFixed(1); });


//PLOTLY.JS
var xHBItrace = {
    y: "HBI",    x: xHBI,
    marker: {color: 'rgb(0,0,0)', size: 2},
    opacity: 0.6,
    type: 'box',
    boxpoints: 'all',
    showlegend: false,
    name: "Household<br>Burden"
};

var selxHBItrace = {
   y: ["Household<br>Burden"],
    x: selHBI,
    mode: "markers", type: "scatter",
    marker: {
        color: 'blue', size: 12,
        line: {color: 'black', width: 2 },
    },
    opacity: 1,
    name: "Selected Utility",
    showlegend: true,
    hovertemplate: selHBI + "% of a low-income household income going to water bills"
};

var xPPItrace = {
    y: "PPI",    x: xPPI,
    marker: {color: 'rgb(0,0,0)', size: 2},
    opacity: 0.6,
    type: 'box',
    boxpoints: 'all',
    name: "Poverty<br>Prevalence",
    showlegend: false
};

var selxPPIItrace = {
    y: ["Poverty<br>Prevalence"],
    x: selPPI,
    mode: "markers", type: "scatter",
    marker: {
        color: 'blue', size: 12,
        line: {color: 'black', width: 2 },
    },
    opacity: 1,
    name: "Selected",
    hovertemplate: selPPI + "% of the community is below 200% of poverty level",
    showlegend: false
};

var xTRADtrace = {
    y: "Traditional",    x: xTRAD,
    marker: {color: 'rgb(0,0,0)', size: 2},
    opacity: 0.6,
    type: 'box',
    boxpoints: 'all',
    name: "Traditional",
    showlegend: false
};

var selxTRADtrace = {
    y: ["Traditional"],
    x: selTRAD,
    mode: "markers", type: "scatter",
    marker: {
        color: 'blue', size: 12,
        line: {color: 'black', width: 2 },
    },
    opacity: 1,
    name: "Selected",
    hovertemplate: selTRAD + "% of a median household income going to water bills",
    showlegend: false
};

var xLabortrace = {
    y: "Labor hrs",    x: xLabor,
    marker: {color: 'rgb(0,0,0)', size: 2},
    opacity: 0.6,
    type: 'box',
    boxpoints: 'all',
    name: "Minimum<br>Wage Hrs",
    showlegend: false
};

var selxLabortrace = {
    y: ["Minimum<br>Wage Hrs"],
    x: selLabor,
    mode: "markers", type: "scatter",
    marker: {
        color: 'blue', size: 12,
        line: {color: 'black', width: 2 },
    },
    opacity: 1,
    name: "Selected Utility",
    hovertemplate: selLabor + " hours of work at minimum wage needed to pay water bills each month",
    showlegend: true
};

var allTrace = {
    y: ["Traditional"],    x: [-1],
    mode: "markers", type: "scatter",
    marker: {color: '#2a2a2a', size: 4 },
    opacity: 1,
    name: "All Utilities",
    skiphover: true,    showlegend: true
};

var allTrace2 = {
    y: ["Minimum<br>Wage Hrs"],    x: [-1],
    mode: "markers", type: "scatter",
    marker: {color: '#2a2a2a', size: 4 },    opacity: 1,
    name: "All Utilities",
    skiphover: true,    showlegend: true
};

//set values to zero for annotation
if (selHBI.length === 0) {
  selHBI[0] = " "; 
  selPPI[0] = " ";
  selTRAD[0] = " ";
  selLabor[0] = " ";
}

var layout = {
    yaxis: {
        title: '',
        titlefont: {color: 'rgb(0, 0, 0)', size: 14 },
        tickfont: {color: 'rgb(0, 0, 0)', size: 12},
        showline: false,
        showgrid: false,
        showticklabels: true,
        //mirror: 'ticks'
    },
    xaxis: {
      showline: false,
      showgrid: false,
      showticklabels: true,
      title: 'Percent of Income (4.6% = 1 day of labor)',
      titlefont: {color: 'rgb(0, 0, 0)', size: 14},
      tickfont: {color: 'rgb(0, 0, 0)', size: 12},
      range: [0, maxXAxis1]
    },
    height: 300,
    //showlegend: false,
    legend: {
      title: 'Legend',
      x: 1, xanchor: 'right', y: 0.5
    },
    margin: { t: 30,   b: 40,  r: 20,   l: 75  },
    fixedrange: false,

    shapes: [
        //HBI TRAD colors
           { type: 'line', xref: 'x', yref: 'paper', //ref is assigned to x values
            x0: day1, y0: 0.0, x1: day1, y1: 1,
            line: {color: '#001b1b', width: 2, dash: "dot"},
            layer: "below",
          },
          { type: 'line', xref: 'x', yref: 'paper', //ref is assigned to x values
            x0: day1*2, y0: 0.0, x1: day1*2, y1: 1,
            line: {color: '#001b1b', width: 2, dash: "dot"},
            layer: "below",
          },
          { type: 'line', xref: 'x', yref: 'paper', //ref is assigned to x values
            x0: day1*3, y0: 0.0, x1: day1*3, y1: 1,
            line: {color: '#001b1b', width: 2, dash: "dot"},
            layer: "below",
          },
          { type: 'line', xref: 'x', yref: 'paper', //ref is assigned to x values
            x0: day1*4, y0: 0.0, x1: day1*4, y1: 1,
            line: {color: '#001b1b', width: 2, dash: "dot"},
            layer: "below",
          },
          { type: 'line', xref: 'x', yref: 'paper', //ref is assigned to x values
            x0: day1*5, y0: 0.0, x1: day1*5, y1: 1,
            line: {color: '#001b1b', width: 2, dash: "dot"},
            layer: "below",
          },
          { type: 'line', xref: 'x', yref: 'paper', //ref is assigned to x values
            x0: day1*6, y0: 0.0, x1: day1*6, y1: 1,
            line: {color: '#001b1b', width: 2, dash: "dot"},
            layer: "below",
          },
     ],

    annotations: [
        //HBI colors
          { xref: 'x', yref: 'paper', //ref is assigned to x values
            x: 1, y: 0.88,
            xanchor: 'left', yanchor: 'bottom',
            text: "< 1 day", 
            font: {family: 'verdana', size: 11, color: '#001b1b'},
            showarrow: false
          },
          { xref: 'x', yref: 'paper', //ref is assigned to x values
            x: day1+1, y: 0.88,
            xanchor: 'left', yanchor: 'bottom',
            text: "1-2 days", 
            font: {family: 'verdana', size: 11, color: '#001b1b'},
            showarrow: false
          },
          { xref: 'x', yref: 'paper', //ref is assigned to x values
            x: day1*2+1, y: 0.88,
            xanchor: 'left', yanchor: 'bottom',
            text: "2-3 days", 
            font: {family: 'verdana', size: 11, color: '#001b1b'},
            showarrow: false
          },
          { xref: 'x', yref: 'paper', //ref is assigned to x values
            x: day1*3+1, y: 0.88,
            xanchor: 'left', yanchor: 'bottom',
            text: "3-4 days", 
            font: {family: 'verdana', size: 11, color: '#001b1b'},
            showarrow: false
          },
          { xref: 'x', yref: 'paper', //ref is assigned to x values
            x: day1*4+1, y: 0.88,
            xanchor: 'left', yanchor: 'bottom',
            text: "4-5 days", 
            font: {family: 'verdana', size: 11, color: '#001b1b'},
            showarrow: false
          },
           { xref: 'x', yref: 'paper', //ref is assigned to x values
            x: day1*5+1, y: 0.88,
            xanchor: 'left', yanchor: 'bottom',
            text: "5-6 days", 
            font: {family: 'verdana', size: 11, color: '#001b1b'},
            showarrow: false
          },
          { xref: 'x', yref: 'paper', //ref is assigned to x values
            x: day1*6+1, y: 0.88,
            xanchor: 'left', yanchor: 'bottom',
            text: "> 6 days", 
            font: {family: 'verdana', size: 11, color: '#001b1b'},
            showarrow: false
          },
      
         //Selected Scores
         { xref: 'paper', yref:'paper', x: 0, y: 0.2, xanchor: 'right', yanchor: 'top',
            text: "<b>"+selHBI[0] + "%</b>", font: {family: 'verdana', size: 11, color: "blue"},
            showarrow: false, 
          }, 
          { xref: 'paper', yref:'paper', x: 0, y: 0.72, xanchor: 'right', yanchor: 'top',
            text: "<b>" + selTRAD[0] + "%</b>", font: {family: 'verdana', size: 11, color: "blue"},
            showarrow: false
          }
        ]
};

var data = [xHBItrace, selxHBItrace, allTrace, xTRADtrace, selxTRADtrace];
//console.log(data);
Plotly.newPlot('allScoresChart', data, layout, config);

//MWH CHART
var layoutmwh = {
    yaxis: {
        title: '',
        titlefont: {color: 'rgb(0, 0, 0)', size: 14 },
        tickfont: {color: 'rgb(0, 0, 0)', size: 12},
        showline: false,
        showgrid: false,
        showticklabels: true,
        //mirror: 'ticks'
    },
    xaxis: {
      showline: false,
      showgrid: false,
      showticklabels: true,
      title: 'Hours of Labor',
      titlefont: {color: 'rgb(0, 0, 0)', size: 14},
      tickfont: {color: 'rgb(0, 0, 0)', size: 12},
      range: [0, maxXAxis]
    },
    height: 150,
    legend: { title: 'Legend', x: 1, xanchor: 'right', y: 0.5  },
    margin: { t: 30,   b: 40,  r: 20,   l: 75  },
    fixedrange: false,

    shapes: [
      //Labor Hrs
          { type: 'line', xref: 'x', yref: 'paper', //ref is assigned to x values
            x0: 8, y0: 0, x1: 8, y1: 1.0,
            layer: "below", // draws layer below trace
            line: {color: '#001b1b', width: 2, dash: "dot"}//line: {color: '#3b80cd', width: 2}
          },
          { type: 'line', xref: 'x', yref: 'paper', //ref is assigned to x values
            x0: 16, y0: 0, x1: 16, y1: 1.0,
            layer: "below", // draws layer below trace
            line: {color: '#001b1b', width: 2, dash: "dot"} //line: {color: '#cd8536', width: 2}
          },
           { type: 'line', xref: 'x', yref: 'paper', //ref is assigned to x values
            x0: 24, y0: 0, x1: 24, y1: 1.0,
            layer: "below", // draws layer below trace
            line: {color: '#001b1b', width: 2, dash: "dot"} //line: {color: '#cd8536', width: 2}
          },
          { type: 'line', xref: 'x', yref: 'paper', //ref is assigned to x values
            x0: 32, y0: 0, x1: 32, y1: 1.0,
            layer: "below", // draws layer below trace
            line: {color: '#001b1b', width: 2, dash: "dot"} //line: {color: '#cd8536', width: 2}
          },
          { type: 'line', xref: 'x', yref: 'paper', //ref is assigned to x values
            x0: 40, y0: 0, x1: 40, y1: 1.0,
            layer: "below", // draws layer below trace
            line: {color: '#001b1b', width: 2, dash: "dot"} //line: {color: '#cd8536', width: 2}
          },
          { type: 'line', xref: 'x', yref: 'paper', //ref is assigned to x values
            x0: 48, y0: 0, x1: 48, y1: 1.0,
            layer: "below", // draws layer below trace
            line: {color: '#001b1b', width: 2, dash: "dot"} //line: {color: '#cd8536', width: 2}
          },
     ],

    annotations: [
      //Labor Hrs
        { xref: 'x', yref: 'paper', //ref is assigned to x values
            x: 3, y: 0.88,
            xanchor: 'left', yanchor: 'bottom',
            text: "< 1 day", 
            font: {family: 'verdana', size: 11, color: '#001b1b'},
            showarrow: false
          },
          { xref: 'x', yref: 'paper', //ref is assigned to x values
            x: 10, y: 0.88,
            xanchor: 'left', yanchor: 'bottom',
            text: "1-2 days", 
            font: {family: 'verdana', size: 11, color: '#001b1b'},
            showarrow: false
          },
          { xref: 'x', yref: 'paper', //ref is assigned to x values
            x: 18, y: 0.88,
            xanchor: 'left', yanchor: 'bottom',
            text: "2-3 days", 
            font: {family: 'verdana', size: 11, color: '#001b1b'},
            showarrow: false
          },
          { xref: 'x', yref: 'paper', //ref is assigned to x values
            x: 26, y: 0.88,
            xanchor: 'left', yanchor: 'bottom',
            text: "3-4 days", 
            font: {family: 'verdana', size: 11, color: '#001b1b'},
            showarrow: false
          },
          { xref: 'x', yref: 'paper', //ref is assigned to x values
            x: 34, y: 0.88,
            xanchor: 'left', yanchor: 'bottom',
            text: "4-5 days", 
            font: {family: 'verdana', size: 11, color: '#001b1b'},
            showarrow: false
          },
          { xref: 'x', yref: 'paper', //ref is assigned to x values
            x: 42, y: 0.88,
            xanchor: 'left', yanchor: 'bottom',
            text: "5-6 days", 
            font: {family: 'verdana', size: 11, color: '#001b1b'},
            showarrow: false
          },
          { xref: 'x', yref: 'paper', //ref is assigned to x values
            x: 50, y: 0.88,
            xanchor: 'left', yanchor: 'bottom',
            text: "> 6 days", 
            font: {family: 'verdana', size: 11, color: '#001b1b'},
            showarrow: false
          },

         //Selected Scores
          { xref: 'paper', yref:'paper', x: 0, y: 0.1, xanchor: 'right', yanchor: 'bottom',
            text: "<b>" + selLabor[0] + " hrs</b>", font: {family: 'verdana', size: 11, color: "blue"},
            showarrow: false
          }
        ]
};
var dataMWH = [xLabortrace, selxLabortrace, allTrace2];
//console.log(data);
Plotly.newPlot('mwhScoresChart', dataMWH, layoutmwh, config);



// Poverty Prevalence ------------------------------------------------------------------------------------------
var layout2 = {
    yaxis: {
        title: '',
        titlefont: {color: 'rgb(0, 0, 0)', size: 14 },
        tickfont: {color: 'rgb(0, 0, 0)', size: 12},
        showline: false,        showgrid: false,         showticklabels: true,
    },
    xaxis: {
      showline: false,
      showgrid: false,
      showticklabels: true,
      title: 'Percent of Community',
      titlefont: {color: 'rgb(0, 0, 0)', size: 14},
      tickfont: {color: 'rgb(0, 0, 0)', size: 12},
      range: [0, 100]
    },
    height: 150,
    showlegend: false,
    margin: { t: 30,   b: 40,  r: 20,   l: 75 },
    fixedrange: false,

    shapes: [
            //PPI colors
          { type: 'line', xref: 'x', yref: 'paper', //ref is assigned to x values
            //x0: 20, y0: 0.25, x1: 20, y1: 0.47,
            x0: 20, y0: 0, x1: 20, y1: 1,
            layer: "below", // draws layer below trace
            line: {color: '#001b1b', width: 2, dash: "dot"}
          },
          { type: 'line', xref: 'x', yref: 'paper', //ref is assigned to x values
            x0: 35, y0: 0.0, x1: 35, y1: 1,
            layer: "below", // draws layer below trace
            line: {color: '#001b1b', width: 2, dash: "dot"}
          },
     ],

    annotations: [
    //PPI colors
           { xref: 'x', yref: 'paper', //ref is assigned to x values
            x: 9, y: 0.88,
            xanchor: 'left', yanchor: 'bottom',
            text: "Low", 
            font: {family: 'verdana', size: 11, color: '#001b1b'},
            showarrow: false
          },
          { xref: 'x', yref: 'paper', //ref is assigned to x values
            x: 24, y: 0.88,
            xanchor: 'left', yanchor: 'bottom',
            text: "Moderate", 
            font: {family: 'verdana', size: 11, color: '#001b1b'},
            showarrow: false
          },
          { xref: 'x', yref: 'paper', //ref is assigned to x values
            x: 55, y: 0.88,
            xanchor: 'left', yanchor: 'bottom',
            text: "High", 
            font: {family: 'verdana', size: 11, color: '#001b1b'},
            showarrow: false
          },

         //Selected Scores
          { xref: 'paper', yref:'paper', x: 0, y: 0.1, xanchor: 'right',
            text: "<b>" + selPPI[0] + "%</b>", font: {family: 'verdana', size: 11, color: "blue"},
            showarrow: false
          },
        ]
};
var data2 = [xPPItrace, selxPPIItrace];
//console.log(data);
Plotly.newPlot('ppiScoresChart', data2, layout2, config);

if (selectSystem !== "none"){ 
  var selName = selCSV.filter(function(d) {return d.pwsid === selectSystem})
      .map(function(d) { return d.service_area; });

  document.getElementById('allScoresTitle').innerHTML = "<strong>Affordability metrics for " + selName + " at " + numberWithCommas(selectVolume) + " gallons</strong>";
}
if (selectSystem === "none"){
  document.getElementById('allScoresTitle').innerHTML = "<strong>Comparing affordability metrics at " + selectVolume + " gallons</strong>";
}

}
//selectSystem = "01-11-010";
//allScores("01-11-010");


