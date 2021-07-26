///////////////////////////////////////////////////////////////////////////////////////////////////
//
//                      RATES FUNCTION GRAPHIC SCRIPT                              ///////////////
////                   
///////////////////////////////////////////////////////////////////////////////////////////////////

function onlyUnique(value, index, self) { 
    return self.indexOf(value) === index;
}

function createBoxTrace(target){
//var selection = document.billToPlot.waterList;
var selection = document.getElementsByName("waterList");
    for (i=0; i<selection.length; i++)
        if (selection[i].checked==true)
        selWaterType = selection[i].value; 
    
    plotRates(selectSystem, selectVolume, selWaterType);
    return selWaterType;
} // end create trace

function plotRates(selectSystem, selectVolume, selWaterType){
  if(selectSystem === "none"){ 
    document.getElementById('ratesTitle').innerHTML = "<strong>Select a utility to see monthly bills</strong>"; 
    document.getElementById('ratesMetaTitle').innerHTML = "<strong>Select a utility to see table of providers</strong>"; 
    document.getElementById('ratesMetaTable').innerHTML = ""; 
  }

  if(selectSystem !== "none"){
    //create a table for the metadata
    document.getElementById('ratesMetaTitle').innerHTML = "<strong>Utilities providing services in the selected service area</strong>"; 
    document.getElementById('ratesMetaTable').innerHTML = "";

    d3.csv("data/rates_metadata.csv").then(function(metaCSV){
      var metaSel = metaCSV.filter(function(d) { return d.pwsid === selectSystem; });
      //console.log(metaSel);
    //create table --- scroll options on table height, etc are in the css portion
    var myTable = "<br><table class='table table-bordered table-striped'>";
    //create column header
    myTable += "<thead><tr>";
    myTable += "<th>pwsid</th>";
    myTable += "<th>service<br>area</th>";
    myTable += "<th>city<br>name</th>";
    myTable += "<th>utility<br>name</th>";
    myTable += "<th>service<br>type</th>";
    myTable += "<th>year rates<br>started</th>";
    myTable += "<th>rates found<br>here</th>";
    myTable += "<th>data last<br>updated</th>";
    
   
   //end header and start body to loop through by activity
    myTable += "</thead><tbody'>";
    
  //loop through and add headers based on number of services
     for (i = 0, len = metaSel.length; i < len; i++) {

     var urlText = "<a href=" + metaSel[i].website + " target = '_blank' style='color: '#3f97a8'><u>click here</u></a>";
     if (metaSel[i].website.substring(0,4) !== "http") { urlText = "website not available"; }
     if (metaSel[i].utility_name === "Homeowners") { urlText = "Estimated Septic"; }
     
     //console.log(metaSel[i].website.substring(0,4));
      myTable += "<tr>";
      myTable += "<td>" + selectSystem + "</td>";
      myTable += "<td>" + metaSel[i].service_area + "</td>";
      myTable += "<td>" + metaSel[i].city_name + "</td>";
      myTable += "<td>" + metaSel[i].utility_name + "</td>";
      myTable += "<td>" + metaSel[i].service + "</td>";
      myTable += "<td>" + metaSel[i].year + "</td>";
      myTable += "<td>" + urlText + "</td>";
      myTable += "<td>" + metaSel[i].last_updated + "</td>";
      myTable += "</tr>";
    }
    myTable += "</tbody></table><br>"; 

  //load table
  var tableHeight = "350px";
  if (metaSel.length <= 5) { tableHeight = "200px"; }
    document.getElementById('ratesMetaTable').style.maxHeight = tableHeight;
    document.getElementById("ratesMetaTable").innerHTML = myTable;
  });//end d3
}//end if statement

//#################################################################################################################################
// 
//                       PLOT MONTHLY DATA
//
//#################################################################################################################################
//read in d3 with rates data
Plotly.purge('monthBillChart'); Plotly.purge('commodityChart'); Plotly.purge('boxRateChart');
document.getElementById('monthBillChart').innerHTML="";
    //read in csv 
  d3.csv("data/rates/rates_" + selectVolume + ".csv").then(function(costCSV){
    costCSV.forEach(function(d){
        d.base_cost = +d.base_cost;
        d.fixed_surcharge = +d.fixed_surcharge;
        d.total = +d.total;
        d.vol_cost = +d.vol_cost;
        d.vol_surcharge = +d.vol_surcharge;
        d.zone_cost = +d.zone_cost;
        d.zone_surcharge = +d.zone_surcharge;
        d.total_surcharge = d.fixed_surcharge + d.vol_surcharge + d.zone_surcharge;
        d.total_vol = d.vol_cost + d.zone_cost;
        d.per_fixed = Math.round(d.base_cost/d.total*100*10)/10;
      });

  //grap selected rates
  var selInsideRates = costCSV.filter(function(d) {return d.pwsid === selectSystem && d.category==="inside"; });
  var selOutsideRates = costCSV.filter(function(d) {return d.pwsid === selectSystem && d.category==="outside"; });
     
  //continue to filter based on selection
  costCSV = costCSV.filter(el => {
      return selCSV.find(element => { return element.pwsid === el.pwsid;  });
  });
  
  
  //filter to inside and outside
  var insideRates = costCSV.filter(function(d) {return d.category === "inside"; });
  var outsideRates = costCSV.filter(function(d) {return d.category === "outside" & d.total > 0; });
  var selName = utilityDetails.filter(function(d) {return d.pwsid === selectSystem})
 // console.log(insideRates);
  
 if(selInsideRates.length>0){
//PLOTLY BAR CHART OF RATES
  var xValue = [selName[0].service_area.substring(0,20)+"..."];
  var waterBill = [selInsideRates.filter(function(d){return d.service==="water";})[0].total];
  var sewerBill = [selInsideRates.filter(function(d){return d.service==="sewer";})[0].total];
  var stormBill = [selInsideRates.filter(function(d){return d.service==="storm";})[0].total];

  var insideTotal = selInsideRates.filter(function(d){return d.service==="total";})[0].total + selInsideRates.filter(function(d){return d.service==="storm";})[0].total;
  var chartTitle = "Total bill at " + selectVolume.toLocaleString() + " gallons for " + selName[0].service_area + " is ~$" + insideTotal.toFixed(0);
               
if(selOutsideRates.length > 0){
  xValue = ["Inside Bill", "Outside Bill"];
  waterBill.push(selOutsideRates.filter(function(d){return d.service==="water";})[0].total);
  sewerBill.push(selOutsideRates.filter(function(d){return d.service==="sewer";})[0].total);
  stormBill.push(0);

  var outsideTotal = selOutsideRates.filter(function(d){return d.service==="total";})[0].total;
  chartTitle = chartTitle + "<span style='font-size: 12px;'>,<br>outside municipal boundaries the bill is $" + 
               outsideTotal.toFixed(0) + "</span>";
}

  var maxY1 = selInsideRates.map(function(d){return d.total;});
  var maxY2 = selOutsideRates.map(function(d){return d.total;});
    if (maxY2.length == 0) { maxY2 = [0]; }
  var maxY = Math.max(d3.max(maxY1), d3.max(maxY2));

//PLOTLY BAR CHART OF RATES
var waterBillTrace = {
    x: xValue, y: waterBill,
    type: "bar",   name: "drinking water",
    hovertemplate: '$%{y} each month',
    marker: {color: "#00578a"},
  };

  var sewerBillTrace = {
      x: xValue, y:sewerBill,
      type: "bar",  name: "wastewater",
      hovertemplate: '$%{y} each month',
      marker: {color: "#8a3300"},
    };

  var stormBillTrace = {
      x: xValue, y:stormBill,
      type: "bar", name: "stormwater",
      marker: {color: "#556b2f"},
      hovertemplate: '$%{y} each month',
   };

var layout2 = {
   title: { 
    text: chartTitle,
    font: {size: 14}
  },

    yaxis: {
        title: 'Household Monthly Bill ($)',
        titlefont: {color: 'rgb(0, 0, 0)', size: 14 },
        tickfont: {color: 'rgb(0, 0, 0)', size: 12},
        showline: false,
        showgrid: true,
        showticklabels: true,
        range: [0, maxY+20]
    },
    xaxis: {
      showline: false,
      showgrid: false,
      showticklabels: true,
      title: '',
      titlefont: {color: 'rgb(0, 0, 0)', size: 14},
      tickfont: {color: 'rgb(0, 0, 0)', size: 12},
    },
    height: 350,
    barmode: "stack",
    showlegend: true,
    legend: {x: 0.95, y: 0.98, xanchor: 'left', orientation: "v" },
    margin: { t: 70,   b: 30,  r: 40,   l: 45  },
};

  data2 = [waterBillTrace, sewerBillTrace, stormBillTrace];
  Plotly.newPlot('monthBillChart', data2, layout2, configNoAutoDisplay);
}//end if selectSystem !== "none"

if(selectSystem === "none"){
  document.getElementById('monthBillChart').innerHTML = "";
}
//##############################################################################################################

// Plot boxplots based on if they select water or wastewater
//##############################################################################################################
//                      BOXPLOT TO SHOW RANGE OF RATES
//##############################################################################################################
//pull out selected rates
var selColorType; var selColorOutType;

  if (selWaterType === "water") { 
    selColorType = "blue";
    selColorOutType = "#9d9dff";
  }
  if (selWaterType === "sewer") { 
    selColorType = "#8a3300";
    selColorOutType = "#ff9d63";
  }
var xFixed; var xVariable; var xPercentFixed; var xMonth; var xSurcharge;
var xSelFixed; var xSelVariable; var xSelPercentFixed; var xSelMonth; var xSelSurcharge; var xSelLegend;
var xOSelFixed; var xOSelVariable; var xOSelPercentFixed; var xOSelMonth; var xOSelSurcharge;

var yFixed = ["Fixed <br> Charge ($) "];   var xFixedColor = [selColorType];  var xSize = [12];
var yCommodity = ["Usage <br> Charge ($) "];
var yperFixed = ["% Fixed"];
var ySurcharge = ["Surcharge <br> Charge ($) "];
var yMonth = ["Monthly <br> Bill ($) "];

//use costCSV to get both inside and outside rates
var waterInside = costCSV.filter(function(d){return d.service === selWaterType; });
var waterSelInside = selInsideRates.filter(function(d){return d.service === selWaterType; });

//var waterOutside = outsideRates.filter(function(d){return d.service === selWaterType; });
var waterSelOutside = selOutsideRates.filter(function(d) {return d.service === selWaterType; });

//set variables
    xFixed = waterInside.map(function(d) { return d.base_cost;});
    xVariable = waterInside.map(function(d) {return d.total_vol; });
    xPercentFixed = waterInside.map(function(d) {return d.per_fixed; });
    xSurcharge = waterInside.map(function(d) {return d.total_surcharge; });
    xMonth = waterInside.map(function(d) {return d.total; });

if (selectSystem !== "none"){
    xSelFixed = [waterSelInside[0].base_cost];
    xSelVariable = [waterSelInside[0].total_vol];
    xSelPercentFixed = [waterSelInside[0].per_fixed];
    xSelSurcharge = [waterSelInside[0].total_surcharge];
    xSelMonth = [waterSelInside[0].total];
    xSelLegend = ["selected: all or inside rates"];
  
  if (selOutsideRates.length > 0){
      xOSelFixed = waterSelOutside[0].base_cost;
      xSelFixed.push(xOSelFixed);   yFixed.push(yFixed[0]);  xFixedColor.push(selColorOutType);  xSize.push(8);

      xOSelVariable = waterSelOutside[0].total_vol;
      xSelVariable.push(xOSelVariable); yCommodity.push(yCommodity[0]);

      xOSelPercentFixed = waterSelOutside[0].per_fixed; 
      xSelPercentFixed.push(xOSelPercentFixed);   yperFixed.push(yperFixed[0]);
   
      xOSelSurcharge = waterSelOutside[0].total_surcharge;
      xSelSurcharge.push(xOSelSurcharge);   ySurcharge.push(ySurcharge[0]);

      xOSelMonth = waterSelOutside[0].total;
      xSelMonth.push(xOSelMonth);   yMonth.push(yMonth[0]);
      xSelLegend.push("selected: outside rates");
  }
}
//console.log(xSelVariable); console.log(xSelPercentFixed);

//CREATE PLOT
  var fixedtrace = {
    y: "Fixed Charge ($)",  x: xFixed,
    marker: {color: '#00578a', size: 2},
    opacity: 0.6,
    type: 'box',   boxpoints: 'all',   
    name: "Fixed <br> Charge ($) ",
    showlegend: false
  };
  
  var selFixedtrace = {
      y: yFixed,      x: xSelFixed,
      marker: { color: xFixedColor, size: xSize, line: {color: 'black', width: 2 },   },
      line: {width: 0, opacity: 0},
      hovertemplate: "$%{x} of monthly bill is fixed",
      type: "markers",    opacity: 1,  text: xSelLegend, 
      showlegend: false
  };

  var percentFixedtrace = {
      y: "Percent Fixed",  x: xPercentFixed,
      marker: {color: '#8a3300', size: 2},  opacity: 0.6,
      type: 'box',    boxpoints: 'all',      
      name: "% Fixed",
      showlegend: false
  };

  var selPerFixedtrace = {
      y: yperFixed,     x: xSelPercentFixed,
      marker: {color: xFixedColor, size: xSize,  line: {color: 'black', width: 2 },   },
      line: {width: 0, opacity: 0},
      hovertemplate: "%{x}% of monthly bill is fixed",
      opacity: 1, type: "markers",   name: "", showlegend: false
  };

  var variabletrace = {
      y: "Usage Charge ",  x: xVariable,
      marker: {color: '#00578a', size: 2},     opacity: 0.6,
      type: 'box',      boxpoints: 'all',      showlegend: false,
      name: "Usage <br> Charge ($) "
  };

  var selVariabletrace = {
      y: yCommodity,      x: xSelVariable,
      marker: {      color: xFixedColor, size: xSize,  line: {color: 'black', width: 2 },  },
      line: {width: 0, opacity: 0},
      hovertemplate: "$%{x} of bill based on usage",
      opacity: 1, type: "marker",      name: "", showlegend: false
  };

  var surchargetrace = {
      y: "Surcharge Charge",    x: xSurcharge,
      marker: {color: '#00578a', size: 2},      opacity: 0.6,
      type: 'box',      boxpoints: 'all',      showlegend: false,
      name: "Surcharge <br> Charge ($) "
  };

  var selSurchargetrace = {
      y: ySurcharge,      x: xSelSurcharge,
      marker: { color: xFixedColor, size: xSize,  line: {color: 'black', width: 2 },      },
      line: {width: 0, opacity: 0},
      hovertemplate: "$%{x} of monthly bill is a surcharge",
      opacity: 1, type: "markers",      name: "", showlegend: false
  };

  var monthtrace = {
      y: "Monthly Bill",      x: xMonth,      marker: {color: '#00578a', size: 2},
      opacity: 0.6,      type: 'box',      boxpoints: 'all',      showlegend: false,
      name: "Monthly <br> Bill ($) "
  };

  var selMonthtrace = {
      y: yMonth,      x: xSelMonth,
      marker: {color: xFixedColor, size: xSize,  line: {color: 'black', width: 2 },     },
      line: {width: 0, opacity: 0},
      hovertemplate: "$%{x} is the monthly bill",
      opacity: 1, type: "markers",   name: "selected: inside or all rates",
      showlegend: true
  };

  var selWaterType2;
  if(selWaterType === "water"){ selWaterType2 = "drinking water"; }
  if(selWaterType === "sewer"){ selWaterType2 = "wastewater"; }
  var boxTitle = "Rate components for " + selWaterType2;

  var layout3 = {
    title: { 
    text: boxTitle,
    font: {size: 14}
  },
    yaxis: {
        title: '',
        titlefont: {color: 'rgb(0, 0, 0)', size: 14 },
        tickfont: {color: 'rgb(0, 0, 0)', size: 12},
        showline: false,  showgrid: false,    showticklabels: true,
    },
    xaxis: {
      showline: false,      showgrid: true,      showticklabels: true,
      title: '<span style="color: #00578a">Bill ($)</span> or <span style="color: #8a3303">Percent</span>',
      titlefont: {color: 'rgb(0, 0, 0)', size: 14},
      tickfont: {color: 'rgb(0, 0, 0)', size: 12},
    //  range: [0, 100]
    },
    height: 400,
    showlegend: false,
    //legend: {x: 1, y: 0.5, xanchor: 'right'},
    margin: {t: 70,   b: 30,  r: 30,  l: 75},
    fixedrange: false,

    shapes: [
        //legend circles and boxes
          { type: 'circle', xref: 'paper', yref: 'paper', //ref is assigned to x values
            x0: 0.75, x1: 0.775, y0: 0.57, y1: 0.60,
            line: {color: 'black', width: 1},
            fillcolor: selColorType
          },
          { type: 'circle', xref: 'paper', yref: 'paper', //ref is assigned to x values
            x0: 0.75, x1: 0.775, y0: 0.49, y1: 0.52,
            line: {color: 'black', width: 1},
            fillcolor: selColorOutType
          },
          { type: 'circle', xref: 'paper', yref: 'paper',
            x0: 0.76, x1:0.77, y0: 0.66, y1: 0.67,
            fillcolor: '#00578a',
            line: {color: 'black', width: 0}
          }
    ],
     annotations: [
          { xref: 'paper', yref: 'paper', x: 0.8, y: 0.69, xanchor: 'left', yanchor: 'top',
            text: "all utilities",
            font: {family: 'verdana', size: 11, color: '#00578a'},
            showarrow: false
          },
          { xref: 'paper', yref: 'paper', x: 0.8, y: 0.63, xanchor: 'left', yanchor: 'top',
            text: "selected: inside<br>       or all rates",
            font: {family: 'verdana', size: 11, color: selColorType},
            showarrow: false
          },
          { xref: 'paper', yref: 'paper', x: 0.8, y: 0.55, xanchor: 'left', yanchor: 'top',
            text: "selected: outside <br>          rates",
            font: {family: 'verdana', size: 11, color: selColorOutType}, 
            showarrow: false
          },
    ]
  };

 if (selectSystem === "none"){
  data3 = [percentFixedtrace, fixedtrace, variabletrace, surchargetrace, monthtrace];
}
if (selectSystem !== "none"){
  data3 = [percentFixedtrace, selPerFixedtrace, fixedtrace, selFixedtrace, variabletrace, selVariabletrace, 
          surchargetrace, selSurchargetrace, monthtrace, selMonthtrace];
}
Plotly.newPlot('boxRateChart', data3, layout3, configNoAutoDisplay);
});//end D3



//##############################################################################################################

// PLOT COMMODITY CHARGE COMPARISON BASED ON VOLUME
d3.csv("data/commodity_price.csv").then(function(price){
    price.forEach(function(d){
        d.commodity_unit_price = +d.commodity_unit_price;
        d.hh_use = +d.hh_use;
        d.total = +d.total;
      });

//pull out selected system
var selPriceInside = price.filter(function(d){ return d.pwsid === selectSystem && d.service===selWaterType && d.category==="inside"; });
var selPriceOutside = price.filter(function(d){ return d.pwsid === selectSystem && d.service===selWaterType && d.category==="outside"; });

//continue to filter based on selection
//filter by map selections
price = price.filter(el => {
  return selCSV.find(element => { return element.pwsid === el.pwsid; });
});
  
//filter less than 0.20 to save space
priceAll = price.filter(function(d){ return d.service === selWaterType && d.pwsid !== selectSystem; });

//pull out selected rates
var selColorType; var selColorOutType;

  if (selWaterType === "water") { 
    selColorType = "blue";
    selColorOutType = "#9d9dff";
  }
  if (selWaterType === "sewer") { 
    selColorType = "#8a3300";
    selColorOutType = "#ff9d63";
  }
//pull out selected state
var dataPrice = [];
var xUse = [0, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000, 11000, 12000, 13000, 14000, 15000, 16000];

var pwsidOther = priceAll.filter(function(d) {return d.hh_use === 4000; });
pwsidOther = pwsidOther.map(function(d) {return d.pwsid; });
var yOther = [];    var insideTrace; 
var legendShow;
for (i=0; i < pwsidOther.length; i++){
  tempSelect = pwsidOther[i];
  temp = priceAll.filter(function(d) {return d.pwsid === tempSelect; });
  //tempName = temp.map(function(d) {return d.service_area.substring(0,15) + ", " + d.state.toUpperCase(); });
  tempName = tempSelect;
  yOther = temp.map(function(d){ return d.commodity_unit_price; });
  if (i===0) {legendShow = true; }
  if (i > 0) {legendShow = false; }
 //create individual trace
    insideTrace = 
        {
          x: xUse,   y: yOther,
          mode: 'lines', type: 'scatter',
          hovertemplate: tempName,
          opacity: 0.4,
          line: {color: '#c5c5c5', width: 1}, //light coral
          showlegend: legendShow,
          name: "all utilities"
        };
  //push trace
  dataPrice.push(insideTrace);
} // end for loop

//draw selected price
var selyin; var selTrace;
var selyout; var selOutTrace;
var selName = utilityDetails.filter(function(d) {return d.pwsid === selectSystem})

if (selPriceOutside.length > 0 ) {
  selyout = selPriceOutside.map(function(d) {return d.commodity_unit_price; });

  selOutTrace = {
    y: selyout,  x: xUse,
    marker: {size: 8, color: selColorOutType, line: {color: 'black', width: 1} },
    line: {color: selColorOutType, width: 3},
    mode: 'lines+markers',  type: 'scatter',  name: selName[0].service_area.substring(0,6)+"...",
    hovertemplate: '$%{y} per 1k gallons <br> at %{x} gallons',
    showlegend: true,
    name: 'selected: outside usage rates'
  };

  dataPrice.push(selOutTrace);
}

if (selPriceInside.length > 0 ) {
  //for (i=0; i < selPriceInside.length; i++){
    //tempSelect = 
  selyin = selPriceInside.map(function(d) {return d.commodity_unit_price; });
    selTrace = {
      y: selyin,  x: xUse,
      marker: {size: 8, color: selColorType, line: {color: 'black', width: 1} },
      line: {color: selColorType, width: 3},
      mode: 'lines+markers',  type: 'scatter',  name: selName[0].service_area.substring(0,6)+"...",
      hovertemplate: '$%{y} per 1k gallons <br> at %{x} gallons',
      legend: "true",
      name: "selected: inside or all usage rates"
    };
  //}// end selTrace Loop

  dataPrice.push(selTrace);
}


var layoutPrice = {
  title: { 
    text: "Usage cost per 1,000 gallons of water",
    font: {size: 14}
  },
    yaxis: {
        title: 'Cost per thousand gallons ($)',
        titlefont: {color: 'rgb(0, 0, 0)', size: 14 },
        tickfont: {color: 'rgb(0, 0, 0)', size: 12},
        showline: false,  showgrid: true, showticklabels: true,
        range: [0, 20]
    },
    xaxis: {
      showline: false,  showgrid: true,  showticklabels: true,
      title: 'Volume of water (gallons)',
      titlefont: {color: 'rgb(0, 0, 0)', size: 14},
      tickfont: {color: 'rgb(0, 0, 0)', size: 12},
      range: [0, 16000]
    },
    hovermode: 'closest',
    height: 400,
    showlegend: true,
    legend: {orientation: "h", x: 0, y: 1}, 
    margin: { t: 70,   b: 30,  r: 30,   l: 40  },
};

Plotly.newPlot('commodityChart', dataPrice, layoutPrice, configNoAutoDisplay);
});//end d3 for commodity



}//end plotRates function
//plotRates("NC0332010", selectVolume, selWaterType);
//plotRates("PA5650032", selectVolume);



