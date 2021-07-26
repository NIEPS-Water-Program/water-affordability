///////////////////////////////////////////////////////////////////////////////////////////////////
//
//                      AFFORDABILITY DROP DOWN MENUS                               ///////////////
////                   
///////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////
//  This function fills county drop down menu when a state is selected
///////////////////////////////////////////////////////////////////////////////////////////////////
function setStateThis(target) {
  //Change variable
  selectState = document.getElementById('setState').value;

  if (selectState === "ca") { map.fitBounds([-124.4, 32.5, -114.2, 42.1]); }
  if (selectState === "nc") { map.fitBounds([-85.2, 34, -74.2, 36.8]); }
  if (selectState === "pa") { map.fitBounds([-80.3, 39.2, -73.8, 42.8]); }  //left, bottom, right, top
  if (selectState === "tx") { map.fitBounds([-106.6, 25.8, -93.5, 36.5]); }
  if (selectState === "or") { map.fitBounds([-124.6, 41.9, -116.5, 46.3]); }
  if (selectState === "none") { map.fitBounds([-124, 25, -74, 48]); }

  //selectSystem = "none";  //I just set to none here because of zoom
  drawMap();
  return selectState; //, selectSystem}; 
} // end setStateThis function


///////////////////////////////////////////////////////////////////////////////////////////////////
//  This function filters by size of system
///////////////////////////////////////////////////////////////////////////////////////////////////
function setSizeThis(target) {
  //Change variable
  selectSize = document.getElementById('setSize').value;

  drawMap();
  return selectSize;//, selectSystem};
} // end setStateThis function


///////////////////////////////////////////////////////////////////////////////////////////////////
//  This function filters by owner type
///////////////////////////////////////////////////////////////////////////////////////////////////
function setOwnerThis(target) {
  //Change variable
  selectOwner = document.getElementById('setOwner').value;

  drawMap();
  return selectOwner;//, selectSystem};
} // end setStateThis function


///////////////////////////////////////////////////////////////////////////////////////////////////
//  This function filters volume
///////////////////////////////////////////////////////////////////////////////////////////////////
function updateNVol(val) {
  selectVolume = Number(val);
  var ccfVol = Math.round(selectVolume / 7.48052);
  document.getElementById('volTitle').innerHTML = "<p style='font-size: 16px;'><b>Select Monthly Usage: " +
    "<span style='color: rgb(26,131,130); font-size: 13px;'>" + numberWithCommas(val) +
    " gallons<br>&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;(~" + numberWithCommas(ccfVol) + " cubic feet)</span></b></p>";

    //remove map layers
    //if (map.getLayer('select-utility-layer')) { map.removeLayer('select-utility-layer'); }
    var utilitiesLayer = map.getLayer('select-utility-layer');
    console.log(utilitiesLayer);
    if (typeof utilitiesLayer !== 'undefined') {
      map.removeLayer('select-utility-layer');
      console.log("removed select utility layer");
    }
    map.removeLayer('utilities-layer');
    map.removeSource('utilities');
    
    //map source only changes when volume changes
    var select_url;
    if (selectVolume <= 4000){
      select_url = 'mapbox://water-afford-project.a4n8hxrh';
    }

    if (selectVolume >= 5000 & selectVolume <= 8000){
      select_url = 'mapbox://water-afford-project.cberqmxq';
    }

    if (selectVolume >= 9000 & selectVolume <= 12000){
      select_url = 'mapbox://water-afford-project.5vk4to4o';
    }

    if (selectVolume >= 13000 & selectVolume <= 16000){
      select_url = 'mapbox://water-afford-project.8moavisi';
    }
    console.log(select_url);
  //  load map layer based on volume selected
    map.addSource('utilities', {
         type: 'vector',
         url: select_url
    });

  drawMap();
  //highlightUtility(selectSystem);
  return selectVolume;
}



///////////////////////////////////////////////////////////////////////////////////////////////////
//  When a system is selected this function calls plots to load depending on tab
///////////////////////////////////////////////////////////////////////////////////////////////////
function setSystemThis(target) {
  selectSystem = document.getElementById('setSystem').value;

  highlightUtility(selectSystem);
  return selectSystem;
}


function setMatrixLegendThis(target) {
  matrixLegend = document.getElementById('setMatrixLegend').value;

  createMatrix(selectSystem, matrixLegend);
  return matrixLegend;
}

