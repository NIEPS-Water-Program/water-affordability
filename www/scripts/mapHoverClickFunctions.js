///////////////////////////////////////////////////////////////////////////////////////////////////
//                      INTERACTIONS WITH MAP                                       ///////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

/*-------------------------------------------------------------------------------------------------------
  ////////////    CREATE HOVER OVER MAP FUNCTIONS                                             ///////////
--------------------------------------------------------------------------------------------------------*/

//create variable so info boxes disappear and reset when you are not hovering over a utility
var utilityID = null;

//create layout for plot when you hover over utility
var layoutHist = {
  title: {
    text: "Block Group Burden",
    font: { size: 12 }
  },
  yaxis: {
    title: 'Block Groups (%)',
    titlefont: { color: 'rgb(0, 0, 0)', size: 10 },
    tickfont: { color: 'rgb(0, 0, 0)', size: 10 },
    showline: false, showgrid: true, showticklabels: true,
    range: [0, 100]
  },
  xaxis: {
    showline: false, showgrid: false, showticklabels: true,
    title: '',
    titlefont: { color: 'rgb(0, 0, 0)', size: 8 },
    tickfont: { color: 'rgb(0, 0, 0)', size: 10 },
  },
  height: 173,
  width: 170,
  showlegend: false,
  margin: { t: 18, b: 30, r: 5, l: 25 },
};

var xHist = ["Low", "Low<br>Mod", "Mod<br>High", "High", "Very<br>High"];
var colHist = [afford_low, afford_low_moderate, afford_moderate_high, afford_high, afford_very_high];
var yHist = [];
var dataHist;
var histTrace;

//function for when you hover over a utility-------------------------------------------------------------------------------
map.on('mousemove', 'utilities-layer', function (e) {
  map.getCanvas().style.cursor = 'pointer';

  //check if feature exist
  if (e.features.length > 0) {
    document.getElementById('map_hover_box').innerHTML =
      '<p><b>' + e.features[0].properties.service_area + '</b> (' + e.features[0].properties.pwsid + ')<br>   has a <b>' +
      e.features[0].properties.burden +
      "</b> burden level at <b>" +
      numberWithCommas(selectVolume) + '</b> gallons' +
      '<br>Utility Size: ' + e.features[0].properties.sizeCategory +
      '<br>Owner: ' + e.features[0].properties.owner_type +
      '<br>Minimum Wage Hours: ' + Number(e.features[0].properties.LaborHrs).toFixed(1) + ' hours' +
      '<br>Household Burden (low income): ' + e.features[0].properties.HBI.toFixed(1) +
      '%<br>Poverty Prevalence: ' + e.features[0].properties.PPI.toFixed(1) +
      '%<br>Traditional (median income): ' + e.features[0].properties.TRAD.toFixed(1) + '%</p>';

    //create a bar plot
    document.getElementById('histChart').innerHTML = "";
    yHist = [e.features[0].properties.low, e.features[0].properties.low_mod, e.features[0].properties.mod_high, e.features[0].properties.high, e.features[0].properties.very_high];

    histTrace = {
      x: xHist, y: yHist,
      type: "bar", name: "block groups",
      marker: { color: colHist }, hoverinfo: 'skip'
    };

    dataHist = [histTrace];
    Plotly.newPlot('histChart', dataHist, layoutHist, { displayModeBar: false });
  }// end if hover over map

  utilityID = e.features[0].pwsid;
  if (utilityID) {
    map.setFeatureState(
      { source: 'utilities', sourceLayer: 'utilities', id: utilityID },
      { hover: true }
    ); //end setFeatureState
  }//end if UtiltiydID
}); //end map.on----------------------------------------------------------------------------------------------------------

//function for when your mouse moves off a utility -----------------------------------------------------------------------
map.on('mouseleave', 'utilities-layer', function () {
  //reset info boxes and turn off hover
  if (utilityID) {
    map.setFeatureState({
      source: 'utilities', id: utilityID
    },
      { hover: false }
    );
  }

  utilityID = null;
  document.getElementById('histChart').innerHTML = "<p>Hover over a utility</p>";
  document.getElementById('map_hover_box').innerHTML = '<p>Hover over a utility</p>';
  map.getCanvas().style.cursor = ''; //resent point
}); //end map.on---------------------------------------------------------------------------------------------------------------

