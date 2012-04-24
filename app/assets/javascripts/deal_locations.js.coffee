## Place all the behaviors and hooks related to the matching controller here.
## All this logic will automatically be available in application.js.
## You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
#
#marker = undefined
#
#@init = () =>
#  open = true
#  options = 
#    map: Gmaps.map.map
#    position: map.getCenter()
#    draggable: true
#    clickable: true
#            
#  marker = new google.maps.Marker options 
#        
#  iOptions = 
#    disableAutoPan: true
#            
#  infoWindow = new google.maps.InfoWindow iOptions 
#        
#  google.maps.event.addListener marker, 'dragend', reverseGeocode
#        
#  openInfoWindow => infoWindow
#        
#  google.maps.event.addListener marker, 'drag', 
#    () =>
#      infoWindow.close() if open
#      open=!open;
#        
#  google.maps.event.addListener marker, 'click',
#    ()=>
#      infoWindow.open(map,marker) unless open
#      else infoWindow.close
#      open=!open
#  reverseGeocode;
#
#@reverseGeocode = (lat,lng) =>
#  latlng = marker.getPosition
#  processForms(latlng);
#  geocoder.geocode 
#    'latLng': latlng
#  , (results, status) =>
#    if status == google.maps.GeocoderStatus.OK 
#      if results[1]
#        infoWindow.setContent results[1].formatted_address
#        infoWindow.close ;
#      else 
#        infoWindow.setContent("Can't identify location.");
#                
#    else 
#      infoWindow.setContent("Failed to identify location.");
#
#@processForms = ()=>
#  $('#deal_location_latitude').attrib 'value',latlng.lat ;
#  $('#deal_location_longitude').attrib 'value',latlng.lng;
#
#
#@codeAddress = (address) =>
#    geocoder = new google.maps.Geocoder
#    geocoder.geocode { 'address': address}, (results, status) =>
#      if status == google.maps.GeocoderStatus.OK 
#        return results;
#      else 
#        alert("Geocoding failed" + status)
#  