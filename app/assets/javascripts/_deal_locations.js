// -->global variables
var map;

//var deal_locations = new Object();
var deal_locations_new = new Array();
// the markers
var marker = new Array();
var info_windows = new Array();

var geocode_result = null;

//page initialize
function initialize() {
    
    $('#tabs').tabs({
        asynchronous:false
    });
    
    // --> map init
    // set to locaiton
    var latlng = new google.maps.LatLng(deal_locations[0].latitude,deal_locations[0].longitude);
    var myOptions = {
        zoom: 13,
        center: latlng,
        mapTypeId: google.maps.MapTypeId.ROADMAP
    }
    map = new google.maps.Map(document.getElementById("map_container"), myOptions);
    
    // TODO: use deal_locations to restore the page from original (reset)
    deal_locations_new = deal_locations;
    setListeners();
    
    // set markers for current locations
    setMarkers();
    // set title for page
    setTitle();
    
}

function setListeners() {
    
    google.maps.event.addListener(map, 'click', function(event) {
      addMarker(event.latLng, true); 
      $("#list-instructions").slideUp();
    });
    
    google.maps.event.addListener(map, 'dragstart', function(event) {
      $("#list-instructions").slideUp();
    });
    
}

function closeInfoWindows() {
    $.each(info_windows , function(i, item) {
        
    })
}


function setMarkers() {
    if ( deal_locations_new.length != 0 ) {
        $.each(deal_locations_new, function(i, item) {
//            marker[i] = new google.maps.Marker ({
//                position: new google.maps.LatLng(
//                    deal_locations_new[i].latitude,
//                    deal_locations_new[i].longitude),
//                map:map,
//                draggable: true
//                });
            addMarker(new google.maps.LatLng(
                deal_locations_new[i].latitude,
                deal_locations_new[i].longitude
            ), false);
                
//            info_windows[i] = new InfoBubble({
//                    content : getNewAddress(deal_locations_new[i].location_name, i ),
//                    minHeight: 100,
//                    minWidth: 380,
//                    maxWidth: 380,
//                    maxHeight: 100
//                });

            createInfoWindow(deal_locations_new[i].location_name, i);

            //marker[i].setZIndex(1);
            
            //addMarkerListeners( i );

            }
        );
                
    } else {
        alert("No locations for this deal yet.")
    }
}

// redirect to deals
function cancel() {
    window.location = "/deals";
}


function addMarker(latLng, geocode) {

    var newMarker = new google.maps.Marker({
            position: latLng,
            map:map,
            draggable: true
        });

    newMarker.setZIndex(1);
    
    if( geocode == true ) {
        var geocoder = new google.maps.Geocoder();
        geocoder.geocode({
                'location': latLng
            },
            function(results, status) {
                if (status == google.maps.GeocoderStatus.OK) {
                    deal_locations_new.push({
                        latitude: latLng.lat(),
                        location_name: results[0].formatted_address,
                        longitude: latLng.lng(),
                        deal_id: deal_id
                    } );

//                    info_windows.push(new InfoBubble({
//                        content : getNewAddress(deal_locations_new[deal_locations_new.length - 1].location_name, deal_locations_new.length - 1),
//                        minHeight: 100,
//                        maxWidth: 300,
//                        maxHeight: 350
//                    }));
                    createInfoWindow(deal_locations_new[deal_locations_new.length -1].location_name, deal_locations_new.length -1);


                } else if(status == google.maps.GeocoderStatus.ZERO_RESULTS) {
                    deal_locations_new.push({
                        latitude: latLng.lat(),
                        location_name: '',
                        longitude: latLng.lng(),
                        deal_id: deal_id
                    } );

//                    info_windows.push(new InfoBubble({
//                        content : getNewAddress("NO LOCATION NAME", deal_locations_new.length - 1),
//                        minHeight: 100,
//                        maxWidth: 300,
//                        maxHeight: 350
//                    }));
                    createInfoWindow("NO LOCATION NAME", deal_locations_new.length -1);


                } else {
                    alert("Google Map Error Status: "+ status);
                }
                //displayObjects();
            }
        );
    }
    
    // push returns length.. i = l -1
    var i = marker.push( newMarker );
    
    addMarkerListeners( i - 1 );

}

