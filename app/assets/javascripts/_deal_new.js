var MAP;

var AUTOCOMPLETE;

var ADDITIONAL_IMAGES = 0;

var LOCATIONS = new Array();

var PRICE_REGEX = /^\d+(\.?\d{1,2})?$/;
var URL_REGEX = /(ftp|http|https):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/;

var temp_placeholder = '';

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

function limitField(field, limit) {
    if(field.value.length > limit) {
        field.value = field.value.substring(0, limit);
    }
}

function initialize() { 
    var latlng = new google.maps.LatLng(14.62478,121.020584);
    var myOptions = {
        zoom: 12,
        minZoom: 3,
        center: latlng,
        mapTypeId: google.maps.MapTypeId.ROADMAP
    }
    MAP = new google.maps.Map(document.getElementById("map_container"), myOptions);
    
    if(deal_locations != undefined) {
        insertOriginalLocations();
    }
    
    if(deal_images != undefined) {
        insertOriginalImages();
    }
    
    //update image
    $('#deal_deal_thumb').change();
    
    
    /*
    var input = document.getElementById("txt-input");
    AUTOCOMPLETE = new google.maps.places.Autocomplete(input);
    
    AUTOCOMPLETE.bindTo('bounds', MAP);
    
    google.maps.event.addListener(AUTOCOMPLETE, 'place_changed', function() {
      var latLng;
      var place = AUTOCOMPLETE.getPlace();
      console.log(place);
      if( place.geometry == undefined ){
        var geocoder = new google.maps.Geocoder();
        geocoder.geocode({
                address: place.name
            },
            function(results, status) {
                if (status == google.maps.GeocoderStatus.OK) {
                    addLocation(results[0].geometry.location, results[0].formatted_address);
                    
                } else {
                    alert("Sorry. No address matches your query. You may plot the location manually.");
                    console.log("MAP ERROR:" + status);
                }
            }
        )
        latLng = place.name;
      } else if (place.geometry.viewport) {
        MAP.fitBounds(place.geometry.viewport);
        latLng = place.geometry.location;
        addLocation(latLng, place.formatted_address);
      } else {
        MAP.setCenter(place.geometry.location);
        MAP.setZoom(11);
        latLng = place.geometry.location;
        addLocation(latLng, place.formatted_address);
      }  

    });
    */
    google.maps.event.addListener(MAP, 'click', function(event) {
        var geocoder = new google.maps.Geocoder();
        geocoder.geocode({
            location: event.latLng
        }, function(results, status){
            if (status == google.maps.GeocoderStatus.OK) {
                addLocation(event.latLng, results[0].formatted_address);
            } else if( status == google.maps.GeocoderStatus.ZERO_RESULTS ) {
                addLocation(event.latLng, '' );
            } else {
                alert("Sorry. No address matches your query. You may plot the location manually.");
                console.log("MAP ERROR:" + status);
            }
        });
    });
    
    google.maps.event.addListener(MAP, 'mousemove', function(event) {
        $("#list-instructions").slideUp();
        document.getElementById("font-instructions").innerHTML = "Show Help" ;
    });
    
    //getOriginalPrice();
}


function insertOriginalLocations() {
    $.each( deal_locations, function(i, item) {
        var latLng = new google.maps.LatLng(item.latitude,item.longitude);
        LOCATIONS.push( new Location(createMarker(latLng, MAP, true), createInfoWindow(item.location_name, LOCATIONS.length)))
        addMarkerListeners(LOCATIONS.length -1 );
        MAP.setCenter(latLng);
        closeInfoWindows();
        LOCATIONS[LOCATIONS.length-1].getInfoWindow().open(MAP, LOCATIONS[LOCATIONS.length-1].getMarker())
    })
}

function insertOriginalImages() {
    $.each( deal_images, function(i, item) {
        addAnotherImage();
        
        $('#images_url_'+ADDITIONAL_IMAGES).val(item.url)
        $('#images_desc_'+ADDITIONAL_IMAGES).val(item.description)
    })
}


function addLocation( latLng, locationName ){
    LOCATIONS.push( new Location(createMarker(latLng, MAP, true), createInfoWindow(locationName, LOCATIONS.length)) )
    
//    new Location( 
//        new google.maps.Marker( {
//            position: latLng,
//            map: MAP,
//            draggable: true
//        }),
//        new google.maps.InfoWindow( {
//            content: getNewAddress(locationName, LOCATIONS.length ),
//            minHeight: 150,
//            minWidth: 350,
//            maxWidth: 350,
//            maxHeight: 150
//        })
//    ) );
    
    // set marker listeners
    addMarkerListeners(LOCATIONS.length - 1);
    // close infow windows
    closeInfoWindows();
    // display info window
    LOCATIONS[LOCATIONS.length-1].getInfoWindow().open(MAP, LOCATIONS[LOCATIONS.length-1].getMarker())
}

