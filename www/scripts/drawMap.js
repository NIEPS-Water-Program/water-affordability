
//--------------------------------------------------------------------------------
//Script to call button has to go after function is defined
//--------------------------------------------------------------------------------
$('button').on('click', function () {
  //since multiple overlapping layers, need to set up so that utilities don't get clicked when clicking on point
  var clickedLayer = this.id;

  if (clickedLayer.length > 0) {
    var mapLayer;
    //change visibility based on menu grabbed
    if (clickedLayer === "menuCounty") { mapLayer = "county"; }
    if (clickedLayer === "menuMuni") { mapLayer = "muni"; }
    var visibility = map.getLayoutProperty(mapLayer, 'visibility');

    // toggle layer visibility by changing the layout object's visibility property
    if (visibility === 'visible') {
      map.setLayoutProperty(mapLayer, 'visibility', 'none');
      this.style.backgroundColor = 'lightgray';
      this.style.color = "black";
    } else {
      map.setLayoutProperty(mapLayer, 'visibility', 'visible');
      this.style.backgroundColor = '#3f97a8';
      this.style.color = "white";
    } // end if for visible

    //add label text as needed
    if (mapLayer === "county") {
      if (visibility === 'none') {
        map.setLayoutProperty('county_name', 'visibility', 'visible');
      } else {
        map.setLayoutProperty('county_name', 'visibility', 'none');
      }
    }//end if mapLayer for county

    if (mapLayer === "muni") {
      if (visibility === 'none') {
        map.setLayoutProperty('muni_name', 'visibility', 'visible');
      } else {
        map.setLayoutProperty('muni_name', 'visibility', 'none');
      }
    }//end if mapLayer for muni
  }//end if clickedLayer>0 (need to do because mapbox zoom are buttons)
}); // end button script



//LOAD DROP DOWN LIST ------------------------------------------------------------------------------------------
function setDropdownValues() {
    //continue to filter based on selection
    selCSV = utilityDetails;
    if (selectState !== "none") {
        selCSV = selCSV.filter(function (d) {
            return d.state === selectState;
        });
    }
    if (selectSize !== "none") {
        selCSV = selCSV.filter(function (d) {
            return d.sizeCategory === selectSize;
        });
    }
    if (selectOwner !== "none") {
        selCSV = selCSV.filter(function (d) {
            return d.owner_type === selectOwner;
        });
    }
    //console.log(selCSV)
  var systemList = selCSV;
  document.getElementById("setSystem").options.length = 1;
  opts = document.getElementById('setSystem');
  var systemNames = systemList.map(function(d){ return d.service_area; });
  systemList.sort(function (a,b) {
     return (a.service_area < b.service_area) ? -1 : 1;
  });
  for(i=0; i< systemNames.length; i++) {
         var option = document.createElement('option');
            option.text = systemList[i].service_area + ", " + systemList[i].pwsid.substring(0,2);
            option.value = systemList[i].pwsid;
            opts.appendChild(option);
  }
  //set dropdown list to whatever is selected
  opts.value = selectSystem;

// Set Display Values
//set other values
document.getElementById("countText").innerHTML = "You selected <strong>" +  numberWithCommas(systemList.length) + "</strong> utilities";

document.getElementById('volumeText').innerHTML = "Volume: " + numberWithCommas(selectVolume) + " gallons per month";

if (selectState === "none") {
  document.getElementById('stateText').innerHTML = "State: All States";
} else {
  document.getElementById('stateText').innerHTML = "State: " + selectState.toUpperCase() + " Utilities";
}

if (selectSize === "none") {
  document.getElementById('sizeText').innerHTML = "Utility Size: All Sizes";
} else {
  document.getElementById('sizeText').innerHTML = "Utility Size: " + selectSize + " Utilities";
}

if (selectOwner === "none") {
  document.getElementById('ownerText').innerHTML = "Owner: All Owner Types";
} else {
  document.getElementById('ownerText').innerHTML = "Owner: " + selectOwner + " Utilities";
}

//console.log(selCSV)
return selCSV; //for some reason not working
};//end drop down list menu


//##############################################################################################
//                             DRAW MAP
//##############################################################################################
function drawMap() {
  //call dropdown list
  if (typeof selCSV !== 'undefined'){
    setDropdownValues();
  }
  
  var utilitiesLayer = map.getLayer('utilities-layer');
  if (typeof utilitiesLayer !== 'undefined') {
    map.removeLayer('utilities-layer');   //.removeSource('utilities'); moved source to select function and index map load
  }

  // Create Filter
  var utilityFilter = ["all"];

  // Apply State Filter
  if (selectState !== "none") {
    utilityFilter.push(["==", "state", selectState])
  }

  // Apply Select Size Filter
  if (selectSize !== "none") {
    utilityFilter.push(["==", "sizeCategory", selectSize]);
  }

  // Apply Owner Type Filter
  if (selectOwner !== "none") {
    utilityFilter.push(["==", "owner_type", selectOwner]);
  }

    map.addLayer({
      'id': 'utilities-layer',
      'type': 'fill',
      'source': 'utilities',
      'source-layer': 'water_systems_' + selectVolume,
      'minzoom': zoomThreshold,
      'filter': utilityFilter,
      'paint': {
        'fill-color': [
          'match',
          ['get', 'burden'],
          'Low', '#3b80cd',
          'Low-Moderate', '#36bdcd',
          'Moderate-High', '#cd8536',
          'High', '#ea3119',
          'Very High', '#71261c',
          '#ccc'
        ],
        'fill-outline-color': 'black',
        'fill-opacity': 0.4,
      }
    });

    highlightUtility(selectSystem);

  // Call other functions based on the tab panel that is currently open----------------------------------------------------------------
  console.log(selCSV);
  if (target === "#metrics") {
    createMatrix(selectSystem, matrixLegend);
    allScores(selectSystem);
    plotCostBill(selectSystem, selectVolume, selectPlotType);
  }

  if (target === "#rates") {
    plotRates(selectSystem, selectVolume, selWaterType);
  }

  if (target === "#census") {
    plotDemographics(selectSystem);
  }

  if (target === "#summary") {
    createSummary();
  }
  //https://stackoverflow.com/questions/62939325/scale-mapbox-gl-map-to-fit-set-of-markers
 
}//end Draw Map

 //drawMap();
 
//--------------------------------------------------------------------------------------
//                    END DRAW MAP FUNCTION
//--------------------------------------------------------------------------------------