/*-------------------------------------------------------------------------------------------------------
 ////////////    CREATE CLICK ON MAP FUNCTIONS                                             ///////////
--------------------------------------------------------------------------------------------------------*/
// set up if utilities-layer is clicked
map.on('click', 'utilities-layer', function (e) {
  //check if select-bkgroup-layer exists so that it doesn't keep reloading and rezooming map
  if (typeof map.getLayer('select-bkgroup-layer') !== 'undefined') {
    var f = map.queryRenderedFeatures(e.point, { layers: ['utilities-layer', 'select-bkgroup-layer'] });
    if (f.length > 1) { return; }
  }

  //if they used the geocoder to find the utility, clear it.
  geocoder.clear();
  selectSystem = e.features[0].properties.pwsid;

  //set drop down to selected value
  document.getElementById("setSystem").value = selectSystem;

  //call this function to zoom into map and load charts   
  highlightUtility(selectSystem);
});

/*---------------------- Mouse hover functions for block group layer-------------------------*/
// Function for when you hover over a block group
map.on('mousemove', 'select-bkgroup-layer', function (e) {
  map.getCanvas().style.cursor = 'pointer';

  // Check if feature exist
  if (e.features.length > 0) {
    // Create information for hover box
    document.getElementById('map_hover_box').innerHTML = '<p><strong>Block Group ID: ' + e.features[0].properties.GEOID + '</strong><br>' +
      'Households: ' + Number(e.features[0].properties.totalhh).toLocaleString() + '<br>Low Income (20%): $' +
      Number(e.features[0].properties.income20).toLocaleString() + '<br>' +
      'Median Income: $' + Number(e.features[0].properties.medianIncome).toLocaleString() +
      '<br>Household Burden (low income): ' + e.features[0].properties.HBI +
      '%<br>Poverty Prevalence: ' + e.features[0].properties.PPI +
      '%<br>Traditional (median income): ' + e.features[0].properties.TRAD +
      '%<br> Percent in Service Area: ' + Number(e.features[0].properties.perArea).toFixed(1) + '%</p>';

    // Remove block highlight if it already exists
    var blockHighlightLayer = map.getLayer("bkgroup_highlight");
    if (typeof blockHighlightLayer !== 'undefined') {
      map.removeLayer('bkgroup_highlight');
    }

    // Redraw block highlight layer for current hover
    map.addLayer({
      'id': 'bkgroup_highlight',
      'type': 'line',
      'source': 'select-bkgroup',
      'source-layer': 'block_groups_' + selectVolume,
      'filter': ['in', 'GEOID', e.features[0].properties.GEOID],
      'paint': { 'line-color': 'white', 'line-width': 3 },
    });
  }
});

//function when mouse leaves hover over block group ------------------------------------------------------------------------
map.on('mouseleave', 'select-bkgroup-layer', function (e) {
  map.removeLayer('bkgroup_highlight');
  document.getElementById('map_hover_box').innerHTML = '<p>Hover over a utility</p>';
  map.getCanvas().style.cursor = ''; //resent point 
}); //end map.on-------------------------------------------------------------------------------------------------------------