function createInfoWindow(address, idx){
    info_windows.push( new google.maps.InfoWindow({
                    content : getNewAddress(address, idx),
                    minHeight: 150,
                    minWidth: 350,
                    maxWidth: 350,
                    maxHeight: 150
                })
                );
}

/**
 * @var item the textarea
 */
function createAddress(item) {
    info_windows[item.id].content = getNewAddress( item.value, item.id );
    console.log(info_windows[item.id].content)
}

/**
 * @var address the plaintext to be added
 */
function getNewAddress( address, idx ) {
    return "<textarea onkeyup='createAddress(this)' id='" + idx + "' style='font: 1em Arial' maxlength='150' maxrows='4'>" + address + "</textarea>"
}


/**
 * add listeners to the marker provided by i
 */
function addMarkerListeners( i ) {
    
    google.maps.event.addListener(marker[i], 'rightclick', function(event) {
        $("#list-instructions").slideUp();
        info_windows[i].close();
        info_windows[i] = null;
        marker[i].setVisible(false);
        marker[i].setMap(null);
        deal_locations_new[i] = null;
    });
    
    google.maps.event.addListener(marker[i], 'click', function(event) {        
        $("#list-instructions").slideUp();
        closeAllInfoWindows();
        info_windows[i].open(map, marker[i]);
    });
    
    google.maps.event.addListener(marker[i], 'dragstart', function(event) {
        $("#list-instructions").slideUp();
        info_windows[i].close();
        info_windows[i] = null;
    });

    google.maps.event.addListener(marker[i], 'dragend', function(event) {
        marker[i].setVisible(false);
        marker[i].setMap(null);
        deal_locations_new[i] = null;
        addMarker(event.latLng, true);
    });
    
}

/**
 * close all info windows
 */
function closeAllInfoWindows() {
    $.each( info_windows, function(i, item) {
        if(info_windows[i] != null ){
            info_windows[i].close();
        }
    });
}


/**
 * strip string html from tags
 * @return content of node
 */
function strip(html) {
   var tmp = document.createElement("DIV");
   tmp.innerHTML = html;
   return tmp.textContent||tmp.innerText;
}


/**
 * create the hidden fields in the markup
 */
function createFields() {
    retrieveEditedLocationNames();
    document.getElementById('div-hidden').innerHTML = createHiddenFields();
    
}

function createHiddenFields() {
    var str = '';
    $.each(deal_locations_new, function(i, item) {
        if( item != null ){
            str += "<input type='hidden' " + 
                "name='deal_location[name][]' " +
                "value='" + JSON.stringify(deal_locations_new[i]) +
                "'/>";
        }
    });
    
    // for if empty and deal_id
    if( str == '' ) {
        str += createExtraFields('empty', deal_id);
    } else {
        str += createExtraFields('nonempty', deal_id);
    }
    
    return str;
}


function createExtraFields(emptyBool, dealId) {
    return "<input type='hidden' name='deal_location[empty]' value='" + emptyBool +"'/>"+
                "<input type='hidden' name='deal_location[deal_id]' value='"+dealId+"'/>"
}

/**
 * @description retrieves the new location names from the text areas and plots them to the deal_locations_new
 */
function retrieveEditedLocationNames() {
    $.each( info_windows, function(i, item) {
        if( info_windows[i] != null ){
            deal_locations_new[i].location_name = strip(info_windows[i].content);
        }
    });
}


/**
 * just for tracing
 */
function displayObjects() {
    $.each(deal_locations_new, function(i, item) {
        console.log(item);
    });
}

/**
 * set title in page
 */
function setTitle() {
    document.getElementById('font-title').innerHTML += deal[0].title;
}

function cancelRedirect() {
    window.location = "/"
}

$("#font-instructions").click(function () {
    $("#list-instructions").slideToggle();
    if (document.getElementById("font-instructions").innerHTML == "Show Help" ) {
        document.getElementById("font-instructions").innerHTML = "Hide Help" ;
    } else {
        document.getElementById("font-instructions").innerHTML = "Show Help" ;
    }
});


$(document).ready(initialize);