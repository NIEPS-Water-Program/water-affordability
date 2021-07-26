///////////////////////////////////////////////////////////////////////////////////////////////////
//
//                      IDWS GRAPHIC SCRIPT                              ///////////////
////                   
///////////////////////////////////////////////////////////////////////////////////////////////////

function togglePlots(target){
  //lets make a variable that decides whether to draw a plot or table//
  var x = document.getElementById("switchDiv").checked;
  if (x === true) { 
    selectPlotType = "table";
    document.getElementById('idwsText').style.display="none";
  }
  if (x === false) { 
    selectPlotType = "plot";
    document.getElementById('idwsText').style.display="block";
  }
  
  document.getElementById('costBillChart').innerHTML = "";
  plotCostBill(selectSystem, selectVolume, selectPlotType);
  
  return selectPlotType;
}


/*########################################################################################################3
#
#
##########################################################################################################3*/
function plotCostBill(selectSystem, selectVolume, selectPlotType) {
//read in csv 
 d3.csv("data/IDWS/idws_"+selectVolume+".csv").then(function(costCSV){
            costCSV.forEach(function(d){
              d.percent_income = +d.percent_income;
              d.annual_cost = +d.annual_cost;
              d.percent_pays_more = +d.percent_pays_more;
            });

//pull out selected system
var selCostInside = costCSV.filter(function(d){ return d.pwsid === selectSystem && d.category === "inside"; });
var selCostOutside = costCSV.filter(function(d){ return d.pwsid === selectSystem && d.category === "outside"; });

//console.log(selCostInside)
if (selCostInside.length > 0) {  
  var selName = utilityDetails.filter(function(d) {return d.pwsid === selectSystem})
      .map(function(d) { return d.service_area});

    document.getElementById('costBillTitle').innerHTML = "Income Dedicated to Water Services for " + selName +
      " at an annual cost of $" + numberWithCommas(selCostInside[0].annual_cost.toFixed(0));
    }

//continue to filter based on selection
costCSV = costCSV.filter(el => {
  return selCSV.find(element => { return element.pwsid === el.pwsid; });
});

//filter less than 0.20 to save space
costInside = costCSV.filter(function(d){ return d.category === "inside" && d.pwsid !== selectSystem; });
costOutside = costCSV.filter(function(d){ return d.category === "outside" && d.pwsid !== selectSystem; });

if (selectPlotType === "plot"){
    //pull out selected state
    var data = [];
    var xPercent = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];

    var pwsidAll = costOutside.filter(function(d) {return d.percent_income==1;});
    pwsidAll = pwsidAll.map(function(d) {return d.pwsid; });
    var yAll2 = [];   var outsideTrace; var legendOnOff;
    for (i=0; i < pwsidAll.length; i++){
      tempSelect = pwsidAll[i];
      temp = costOutside.filter(function(d) {return d.pwsid === tempSelect; });
      //tempName = temp.map(function(d) {return d.service_area.substring(0,6) + "..., " + d.state.toUpperCase() + " outside rates"; });
      tempName = tempSelect// + " outside rates";
      yAll2 = temp.map(function(d){ return d.percent_pays_more; });
      if (i==0) {legendOnOff = true; }//console.log("draw legend")} 
        else {legendOnOff = false; }
      //create individual trace
        outsideTrace = 
            {
              x: xPercent,   y: yAll2,
              mode: 'lines', type: 'scatter', name: "",
              hovertemplate: tempName,  opacity: 0.5,
              line: {color: 'rgba(0,87,138,0.4)', width: 1.5}, //light coral
              name: "outside rates",
              showlegend: legendOnOff,
            };
      //push trace
    data.push(outsideTrace);
    } // end for loop

    // create all traces for inside state
    pwsidAll = costInside.filter(function(d) {return d.percent_income==1;});
    pwsidAll = pwsidAll.map(function(d) {return d.pwsid; });
    var yAll = [];  var insideTrace;
    for (i=0; i<pwsidAll.length; i++){
      tempSelect = pwsidAll[i];
      temp = costInside.filter(function(d) {return d.pwsid === tempSelect; });
      //tempName = temp.map(function(d) {return d.service_area.substring(0,6)  + ", " + d.state.toUpperCase() + " inside rates"; });
      tempName = tempSelect// + " inside rates"
      yAll = temp.map(function(d){ return d.percent_pays_more; });
      if (i==0) {legendOnOff = true;} 
                 else {legendOnOff = false; }
     
      //create individual trace
        insideTrace = 
            {
              x: xPercent,   y: yAll,
              mode: 'lines', type: 'scatter', name: "",
              hovertemplate: tempName,
              opacity: 0.5,
              line: {color: '#d4ebf2', width: 1.5}, //light blue
              name: "inside rates",
              showlegend: legendOnOff
            };
      //push trace
    data.push(insideTrace);
    } // end for loop


    //calculate median value
    var yMedian = []; var medVal;
    for(i=0; i<xPercent.length; i++){
      temp = costCSV.filter(function(d) {return d.percent_income === xPercent[i]; });
      yAll = temp.map(function(d){ return d.percent_pays_more; });
      yAll.sort(function(a,b){return a-b; });
      medVal = Math.round(d3.quantile(yAll, 0.50)*10)/10;
      yMedian.push(medVal);   
    }
    //yMedian.unshift(100);

    //selected - draw all as present----------------------------------------------------------------
    var selyall; 
    if (selCostInside.length > 0 ) {
      selyall = selCostInside.map(function(d) {return d.percent_pays_more; });
    //  selyall.unshift(100);
    }

    var selyall2; 
    if (selCostOutside.length > 0 ) {
      selyall2 = selCostOutside.map(function(d) {return d.percent_pays_more; });
    }

    //grab values for annotation
    var y4annot; var y7annot; var y10annot; var y4annotText; var y7annotText; var y10annotText;
    if (selCostInside.length > 0) {
      y4annot = selyall[2].toFixed(1);  
        y4annotText = selyall[2].toFixed(1) + "% of homes spend more than <br> 2% of income on water services";  
      y7annot = selyall[4].toFixed(1); 
        y7annotText = selyall[4].toFixed(1) + "% of homes spend more than <br> 4% of income on water services"; 
      y10annot = selyall[7].toFixed(1);
        y10annotText = selyall[7].toFixed(1) + "% of homes spend more than <br> 7% of income on water services";
    }


    //account for no selection made
    if (selCostInside.length === 0) {
      y4annotText = "select system"; y7annotText = "select system"; y10annotText = "select system";
      y4annot = 65; y7annot = 50; y10annot = 35;
    }

    var medtrace = {
      y: yMedian,  x: xPercent,
      marker: {size: 6, color: '#5d5d5d'},
      line: {color: '#5d5d5d', width: 6},
      mode: 'lines+markers',
      type: 'scatter',
      name: 'median',
      hovertemplate: 'Median: %{y}% houses spending more than %{x}% of income',
      showlegend: true,
    };


    var seltrace = {
      y: selyall,  x: xPercent,
      marker: {
        size: 8, color: "blue",
        line: {color: 'black', width: 1}
        },
      line: {color: 'blue', width: 3},
      mode: 'lines+markers',
      type: 'scatter',
      name: 'selected: all or inside rates',
      hovertemplate: '%{y}% houses spending more than %{x}% of income',
      showlegend: true
    };

    var selouttrace = {
      y: selyall2,  x: xPercent,
      marker: {
        size: 8, color: "#00578a",
        line: {color: 'black', width: 1}
        },
      line: {color: '#00578a', width: 3, dash: "dashdot"},
      mode: 'lines+markers',
      type: 'scatter',
      name: 'selected: outside rates',
      hovertemplate: '%{y}% houses spending more than %{x}% of income',
      showlegend: true
    };

    var layout = {
        yaxis: {
            title: 'Percent of households paying more',
            titlefont: {color: 'rgb(0, 0, 0)', size: 14 },
            tickfont: {color: 'rgb(0, 0, 0)', size: 12},
            showline: false,
            showgrid: true,
            showticklabels: true,
            range: [0, 100]
        },
        xaxis: {
          showline: false,
          showgrid: true,
          showticklabels: true,
          title: 'Percent of income going to water services',
          titlefont: {color: 'rgb(0, 0, 0)', size: 14},
          tickfont: {color: 'rgb(0, 0, 0)', size: 12},
          range: [0, 15]
        },
        hovermode: 'closest',
        height: 400,
        //showlegend: false,
        legend: {x: 1, y: 1, xanchor: 'right'},
        margin: { t: 30,   b: 30,  r: 40,   l: 40  },

        shapes: [
          //days
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
       ],
  
      annotations: [
          //days
            { xref: 'x', yref: 'paper', //ref is assigned to x values
              x: 2.3, y: 1,
              xanchor: 'middle', yanchor: 'top',
              text: "< 1 day", 
              font: {family: 'verdana', size: 11, color: '#001b1b'},
              showarrow: false
            },
            { xref: 'x', yref: 'paper', //ref is assigned to x values
              x: day1+2.3, y: 1,
              xanchor: 'middle', yanchor: 'top',
              text: "1-2 days", 
              font: {family: 'verdana', size: 11, color: '#001b1b'},
              showarrow: false
            },
            { xref: 'x', yref: 'paper', //ref is assigned to x values
              x: day1*2+2.3, y: 1,
              xanchor: 'middle', yanchor: 'top',
              text: "2-3 days", 
              font: {family: 'verdana', size: 11, color: '#001b1b'},
              showarrow: false
            },
            { xref: 'x', yref: 'paper', //ref is assigned to x values
              x: day1*3+2.3, y: 1,
              xanchor: 'middle', yanchor: 'top',
              text: "3-4 days", 
              font: {family: 'verdana', size: 11, color: '#001b1b'},
              showarrow: false
            },
            { xref: 'x', yref: 'paper', //ref is assigned to x values
              x: day1*4+2.3, y: 1,
              xanchor: 'middle', yanchor: 'top',
              text: ">4 days", 
              font: {family: 'verdana', size: 11, color: '#001b1b'},
              showarrow: false
            },

            //4% threshold
              { xref: 'x', yref: 'y', //ref is assigned to x values
                x: 2, y: y4annot,
                axref: 'x', ayref: 'y', ax: 5, ay: 85,  //draws arrow
                xanchor: 'left', yanchor: 'bottom',
                text: y4annotText, 
                font: {family: 'verdana', size: 11, color: 'blue'},
                showarrow: true,
                arrowcolor: 'blue',
                arrowhead: 5//arrowhead style
              },

              //7% threshold
              { xref: 'x', yref: 'y', //ref is assigned to x values
                x: 4, y: y7annot,
                axref: 'x', ayref: 'y', ax: 8, ay: 70,  //draws arrow
                xanchor: 'left', yanchor: 'bottom',
                text: y7annotText, 
                font: {family: 'verdana', size: 11, color: 'blue'},
                showarrow: true,
                arrowcolor: 'blue',
                arrowhead: 5//arrowhead style
              },

              //10% threshold
              { xref: 'x', yref: 'y', //ref is assigned to x values
                x: 7, y: y10annot,
                axref: 'x', ayref: 'y', ax: 11, ay: 55,  //draws arrow
                xanchor: 'left', yanchor: 'bottom',
                text: y10annotText, 
                font: {family: 'verdana', size: 11, color: 'blue'},
                showarrow: true,
                arrowcolor: 'blue',
                arrowhead: 5//arrowhead style
              },
        ]
      };

    data.push(medtrace);

    if (selCostInside.length > 0) {  
      data.push(seltrace);  
      document.getElementById('idwsText').innerHTML = "The metric shows how many households share a similar financial burden in the utility in terms of the annual income going to pay for water services. Each 4.6% of income represents roughly a day of labor. This metric allows utilities to see the breadth of affordability challenges given estimated water bills and the distribution of household incomes in the service area.";
    } 
    if (selectSystem !== "none" & selCostInside.length ===0) {
      document.getElementById('idwsText').innerHTML = "The metric shows how many households share a similar financial burden in the utility in terms of the annual income going to pay for water services. Each 4.6% of income represents roughly a day of labor. This metric allows utilities to see the breadth of affordability challenges given estimated water bills and the distribution of household incomes in the service area." + 
      "<br><br><span style='font-size: 20px; font-weight: bold; color: rgb(252,57,67)'>The area of this utility was too small for this analysis.";
   }

    if (selCostOutside.length > 0) {  data.push(selouttrace); }

    Plotly.newPlot('costBillChart', data, layout, config);
}// end if selectPlotType === "plot"

if(selectPlotType === "table"){
  if(selectSystem != "none"){
      //CREATE TABLE SUMMARIZING BY INCOME BRACKETS
        sel_hh = demData.filter(function(d) {return d.pwsid === selectSystem; });
  //      console.log(sel_hh);

      //create table
        var myTable = "<br><table class='table table-bordered table-striped'>";
        //create column header
        myTable += "<thead><tr>";
        myTable += "<th>Income Range</th>";
        myTable += "<th>Percent of<br>Households in Income Range</th>";
        myTable += "<th>Cumulative Percent of<br>Households in Income Range</th>";
        if (selCostOutside.length===0) { myTable += "<th>Percent of Income<br>to Water Services</th>"; }
        if (selCostOutside.length > 0) { 
          myTable += "<th>Percent of Income<br>to Water Services<br>(Inside)</th>"; 
          myTable += "<th>Percent of Income<br>to Water Services<br>(Outside)</th>"; 
        }
        
      //end header and start body to loop through by activity
      myTable += "</thead><tbody'>";
     
      //tables fill by rows not columns
      var incomeText = ["Less than $25,000", "$25,000 to $49,999", "$50,000 to $74,999", "$75,000 to $99,999",
      "$100,000 to $124,999", "$125,000 to $149,999", "More than $150,000"];

      var hhBracket = [sel_hh[0].d0to24k, sel_hh[0].d25to49k, sel_hh[0].d50to74k, sel_hh[0].d75to100k, sel_hh[0].d100to125k,
      sel_hh[0].d125to150k, sel_hh[0].d150kmore];

      var cumBracket = [sel_hh[0].d0to24k, sel_hh[0].d0to24k+sel_hh[0].d25to49k, sel_hh[0].d0to24k+sel_hh[0].d25to49k+sel_hh[0].d50to74k, 
      sel_hh[0].d0to24k+sel_hh[0].d25to49k+sel_hh[0].d50to74k+sel_hh[0].d75to100k, 
      sel_hh[0].d0to24k+sel_hh[0].d25to49k+sel_hh[0].d50to74k+sel_hh[0].d75to100k+sel_hh[0].d100to125k,
      sel_hh[0].d0to24k+sel_hh[0].d25to49k+sel_hh[0].d50to74k+sel_hh[0].d75to100k+sel_hh[0].d100to125k+sel_hh[0].d125to150k, 
      sel_hh[0].d0to24k+sel_hh[0].d25to49k+sel_hh[0].d50to74k+sel_hh[0].d75to100k+sel_hh[0].d100to125k+sel_hh[0].d125to150k+sel_hh[0].d150kmore];

      var annualCost = selCostInside[0].annual_cost;
      
      var insideBracketMed = [annualCost/12500*100, annualCost/37500*100, annualCost/62500*100, annualCost/87500*100,
                            annualCost/112500*100, annualCost/137500*100, annualCost/162500*100];

      var insideBracketMin = [annualCost/25000*100, annualCost/50000*100, annualCost/75000*100, annualCost/100000*100,
                            annualCost/125000*100, annualCost/150000*100, annualCost/500000*100];

      var insideBracketMax = [100, annualCost/25000*100, annualCost/50000*100, annualCost/75000*100,
                            annualCost/100000*100, annualCost/125000*100, annualCost/150000*100];

      if (selCostOutside.length > 0){
        var annualOutCost = selCostOutside[0].annual_cost;
        var outsideBracketMed = [annualOutCost/12500*100, annualOutCost/37500*100, annualOutCost/62500*100, annualOutCost/87500*100,
                            annualOutCost/112500*100, annualOutCost/137500*100, annualOutCost/162500*100];
        var outsideBracketMin = [annualOutCost/25000*100, annualOutCost/50000*100, annualOutCost/75000*100, annualOutCost/100000*100,
                            annualOutCost/125000*100, annualOutCost/150000*100, annualOutCost/500000*100];

        var outsideBracketMax = [100, annualOutCost/25000*100, annualOutCost/50000*100, annualOutCost/75000*100,
                            annualOutCost/100000*100, annualOutCost/125000*100, annualOutCost/150000*100];  
      }
      

      if(sel_hh[0].keep!=="keep"){ 
        for (i = 0; i < hhBracket.length; i++) { 
          hhBracket[i] = "No Data";  
          cumBracket[i] = "No Data";  
        }
      }
      //console.log(insideBracket);

      for (i = 0; i < hhBracket.length; i++) {
        myTable += "<tr>";
        //add income range
        myTable += "<td>" + incomeText[i] +"</td>";  
        //add percent of households
        if(sel_hh[0].keep === "keep"){
           myTable += "<td>" + hhBracket[i].toFixed(1) +"%</td>";  
           myTable += "<td>" + cumBracket[i].toFixed(1) +"%</td>";  
        } else {
          myTable += "<td>" + hhBracket[i] +"</td>";  
          myTable += "<td>" + cumBracket[i] +"</td>";  
        }

        //add percent income
        //myTable += "<td>" + insideBracketMin[i].toFixed(1) + " to " + insideBracketMax[i].toFixed(1) + "</td>";  
        if (i===0){myTable += "<td>More than " + insideBracketMin[i].toFixed(1) + "%"; }
        if (i > 0 & i < (hhBracket.length-1)) {
          //myTable += "<td>" + insideBracketMed[i].toFixed(1) + " &plusmn; " + ((insideBracketMax[i]-insideBracketMin[i])/2).toFixed(1) + "</td>";  
          myTable += "<td>" + insideBracketMed[i].toFixed(1) + "% (range: " + insideBracketMin[i].toFixed(1) + " to " + insideBracketMax[i].toFixed(1) + "%)</td>";  
        }        
        if (i===(hhBracket.length-1)){myTable += "<td>Less than " + insideBracketMax[i].toFixed(1) + "%"; }

        if(selCostOutside.length > 0){
          if (i===0){myTable += "<td>More than " + outsideBracketMin[i].toFixed(1) + "%"; }
          if (i > 0 & i < (hhBracket.length-1)) {
            //myTable += "<td>" + outsideBracketMed[i].toFixed(1) + " &plusmn; " + ((outsideBracketMax[i]-outsideBracketMin[i])/2).toFixed(1) + "</td>";  
            myTable += "<td>" + outsideBracketMed[i].toFixed(1) + "% (range: " + outsideBracketMin[i].toFixed(1) + " to " + outsideBracketMax[i].toFixed(1) + "%)</td>";  
          }        
          if (i===(hhBracket.length-1)){myTable += "<td>Less than " + outsideBracketMax[i].toFixed(1) +"%"; }
          
        }

        myTable += "</tr>";
      
      }//end for loop
      

       myTable += "</tbody></table><br>"; 
      if(sel_hh[0].keep==="keep"){
        document.getElementById("costBillChart").innerHTML = 
        "<br><p>This table shows the percent of households in the service area in each income range and the percent of income those households" + 
        " are spending on water services. The percent income is based on the middle of the income range.</p>" + myTable;
      } else {
        document.getElementById('costBillChart').innerHTML = 
        "<br><p>This table shows the percent of households in the service area in each income range and the percent of income those households" + 
        " are spending on water services. The percent income is based on the middle of the income range.</p>" +
        "<p style='color: rgb(252,57,67)';>This system was too small to estimate percent of households</p><br>" + myTable;
      }
     
   }//end if selected pwsid
 }//end if selectPlotType==="table"


 }); //end D3 cost bill
}
//plotCostBill("NC0332010", selectVolume);




