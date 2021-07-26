///////////////////////////////////////////////////////////////////////////////////////////////////
//
//                      AFFORDABILITY MATRIX SCRIPT                               ///////////////
////                   
///////////////////////////////////////////////////////////////////////////////////////////////////

function createMatrix(selectSystem, matrixLegend) {

//read in csv 
dataCSV = utilityScores.filter(function(d){ return d.hh_use === selectVolume; });

//calculate here so have more stability in y-axis
var yPoints = dataCSV.map(function(d) { return d.HBI; });
var maxHB = d3.max(yPoints)+2;

var a1 = ["Very High", "High", "Moderate-High", "Low-Moderate", "Low"];
var a2 = dataCSV.map(function(d){ return d.burden; });
var initialValue = {};

var reducer = function(tally, vote) {
  if (!tally[vote]) {
    tally[vote] = 1;
  } else {
    tally[vote] = tally[vote] + 1;
  }
  return tally;
};
var resultsAll = a2.reduce(reducer, initialValue);

//filter by map selections
dataCSV = dataCSV.filter(el => {
  return selCSV.find(element => {
     return element.pwsid === el.pwsid;
  });
});
//console.log(dataCSV);

var xPoints = dataCSV.map(function(d) { return d.PPI; });
yPoints = dataCSV.map(function(d) { return d.HBI; });
//maxHB = d3.max(yPoints)+2;
//var ptsLabels = dataCSV.map(function(d) {return d.service_area  + ", " + d.state.toUpperCase(); });
var ptsLabels = dataCSV.map(function(d) {return d.pwsid; });

//pull out selected system
var selMatrix = utilityScores.filter(function(d){ return d.pwsid === selectSystem & d.hh_use===selectVolume; });
  var selXPoint = selMatrix.map(function(d){ return d.PPI; });
  var selYPoint = selMatrix.map(function(d){ return d.HBI; });
  var selBurden = selMatrix.map(function(d) {return d.burden; });

var selName = selCSV.filter(function(d) {return d.pwsid === selectSystem})
      .map(function(d) { return d.service_area  + ", " + d.pwsid.substring(0,2); });

//PLOTLY.JS TRACES ----------------------------------------------------------------------------------------
var allTrace = {
  x: xPoints,  y: yPoints,  name: "all",
  mode: 'markers',  type: 'scatter',  text: ptsLabels,
  marker: {size: 6, color: 'rgba(0,0,0,0.6)', line: {color: 'black', width: 1}}, //"#8a8a8a"},
  hovertemplate:
            "<b>%{text}</b><br>" +
            "HB: %{y:.1f}<br>" +
            "PP: %{x:.1f}"
};

var selTrace = {
  x: selXPoint,  y: selYPoint,  name: "selected",
  mode: 'markers',  type: 'scatter', // text: selectSystem,
  hovertemplate:
            "<span style='color: blue'><b>"+selectSystem+"</b><br>" +
            "HB: %{y:.1f}<br>" +
            "PP: %{x:.1f}</span>",
  marker: {
    size: 16, color: "blue",
    line: {color: "white", width: 2}
    },
};

//#######################  IF STATE LEGEND IS SELECTED  ######################################################
if(matrixLegend === "state"){
  var caData2 = selCSV.filter(function(d){ return d.state==="ca"; });
  var caData = dataCSV.filter(el => {
     return caData2.find(element => { return element.pwsid === el.pwsid; });
    });
    var xCA = caData.map(function(d) {return d.PPI; });  
    var yCA = caData.map(function(d) {return d.HBI; });
    var caLabels = caData.map(function(d){ return d.pwsid; });
    
  var paData2 = selCSV.filter(function(d){ return d.state==="pa"; });
  var paData = dataCSV.filter(el => {
    return paData2.find(element => { return element.pwsid === el.pwsid; });
  });
    var xPA = paData.map(function(d) {return d.PPI; });  
    var yPA = paData.map(function(d) {return d.HBI; });
    var paLabels = paData.map(function(d){ return d.pwsid; });

  var ncData2 = selCSV.filter(function(d){ return d.state==="nc"; });
      //filter by map selections
  var ncData = dataCSV.filter(el => {
     return ncData2.find(element => { return element.pwsid === el.pwsid; });
    });
    var xNC = ncData.map(function(d) {return d.PPI; });  
    var yNC = ncData.map(function(d) {return d.HBI; });
    var ncLabels = ncData.map(function(d){ return d.pwsid; });

    var orData2 = selCSV.filter(function(d){ return d.state==="or"; });
    //filter by map selections
    var orData = dataCSV.filter(el => {
      return orData2.find(element => { return element.pwsid === el.pwsid; });
      });
    var xOR = orData.map(function(d) {return d.PPI; });  
    var yOR = orData.map(function(d) {return d.HBI; });
    var orLabels = orData.map(function(d){ return d.pwsid; });

    var txData2 = selCSV.filter(function(d){ return d.state==="tx"; });
    //filter by map selections
    var txData = dataCSV.filter(el => {
      return txData2.find(element => { return element.pwsid === el.pwsid;  });
      });
    var xTX = txData.map(function(d) {return d.PPI; });  
    var yTX = txData.map(function(d) {return d.HBI; });
    var txLabels = txData.map(function(d){ return d.pwsid });

    // if states, create trace
    var caTrace = {
      x: xCA,  y: yCA,  name: "CA",
      mode: 'markers',  type: 'scatter',  text: caLabels,
      marker: {size: 6, color: "#c49532", line: {color: 'black', width: 1}}, //"#8a8a8a"},
      hovertemplate: "<b>%{text}</b><br>" +  "HB: %{y:.1f}<br>" +   "PP: %{x:.1f}"
    };

    var ncTrace = {
      x: xNC,       y: yNC,               name: "NC",
      mode: 'markers',  type: 'scatter',  text: ncLabels,
      marker: {size: 6, color:'#1f97e5', line: {color: 'black', width: 1}, opacity: 0.7},
      hovertemplate: "<b>%{text}</b><br>" + "HB: %{y:.1f}<br>" + "PP: %{x:.1f}"
    };

    var paTrace = {
      x: xPA,       y: yPA,               name: "PA",
      mode: 'markers',  type: 'scatter',  text: paLabels,
      marker: {size: 6, color:'#7c2020', line: {color: 'black', width: 1}, opacity: 0.7},
      hovertemplate: "<b>%{text}</b><br>" + "HB: %{y:.1f}<br>" + "PP: %{x:.1f}"
    };

    var txTrace = {
      x: xTX,       y: yTX,               name: "TX",
      mode: 'markers',  type: 'scatter',  text: txLabels,
      marker: {size: 6, color: '#6d1fe5', line: {color: 'black', width: 1}, opacity: 0.7},
      hovertemplate: "<b>%{text}</b><br>" + "HB: %{y:.1f}<br>" + "PP: %{x:.1f}"
    };

     var orTrace = {
      x: xOR,       y: yOR,               name: "OR",
      mode: 'markers',  type: 'scatter',  text: orLabels,
      marker: {size: 6, color: '#19d663', line: {color: 'black', width: 1}, opacity: 0.7},
      hovertemplate: "<b>%{text}</b><br>" + "HB: %{y:.1f}<br>" + "PP: %{x:.1f}"
    };

data = [ncTrace, paTrace, caTrace, txTrace, orTrace, selTrace]; 
}


//#######################  IF Size LEGEND IS SELECTED  ######################################################
if(matrixLegend === "sizeCategory"){
  var vSmallData2 = selCSV.filter(function(d){ return d.sizeCategory==="Very Small"; });
  var vSmallData = dataCSV.filter(el => {
    return vSmallData2.find(element => { return element.pwsid === el.pwsid; });
  });
    var xVSmall = vSmallData.map(function(d) {return d.PPI; });  
    var yVSmall = vSmallData.map(function(d) {return d.HBI; });
    var vSmallLabels = vSmallData.map(function(d){ return d.pwsid; });

    var smallData2 = selCSV.filter(function(d){ return d.sizeCategory==="Small"; });
    var smallData = dataCSV.filter(el => {
      return smallData2.find(element => { return element.pwsid === el.pwsid; });
    });
    var xSmall = smallData.map(function(d) {return d.PPI; });  
    var ySmall = smallData.map(function(d) {return d.HBI; });
    var smallLabels = smallData.map(function(d){ return d.pwsid; });

    var mediumData2 = selCSV.filter(function(d){ return d.sizeCategory==="Medium"; });
    var mediumData = dataCSV.filter(el => {
      return mediumData2.find(element => {return element.pwsid === el.pwsid; });
    });
    var xMedium = mediumData.map(function(d) {return d.PPI; });  
    var yMedium = mediumData.map(function(d) {return d.HBI; });
    var mediumLabels = mediumData.map(function(d){ return d.pwsid; });

    var mediumLargeData2 = selCSV.filter(function(d){ return d.sizeCategory==="Medium-Large"; });
    var mediumLargeData = dataCSV.filter(el => {
      return mediumLargeData2.find(element => {return element.pwsid === el.pwsid; });
    });
    var xMediumLarge = mediumLargeData.map(function(d) {return d.PPI; });  
    var yMediumLarge = mediumLargeData.map(function(d) {return d.HBI; });
    var mediumLargeLabels = mediumLargeData.map(function(d){ return d.pwsid; });

    var largeData2 = selCSV.filter(function(d){ return d.sizeCategory==="Large"; });
    var largeData = dataCSV.filter(el => {
      return largeData2.find(element => {return element.pwsid === el.pwsid; });
    });
    var xLarge = largeData.map(function(d) {return d.PPI; });  
    var yLarge = largeData.map(function(d) {return d.HBI; });
    var largeLabels = largeData.map(function(d){ return d.pwsid; });

    var vLargeData2 = selCSV.filter(function(d){ return d.sizeCategory==="Very Large"; });
    var vLargeData = dataCSV.filter(el => {
      return vLargeData2.find(element => {return element.pwsid === el.pwsid; });
    });
    var xVLarge = vLargeData.map(function(d) {return d.PPI; });  
    var yVLarge = vLargeData.map(function(d) {return d.HBI; });
    var vLargeLabels = vLargeData.map(function(d){ return d.pwsid; });

  // if states, create trace
    var vSmallTrace = {
      x: xVSmall,  y: yVSmall,  name: "Very Small",
      mode: 'markers',  type: 'scatter',  text: vSmallLabels,
      marker: {size: 6, color: "#924311", line: {color: 'black', width: 1}}, //"#8a8a8a"},
      hovertemplate: "<b>%{text}</b><br>" +  "HB: %{y:.1f}<br>" +   "PP: %{x:.1f}"
    };

    var smallTrace = {
      x: xSmall,       y: ySmall,               name: "Small",
      mode: 'markers',  type: 'scatter',  text: smallLabels,
      marker: {size: 6, color:'#990099', line: {color: 'black', width: 1}, opacity: 0.7},
      hovertemplate: "<b>%{text}</b><br>" + "HB: %{y:.1f}<br>" + "PP: %{x:.1f}"
    };

    var mediumTrace = {
      x: xMedium,       y: yMedium,               name: "Medium",
      mode: 'markers',  type: 'scatter',  text: mediumLabels,
      marker: {size: 6, color:'#d6c219', line: {color: 'black', width: 1}, opacity: 0.7},
      hovertemplate: "<b>%{text}</b><br>" + "HB: %{y:.1f}<br>" + "PP: %{x:.1f}"
    };

    var mediumLargeTrace = {
      x: xMediumLarge,       y: yMediumLarge,               name: "Medium-Large",
      mode: 'markers',  type: 'scatter',  text: mediumLargeLabels,
      marker: {size: 6, color:'#19d6c2', line: {color: 'black', width: 1}, opacity: 0.7},
      hovertemplate: "<b>%{text}</b><br>" + "HB: %{y:.1f}<br>" + "PP: %{x:.1f}"
    };

    var largeTrace = {
      x: xLarge,       y: yLarge,               name: "Large",
      mode: 'markers',  type: 'scatter',  text: largeLabels,
      marker: {size: 6, color: '#009900', line: {color: 'black', width: 1}, opacity: 0.7},
      hovertemplate: "<b>%{text}</b><br>" + "HB: %{y:.1f}<br>" + "PP: %{x:.1f}"
    };

     var vLargeTrace = {
      x: xVLarge,       y: yVLarge,               name: "Very Large",
      mode: 'markers',  type: 'scatter',  text: vLargeLabels,
      marker: {size: 6, color: '#000099', line: {color: 'black', width: 1}, opacity: 0.7},
      hovertemplate: "<b>%{text}</b><br>" + "HB: %{y:.1f}<br>" + "PP: %{x:.1f}"
    };

data = [vSmallTrace, smallTrace, mediumTrace, mediumLargeTrace, largeTrace, vLargeTrace, selTrace];   
}


//owner_type----------------------------------------------------------------
if(matrixLegend === "owner_type"){
  var localData2 = selCSV.filter(function(d){ return d.owner_type==="Local"; });
    var localData = dataCSV.filter(el => {
      return localData2.find(element => {return element.pwsid === el.pwsid; });
    });
    var xLocal = localData.map(function(d) {return d.PPI; });  
    var yLocal = localData.map(function(d) {return d.HBI; });
    var localLabels = localData.map(function(d){ return d.pwsid; });

  var privateData2 = selCSV.filter(function(d){ return d.owner_type==="Private"; });
    var privateData = dataCSV.filter(el => {
      return privateData2.find(element => {return element.pwsid === el.pwsid; });
    });
    var xPrivate = privateData.map(function(d) {return d.PPI; });  
    var yPrivate = privateData.map(function(d) {return d.HBI; });
    var privateLabels = privateData.map(function(d){ return d.pwsid; });
  
  var mixData2 = selCSV.filter(function(d){ return d.owner_type !== "Local" && d.owner_type !== "Private"; });
    var mixData = dataCSV.filter(el => {
      return mixData2.find(element => {return element.pwsid === el.pwsid; });
    });
    var xMix = mixData.map(function(d) {return d.PPI; });  
    var yMix = mixData.map(function(d) {return d.HBI; });
    var mixLabels = mixData.map(function(d){ return d.pwsid; });

  var localTrace = {
      x: xLocal,       y: yLocal,               name: "Local Govt",
      mode: 'markers',  type: 'scatter',  text: localLabels,
      marker: {size: 6, color: 'darkgray', line: {color: 'black', width: 1}, opacity: 0.7},
      hovertemplate: "<b>%{text}</b><br>" + "HB: %{y:.1f}<br>" + "PP: %{x:.1f}"
    };

  var privateTrace = {
      x: xPrivate,       y: yPrivate,               name: "Private",
      mode: 'markers',  type: 'scatter',  text: privateLabels,
      marker: {size: 6, color: 'blue', line: {color: 'black', width: 1}, opacity: 0.7},
      hovertemplate: "<b>%{text}</b><br>" + "HB: %{y:.1f}<br>" + "PP: %{x:.1f}"
    };

  var mixTrace = {
      x: xMix,       y: yMix,               name: "Other",
      mode: 'markers',  type: 'scatter',  text: mixLabels,
      marker: {size: 6, color: 'purple', line: {color: 'black', width: 1}, opacity: 0.7},
      hovertemplate: "<b>%{text}</b><br>" + "HB: %{y:.1f}<br>" + "PP: %{x:.1f}"
    };

  data = [localTrace, privateTrace, mixTrace, selTrace];
}


// #####-------------------------------------------------########################################################
if (matrixLegend === "none") {data = [allTrace, selTrace]; }
//console.log(data);
//https://plotly.com/javascript/configuration-options/

//create layout
var layout_height = 400;
var layout = {
    yaxis: {
        title: 'HB: Income Spent on Water Services (%)',
        titlefont: {color: 'rgb(0, 0, 0)', size: 14 },
        tickfont: {color: 'rgb(0, 0, 0)', size: 12},
        showline: false,    showgrid: false,   showticklabels: true,
        range: [0, maxHB], 
    },
    xaxis: {
      showline: false,   showgrid: false,   showticklabels: true,
      title: 'PP: Poverty Prevalence in Service Area (%)',
      titlefont: {color: 'rgb(0, 0, 0)', size: 14},
      tickfont: {color: 'rgb(0, 0, 0)', size: 12},
      range: [0, 100]
    },
    height: layout_height,
    showlegend: true,
    legend: {x: 1, xanchor: 'right', y: 1, 
              bgcolor: 'rgba(255,255,255,0.7)', borderwidth: 0.8, bordercolor: 'gray',
              title: { text: '<b> Legend </b>'}, font: {size: 10 }
            },
    margin: { t: 30,   b: 40,  r: 50,   l: 50  },
    hovermode: "closest",
    hoverlabel: {bgcolor: "#FFF"},
    config: {responsive: true},
    
    shapes: [ // EVEN DRAWING SHAPES BELOW< HOVER NO LONGER WORKS
      { type: 'rect', xref: 'x', yref: 'y', //ref is assigned to x values
            x0: 0, y0: 0, x1: 20, y1: day1,
            fillcolor: '#3b80cd', opacity: 0.1,
            layer: "below", // draws layer below trace
            line: { 'width': 1, color: 'darkgray'}
          },

       { type: 'rect', xref: 'x', yref: 'y', //ref is assigned to x values
            x0: 0, y0: day1, x1: 20, y1: day1*2,
            fillcolor: '#36bdcd', opacity: 0.1,
            line: { 'width': 1, color: 'darkgray'},
       },
       { type: 'rect', xref: 'x', yref: 'y', //ref is assigned to x values
            x0: 20, y0: 0, x1: 35, y1: day1,
            fillcolor: '#36bdcd',  opacity: 0.1,
            layer: "below", // draws layer below trace
            line: { 'width': 1, color: 'darkgray'},
       },

      { type: 'rect', xref: 'x', yref: 'y', //ref is assigned to x values
          x0: 0, y0: day1*2, x1: 20, y1: 100,
          fillcolor: '#cd8536', opacity: 0.1,
          layer: "below", // draws layer below trace
          line: { 'width': 1, color: 'darkgray'},
     },
     { type: 'rect', xref: 'x', yref: 'y', //ref is assigned to x values
          x0: 35, y0: 0, x1: 100, y1: day1,
          fillcolor: '#cd8536',   opacity: 0.1,
          layer: "below", // draws layer below trace
          line: { 'width': 1, color: 'darkgray'},
     },
     { type: 'rect', xref: 'x', yref: 'y', //ref is assigned to x values
          x0: 20, y0: day1, x1: 35, y1: day1*2,
          fillcolor: '#cd8536',    opacity: 0.1,
          layer: "below", // draws layer below trace
          line: { 'width': 1, color: 'darkgray'},
     },

     { type: 'rect', xref: 'x', yref: 'y', //ref is assigned to x values
          x0: 20, y0: day1*2, x1: 35, y1: 100,
          fillcolor: '#ea3119',  opacity: 0.1,
          layer: "below", // draws layer below trace
          line: { 'width': 1, color: 'darkgray'},
     },
     { type: 'rect', xref: 'x', yref: 'y', //ref is assigned to x values
          x0: 35, y0: day1, x1: 100, y1: day1*2,
          fillcolor: '#ea3119',  opacity: 0.15,
          layer: "below", // draws layer below trace
          line: { 'width': 1, color: 'darkgray'},
     },

     { type: 'rect', xref: 'x', yref: 'y', //ref is assigned to x values
          x0: 35, y0: day1*2, x1: 100, y1: 100,
          fillcolor: '#71261c',   opacity: 0.1,
          layer: "below", // draws layer below trace
          line: { 'width': 1, color: 'darkgray'},
     }, 

     { type: 'line', xref: 'x', yref: 'y', 
          x0: 20, y0: 0, x1: 20, y1: 100,
          line: {'width': 1, color: '#001b1b', dash: "dot"},
          layer: "below", // draws layer below trace
        },
    { type: 'line', xref: 'x', yref: 'y', 
          x0: 0, y0: day1, x1: 100, y1: day1,
          line: {'width': 1, color: '#001b1b', dash: "dot"},
          layer: "below", // draws layer below trace
        },
    { type: 'line', xref: 'x', yref: 'y', 
          x0: 35, y0: 0, x1: 35, y1: 100,
          line: {'width': 1, color: '#001b1b', dash: "dot"},
          layer: "below", // draws layer below trace
        },
    { type: 'line', xref: 'x', yref: 'y', 
          x0: 0, y0: day1*2, x1: 100, y1: day1*2,
          line: {'width': 1, color: '#001b1b', dash: "dot"},
          layer: "below", // draws layer below trace
    },
    { type: 'line', xref: 'x', yref: 'y', 
          x0: 0, y0: day1*3, x1: 100, y1: day1*3,
          line: {'width': 1, color: 'darkgray', dash: "dot"},
          layer: "below", // draws layer below trace
    },
    { type: 'line', xref: 'x', yref: 'y', 
          x0: 0, y0: day1*4, x1: 100, y1: day1*4,
          line: {'width': 1, color: 'darkgray', dash: "dot"},
          layer: "below", // draws layer below trace
    },
       { type: 'line', xref: 'x', yref: 'y', 
          x0: 0, y0: day1*5, x1: 100, y1: day1*5,
          line: {'width': 1, color: 'darkgray', dash: "dot"},
          layer: "below", // draws layer below trace
    },
       { type: 'line', xref: 'x', yref: 'y', 
          x0: 0, y0: day1*6, x1: 100, y1: day1*6,
          line: {'width': 1, color: 'darkgray', dash: "dot"},
          layer: "below", // draws layer below trace
    },
    { type: 'line', xref: 'x', yref: 'y', 
          x0: 0, y0: day1*7, x1: 100, y1: day1*7,
          line: {'width': 1, color: 'darkgray', dash: "dot"},
          layer: "below", // draws layer below trace
    },
    ],

    annotations: [
          { xref: 'x', yref: 'y', x: 1, y: 2,
            xanchor: 'left', yanchor: 'bottom',
            text: "Low", 
            font: {family: 'verdana', size: 11, color: '#3b80cd'},
            showarrow: false,
          },
          { xref: 'x', yref: 'y', x: 1, y: 7,
            xanchor: 'left', yanchor: 'bottom',
            text: "Low-Moderate", 
            font: {family: 'verdana', size: 11, color: '#36bdcd'},
            showarrow: false,
          },
          { xref: 'x', yref: 'paper', x: 1, y: 0.95,
            xanchor: 'left', yanchor: 'top',
            text: "Moderate-High", 
            font: {family: 'verdana', size: 11, color: '#cd8536'},
            showarrow: false,
          },
          { xref: 'x', yref: 'paper', x: 25, y: 0.95,
            xanchor: 'left', yanchor: 'top',
            text: "High", 
            font: {family: 'verdana', size: 11, color: '#ea3119'},
            showarrow: false,
          },
          { xref: 'x', yref: 'paper', x: 42, y: 0.95,
            xanchor: 'left', yanchor: 'top',
            text: "Very High", 
            font: {family: 'verdana', size: 11, color: '#71261c'},
            showarrow: false,
          },
           { xref: 'x', yref: 'y', x: 100, y: day1,
            xanchor: 'right', yanchor: 'bottom', text: "1 day", 
            font: {family: 'verdana', size: 11, color: 'black'}, showarrow: false,
          },
          { xref: 'x', yref: 'y', x: 100, y: day1*2,
            xanchor: 'right', yanchor: 'bottom', text: "2 days", 
            font: {family: 'verdana', size: 11, color: 'black'}, showarrow: false,
          },
          { xref: 'x', yref: 'y', x: 82, y: day1*3,
            xanchor: 'right', yanchor: 'bottom', text: "3 days", 
            font: {family: 'verdana', size: 11, color: 'darkgray'}, showarrow: false,
          },
          { xref: 'x', yref: 'y', x: 82, y: day1*4,
            xanchor: 'right', yanchor: 'bottom', text: "4 days", 
            font: {family: 'verdana', size: 11, color: 'darkgray'}, showarrow: false,
          },
          { xref: 'x', yref: 'y', x: 82, y: day1*5,
            xanchor: 'right', yanchor: 'bottom', text: "5 days", 
            font: {family: 'verdana', size: 11, color: 'darkgray'}, showarrow: false,
          },
          { xref: 'x', yref: 'y', x: 82, y: day1*6,
            xanchor: 'right', yanchor: 'bottom', text: "6 days", 
            font: {family: 'verdana', size: 11, color: 'darkgray'}, showarrow: false,
          },
          { xref: 'x', yref: 'y', x: 82, y: day1*7 + 4,
            xanchor: 'right', yanchor: 'bottom', text: "> 7 days", 
            font: {family: 'verdana', size: 11, color: 'darkgray'}, showarrow: false,
          },
      ]
};
////////////////-----------------------------------------------------------------------///////////

Plotly.newPlot('matrixPlot', data, layout, config);


// ############################################################################################################
// CREATE THE TABLE
//##############################################################################################################
//how many of filtered dataset
var lowFilter = dataCSV.filter(function(d){ return d.burden==="Low"; }).length;
var lowModFilter = dataCSV.filter(function(d){ return d.burden==="Low-Moderate"; }).length;
var modHighFilter = dataCSV.filter(function(d){ return d.burden==="Moderate-High"; }).length;
var highFilter = dataCSV.filter(function(d){ return d.burden==="High"; }).length;
var veryHighFilter = dataCSV.filter(function(d){ return d.burden==="Very High"; }).length;

// repeat for block group if a place is selected
d3.csv("data/block_scores/block_scores_"+selectVolume+".csv").then(function(dataBlocksCSV){
  //console.log(dataBlocksCSV);
  dataBlocksCSV = dataBlocksCSV;
  
  //filter
  if(selectSystem === "none"){
  dataBlocksCSV = dataBlocksCSV.filter(el => {
    return selCSV.find(element => {
       return element.pwsid === el.pwsid;
    });
  });
}

  if(selectSystem !== "none"){
    dataBlocksCSV = dataBlocksCSV.filter(function(d){return d.pwsid === selectSystem; });
  }   

  console.log(dataBlocksCSV);
  //tally burden for block groups
  var a3 = dataBlocksCSV.map(function(d){ return d.burden; });
    var initialValue2 = {};
    blockBurdenResults = a3.reduce(reducer, initialValue2);
    //console.log(blockBurdenResults);
    
//check to see if exists, if negative 1 then set to 0
var low = blockBurdenResults.Low;
var lowmod = blockBurdenResults["Low-Moderate"];
var modhigh = blockBurdenResults["Moderate-High"];
var high = blockBurdenResults.High;
var veryhigh = blockBurdenResults["Very High"];

if(low == null) {low = 0;  } //has to be == not ===
if(lowmod == null) {lowmod = 0;  } //has to be == not ===
if(modhigh == null) {modhigh = 0;  } //has to be == not ===
if(high == null) {high = 0;  } //has to be == not ===
if(veryhigh == null) {veryhigh = 0;  } //has to be == not ===

// Create matrix Table
var myTable= "<table class='table table-condensed'>";
//create column header
myTable += "<thead><tr>";
myTable += "<th>Burden Level</th>";
myTable += "<th>All utilities in database</th>";
myTable += "<th>Filtered utilities in map</th>";

if(selectSystem === "none"){
  myTable += "<th>Block Groups in Filtered Utilities</th>";
}
if(selectSystem !== "none"){
  myTable += "<th>Block Groups in Selected Utility</th>" ;
}
myTable += "</tr></thead>";

//load info
myTable += "<tbody class='boldFont'>";
myTable += "<tr style= 'background-color: rgba(59,128,205,0.5)'>";
  myTable += "<td class='leftFont'>Low" +"</td><td>" + resultsAll["Low"] + "</td><td>" + lowFilter + "</td><td>" + 
      low.toLocaleString() + "</td></tr>";

myTable += "<tr style= 'background-color: rgba(54,189,205,0.5)'>";
  myTable += "<td class='leftFont'>Low-Moderate" +"</td><td>"  + resultsAll["Low-Moderate"] + "</td><td>" + lowModFilter + "</td><td>" +
      lowmod.toLocaleString() + "</td></tr>";

myTable += "<tr style= 'background-color: rgba(205,133,54,0.5)'>";
  myTable += "<td class='leftFont'>Moderate-High"  + "</td><td>"  + resultsAll["Moderate-High"] + "</td><td>" + modHighFilter + "</td><td>" +
    modhigh.toLocaleString() + "</td></tr>";

myTable += "<tr style= 'background-color: rgba(234,49,25,0.5)'>";
  myTable += "<td class='leftFont'>High" +"</td><td>"   + resultsAll["High"] + "</td><td>" + highFilter + "</td><td>" +
   high.toLocaleString() + "</td></tr>";

myTable += "<tr style= 'background-color: rgba(113,38,28,0.5)'>";
  myTable += "<td class='leftFont'>Very High" +"</td><td>"   + resultsAll["Very High"] + "</td><td>" + veryHighFilter + "</td><td>" +
   veryhigh.toLocaleString() + "</td></tr>";

myTable += "</tbody></table>"; 
//load table
document.getElementById('matrixTable').innerHTML = myTable;


  //update title
  if(selectSystem !== "none"){
    document.getElementById('matrixTitle').innerHTML =
      "<strong>" + selName + " affordability burden is " + selBurden +  "</strong>";
  }

  if(selectSystem === "none"){
    document.getElementById('matrixTitle').innerHTML = "<strong> Affordability Burden for all systems </strong>";
  }

});//end D3 block groups

//console.log(selectOwner)

// ############################################################################################################
// CREATE PLOT OF JUST THIS UTILITY AND HOW IT CHANGES WITH HH USE
//##############################################################################################################

if (selectSystem === "none"){
  document.getElementById('matrixVolHeader').innerHTML="How does burden change with water use?";
  //document.getElementById('matrixVolPlot').style.display="none";
  document.getElementById('matrixVolPlot').innerHTML = "You must select a utility";
}
if (selectSystem !== "none"){
  //document.getElementById('matrixVolHeader').style.display="block";
  
  document.getElementById('matrixVolPlot').innerHTML = "";
  //document.getElementById('matrixVolPlot').style.display="block";
  var allVol = utilityScores.filter(function(d){ return d.pwsid === selectSystem && d.hh_use != 4030; });

  var allVoltext = allVol.map(function(d) {return d.hh_use.toLocaleString(); });
  var allVoly = allVol.map(function(d){ return d.HBI; });
  var allVolx = allVol.map(function(d){ return d.PPI; });

  var changeHB = d3.max(allVoly) - d3.min(allVoly);

  var selVolTrace = {
    x: allVolx,  y: allVoly,  name: "selected",
    mode: 'markers+lines',  type: 'scatter',  //text: ptsLabels,
    marker: { size: 8, color: "blue"},
    line: {color: "black", width: 1},
    text: allVoltext,
    hovertemplate: "<b>%{text} gal</b><br>" + "HB: %{y:.1f}<br>" + "PP: %{x:.1f}"
  };
  var volData = [selVolTrace];
  Plotly.newPlot('matrixVolPlot', volData, layout, config);

  document.getElementById('matrixVolHeader').innerHTML = selName +" household burden increased by " + changeHB.toFixed() +"% from using 0 to 16,000 gallons a month";
} // end if statement

} // end function
//selectSystem = "01-11-010";
//createMatrix(selectSystem);