/*///////////////////////////////////////////////////////////////////////////////////////////////////////////////
                FUNCTION WHEN CLICK ON A UTILITY
 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/
function highlightUtility(selectSystem) {
  if (map.getLayer('select-utility-layer')) { map.removeLayer('select-utility-layer'); }
  //if (map.getSource('select-utility')) { map.removeSource('select-utility'); }

  if (typeof map.getLayer('select-bkgroup-layer') !== 'undefined') {
    if (typeof map.getLayer('bkgroup_highlight') !== 'undefined') {
      map.removeLayer('bkgroup_highlight');
    }
    map.removeLayer('select-bkgroup-layer');
    map.removeSource('select-bkgroup');
  }

  /*------------------------------------------------------------------------------------------
                ADD CENSUS BLOCKS OVERLAY STUFF
 -----------------------------------------------------------------------------------------*/
  // If a system is selected (might not be in drop down menu) then load appropriate mbtile for the selectVolume
  if (selectSystem !== "none") {
    // Create Filter
    var blockFilter = ["all"];

    // Apply PWSID Filter
    blockFilter.push(["==", "pwsid", selectSystem]);

    // Only Add Layers For Selected NVol (Monthly Usage) Filter
    //mapbox url varies depending on volume selected
    var select_url;
    switch (selectVolume) {
      case 0:
         select_url = 'mapbox://YOUR MAPBOX TILESET USERNAME.ID';
      break;
      case 1000:
          select_url = 'mapbox://YOUR MAPBOX TILESET USERNAME.ID';
      break;
      case 2000:
          select_url = 'mapbox://YOUR MAPBOX TILESET USERNAME.ID';
      break;
      case 3000:
        select_url = 'mapbox://YOUR MAPBOX TILESET USERNAME.ID';
      break;
      case 4000:
        select_url = 'mapbox://YOUR MAPBOX TILESET USERNAME.ID';
      break;
      case 5000:
        select_url = 'mapbox://YOUR MAPBOX TILESET USERNAME.ID';
      break;
      case 6000:
        select_url = 'mapbox://YOUR MAPBOX TILESET USERNAME.ID';
      break;
      case 7000:
        select_url = 'mapbox://YOUR MAPBOX TILESET USERNAME.ID';
      break;
      case 8000:
        select_url = 'mapbox://YOUR MAPBOX TILESET USERNAME.ID';
      break;
      case 9000:
        select_url = 'mapbox://YOUR MAPBOX TILESET USERNAME.ID';
      break;
      case 10000:
        select_url = 'mapbox://YOUR MAPBOX TILESET USERNAME.ID';
      break;
      case 11000:
        select_url = 'mapbox://YOUR MAPBOX TILESET USERNAME.ID';
      break;
      case 12000:
        select_url = 'mapbox://YOUR MAPBOX TILESET USERNAME.ID';
      break;
      case 13000:
        select_url = 'mapbox://YOUR MAPBOX TILESET USERNAME.ID';
      break;
      case 14000:
        select_url = 'mapbox://YOUR MAPBOX TILESET USERNAME.ID';
      break;
      case 15000:
         select_url = 'mapbox://YOUR MAPBOX TILESET USERNAME.ID';
      break;
      case 16000:
         select_url = 'mapbox://YOUR MAPBOX TILESET USERNAME.ID';
      break;
      default:
        select_url = 'mapbox://YOUR MAPBOX TILESET USERNAME.ID'
      break;
    } //end switch case

    map.addSource('select-bkgroup', {
      type: 'vector',
      url: select_url
    });
    map.addLayer({
      'id': 'select-bkgroup-layer',
      'type': 'fill',
      'source': 'select-bkgroup',
      'source-layer': 'block_groups_' + selectVolume,
      'filter': blockFilter,
      'paint': {
        'fill-color': [
          'match',
          ['get', 'burden'],
          'Low', '#3b80cd',
          'Low-Moderate', '#36bdcd',
          'Moderate-High', '#cd8536',
          'High', '#ea3119',
          'Very High', '#71261c',//'#a7210f',
          'Unknown', 'darkgray',
          '#ccc'
        ],
        'fill-outline-color': 'black',
        'fill-opacity': 0.7,
      }
    });

  //zoom into selected feature
    selFeature = gisSystemData.features.find(d => d.properties.pwsid === selectSystem);

  if(selectSystem !== oldSystem){
    map.fitBounds(turf.bbox(selFeature), {padding: 50});
  }
  
  //draw selected feature on the map
  map.addLayer({
    'id': 'select-utility-layer',
    'type': 'line',
    'source': 'utilities',
    'source-layer': 'water_systems_'+ selectVolume,
    'paint': {
      'line-color': 'black',
      'line-width': 5,
    },
    'filter': ["==", "pwsid", selectSystem]
  });
}//end if selectSystem !=="none"

  
// Display selected utility below filter panel
var utilityText = document.getElementById("utilityResult");
if (selectSystem === "none") {
utilityText.innerHTML = "<h4>No utility service provider found or selected.</h4>";
} else {
  myUtility = utilityDetails.filter(function (d) {
    return d.pwsid === selectSystem;
  });
  utilityText.innerHTML = "<h4>You selected " + myUtility[0].service_area + " service area (pwsid: " + selectSystem + ").</h4>";
}

  oldSystem = selectSystem;
  
  // Call other filter functions
  if (target === "#metrics") {
    createMatrix(selectSystem, matrixLegend);
    allScores(selectSystem);
    plotCostBill(selectSystem, selectVolume, selectPlotType);
  } else if (target === "#rates") {
    plotRates(selectSystem, selectVolume, selWaterType);
  } else if (target === "#census") {
    plotDemographics(selectSystem);
  }
  if (target === "#summary") {
    createSummary();
  }
 
  return oldSystem;
} // end highlight utility function
