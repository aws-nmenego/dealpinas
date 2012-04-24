var MAP;
var LOCATIONS = new Array();

/**
 * Location class
 */
function Location(marker, infoWindow) {
    this.marker = marker;
    this.infoWindow = infoWindow;
    this.getInfoWindow = function() {
        return this.infoWindow;
    }
    this.getMarker = function() {
        return this.marker;
    }
    this.setMarker = function(marker) {
        this.marker = marker;
    }
    this.setInfoWindow = function(infoWindow) {
        this.infoWindow = infoWindow;
    }
    this.getLocation = function() {
        return {
            'latitude': this.marker.getPosition().lat(),
            'longitude': this.marker.getPosition().lng(),
            'location_name': strip( this.infoWindow.getContent() )
        }
    }
}

function initialize() { 
    var latlng
    
    if(deal_locations != undefined && deal_locations.length > 0) {    
        latlng = new google.maps.LatLng(deal_locations[0].latitude,deal_locations[0].longitude);
    } else {
        latlng = new google.maps.LatLng(14.62478,121.020584);
    }
    
    var myOptions = {
        zoom: 11,
        minZoom: 3,
        center: latlng,
        mapTypeId: google.maps.MapTypeId.ROADMAP
    }
    MAP = new google.maps.Map(document.getElementById("map_container"), myOptions);
    
    $.each(deal_locations, function(i, item) {
        
        var latLng = new google.maps.LatLng(item.latitude,item.longitude);
        LOCATIONS.push( new Location(createMarker(latLng, MAP, false), createInfoWindow(item.location_name, LOCATIONS.length)))
        addMarkerListeners(LOCATIONS.length -1 );
        MAP.setCenter(latLng)
        closeInfoWindows();
        LOCATIONS[LOCATIONS.length-1].getInfoWindow().open(MAP, LOCATIONS[LOCATIONS.length-1].getMarker())

    })
}

function createMarker( latLng, map, draggable ) {
    return new google.maps.Marker( {
                position: latLng,
                map: map,
                draggable: draggable
            })
}

function createInfoWindow( location_name, idx) {
    return new google.maps.InfoWindow({
                content: createContent(location_name)   
            })
}

function createContent(loc) {
    return "<div style='overflow:hidden'>"+loc+"</div>"
}

/**
 * add listeners to the marker provided by i
 */
function addMarkerListeners( index ) {
    
    var marker = LOCATIONS[index].getMarker();
    var infoWindow = LOCATIONS[index].getInfoWindow();
    
    google.maps.event.addListener(marker, 'click', function(event) {
        closeInfoWindows();
        infoWindow.open(MAP, marker);
    });
    
}

function closeInfoWindows(){
    $.each(LOCATIONS, function(i, item){
        if(LOCATIONS[i] != null) {
            LOCATIONS[i].getInfoWindow().close(); 
        }
    });
}


$(document).ready(initialize);