/**
 * add listeners to the marker provided by i
 */
function addMarkerListeners( index ) {
    
    var marker = LOCATIONS[index].getMarker();
    var infoWindow = LOCATIONS[index].getInfoWindow();
    
    var temp; // latlng holder
    
    google.maps.event.addListener(marker, 'rightclick', function(event) {
        infoWindow.close();
        infoWindow = null;
        marker.setVisible(false);
        marker.setMap(null);
        LOCATIONS[index] = null;
    });
    
    google.maps.event.addListener(marker, 'click', function(event) {
        closeInfoWindows();
        infoWindow.open(MAP, marker);
    });
    
    google.maps.event.addListener(marker, 'dragstart', function(event) {
        temp = marker.getPosition();
        infoWindow.close();
    });

    google.maps.event.addListener(marker, 'dragend', function(event) {
        marker.setVisible(false);
        
        var geocoder = new google.maps.Geocoder();
        geocoder.geocode({
            location: event.latLng
        }, function(results, status){
            if (status == google.maps.GeocoderStatus.OK) {
                addLocation(event.latLng, results[0].formatted_address);
                marker.setMap(null);
                infoWindow = null;
                LOCATIONS[index] = null;
            } else {
                alert("Sorry. No address matches your query. Are you in the sea?");
                console.log("MAP ERROR:" + status);
                
                // restore previous state
                marker.setPosition(temp);
                marker.setVisible(true);
                infoWindow.open(MAP, marker);
                
            }
        });
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

function getOriginalPrice() {
    var ret = ( parseFloat($('#deal_price').val()) / (100 - parseFloat($('#deal_discount').val())) ) * 100;
    if( !isNaN(ret) ) {
        $('#deal_original_price').val(ret);
    }
}

function checkCategoryAtLeastOne() {
    var ret = true;
    $.each( document.getElementById('new_deal')['deal[cat_ids][]'], function (i, item) {
        if( item.checked == true )
            ret = false;
    } );        
    return ret;
}

function validateForm() {

    if( 
        document.getElementById('deal_title').value == '' ||
        document.getElementById('deal_description').value == '' ||
        document.getElementById('deal_price').value == '' ||
        document.getElementById('deal_expiry').value == '' ||
        document.getElementById('deal_deal_url').value == '' ||
        document.getElementById('deal_deal_thumb').value == ''
        //checkCategoryAtLeastOne() 
    ) {
        alert( "Please provide data for all required fields.")
        return false;        
    } else {
        createHiddenFields();
        return true;
    }
}


function validateFormAd() {

    if( 
        document.getElementById('deal_title').value == '' ||
        document.getElementById('deal_description').value == '' ||
        document.getElementById('deal_expiry').value == '' || 
        document.getElementById('deal_deal_thumb').value == '' ||
        document.getElementById('deal_promo').value == '' ||
        document.getElementById('deal_merchant_name').value == '' || 
        document.getElementById('deal_contact_address').value == '' ||
        document.getElementById('deal_contact_number').value == '' ||
        document.getElementById('deal_contact_name').value == '' ||
        document.getElementById('deal_contact_email').value == '' ||
        document.getElementById('deal_display_until').value == ''
        //checkCategoryAtLeastOne() 
    ) {
        alert( "Please provide data for all required fields.")
        return false;        
    } else {
        if(ADDITIONAL_IMAGES != 0) {
            createHiddenFieldsForImages();
        }
        createHiddenFields();
        return true;
    }
}

function createHiddenFieldsForImages() {
    var i;
    var str = '';
    for( i=1; i <= ADDITIONAL_IMAGES; i++ ) {
        if( $("#images_url_"+i).val() == "" ){
            continue;
        }
        $('#div-hidden').append("<input type='hidden' " +
            "name='deal[images][]' " +
            "value='" + JSON.stringify( getImage(i) ) + "'/>")
    }
}

function createHiddenFields() {    
    var str = '';
    $.each(LOCATIONS, function(i, item) {
        if( item != null ){
            str += "<input type='hidden' " + 
                "name='deal[locations][]' " +
                "value='" + JSON.stringify(item.getLocation()) +
                "'/>";
        }
    });

    $('#div-hidden').append(str);
}

function getNewAddress( address, idx ) {
    return "<textarea onkeyup='createAddress(this)' id='" + idx + "' style='font: 1em Arial' class='infowindow' maxlength='150' maxrows='4'>" + address + "</textarea>"
}

/**
 * update infowindow object content upon textarea update
 */
function createAddress(item) {
    LOCATIONS[item.id].getInfoWindow().content = getNewAddress( item.value, item.id ) ;
}


function closeInfoWindows(){
    $.each(LOCATIONS, function(i, item){
        if(LOCATIONS[i] != null) {
            LOCATIONS[i].getInfoWindow().close(); 
        }
    });
}

function isNumberKey(evt) {
    var charCode = (evt.which) ? evt.which : event.keyCode
    if (charCode > 31 
            && ( charCode < 48 || charCode > 57 ) ) {
        return false;
    }

    return true;
}

function isPrice(evt) {
    
    var charCode = (evt.which) ? evt.which : event.keyCode
    if (charCode > 31 && (charCode < 48 || charCode > 57) 
            && ( charCode < 96 || charCode > 105) 
            && charCode != 190 
            && charCode != 110 )
        return false;

    return true;
}

function updateDiscount() {
    var originalPrice = document.getElementById('deal_original_price').value
    var discountedPrice = document.getElementById('deal_price').value
    
    if( originalPrice != "" && discountedPrice != "" ) {
        document.getElementById('deal_discount').value = Math.round((1- (discountedPrice / originalPrice))*100) + "%"
    } else {
        document.getElementById('deal_discount').value = ""
    }
}


function handlePrice(input) {
    
    if(input.value.search(PRICE_REGEX) == -1 && input.value != "") {
        input.style.border = "2px solid red"
    } else {
        input.style.border = ""
    }
}

function handleUrl(input) {
    
    if(input.value.search(URL_REGEX) == -1 && input.value != "") {
        input.style.border = "2px solid red"
    } else {
        input.style.border = ""
    }
}
    
function handlePercent(input) {
    if (input.value < 0) input.value = 0;
    if (input.value > 100) input.value = 100;
}

function lessThanQuantity(input) {
    var quantity = document.getElementById('deal_quantity').value;
    console.log(input.value + ' - ' + quantity)
    if(parseInt(input.value,10) >= parseInt(quantity,10) ) {
        input.value = 0;
        alert("Sold items can not exceed deal quantity.");
    }
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
                content: getNewAddress( location_name, idx ),
                minHeight:150,
                minWidth: 350,
                maxWidth:350,
                maxHeight: 150                
            })
}

function addAnotherImage() {
    if( ADDITIONAL_IMAGES < 5) {
        if( ADDITIONAL_IMAGES == 0 ) {
            $('#remove-last-image').css('display', 'inline');
        }
        ADDITIONAL_IMAGES++;
        $('#cell-images')
        .append('<tr><td>Image '+ ADDITIONAL_IMAGES +
            ' URL</td><td width="65%"><input id="images_url_' + 
            ADDITIONAL_IMAGES + '" type="text"/></td></tr>' + 
            '<tr><td>Image '+ ADDITIONAL_IMAGES +
            ' Description</td><td><input id="images_desc_' + 
            ADDITIONAL_IMAGES + '" type="text"/></td></tr>');
    } else {
        alert("Sorry. You may only add 5 images at a time. Thank you.")
    }
}

function removeLastImage() {
    if( ADDITIONAL_IMAGES > 0 ) {
        $('#cell-images tr:last').remove();
        $('#cell-images tr:last').remove();
        ADDITIONAL_IMAGES--;
        if( ADDITIONAL_IMAGES == 0 )
           $('#remove-last-image').css('display', 'none'); 
    } else {
        $('#remove-last-image').css('display', 'none');
    }
}

function getImage(idx) {
    return {
        'url' : $("#images_url_"+idx).val(),
        'description' : $("#images_desc_"+idx).val()
    }
}


$(function() {
    $( "#deal_display_until" ).datepicker({dateFormat: 'yy-mm-dd', minDate:0});
    $( "#deal_expiry" ).datetimepicker({dateFormat: 'yy-mm-dd', timeFormat: 'hh:mm:ss', minDate: 0});
});

$('#deal_deal_thumb').change(function() {
    if(  $('#deal_deal_thumb').val() != ''  )  {
        $('#thumbnail').attr('src',$('#deal_deal_thumb').val() );
    } else {
        $('#thumbnail').attr('src',$('#thumbnail').attr('default') );
    }
})

$('#deal_original_price').change(function() {
  updateDiscount();
});

$('#deal_price').change(function() {
  updateDiscount();
});

$("input[type=text]").focus(function(){
  temp_placeholder = $(this).attr('placeholder');
  $(this).attr('placeholder', '');
});

$("input[type=text]").focusout(function(){
  $(this).attr('placeholder', temp_placeholder);
});

$("#font-instructions").click(function () {
    $("#list-instructions").slideToggle();
    if (document.getElementById("font-instructions").innerHTML == "Show Help" ) {
        document.getElementById("font-instructions").innerHTML = "Hide Help" ;
    } else {
        document.getElementById("font-instructions").innerHTML = "Show Help" ;
    }
});

$(document).ready(initialize);