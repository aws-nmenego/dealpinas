// -->global variables
var map;
// collection of deal information (markers, description, infowindows, etc)
var deals = new Array();
// collection of deals visible within the map, array of deal indeces
var visibleDeals = new Array();
// -->

//timer for map checking map status
var mapTimer;

// constant strings
var SELECTED_MARKER_ICON="/assets/markers/star.png"
var LOCATION_PLACEHOLDER = "e.g. Manila";
var WHAT_PLACEHOLDER = "e.g. Spa";

//page tab
var selectedTab = 1;

// --> visible deals control
// id of current deal displayed
var currentDeal;
// index in visbleDeals
var currentDealIndex = 0;
// -->

// indicate start of page load
var start = true;

// distance of sidebar from page top
var sidebar_offset;

// check if there are no more deals retrieved
var noMoreDeals = false;

var listReceived = true;

var globalMaxInt = 9007199254740992;

var predefinedLocations;

var hasValueWhat = false , hasValueWhere = false;

$.ajaxSetup ({
    // Disable caching of AJAX responses
    cache: false
});

$(function(){
    // --> tabs
    $('#tabs').tabs({
        asynchronous:false
    });
    //hover states on the static widgets
    $('#dialog_link, ul#icons li').hover(
        function() {
            $(this).addClass('ui-state-hover');
        }, 
        function() {
            $(this).removeClass('ui-state-hover');
        }
        );
    // -->

    // --> animation for deal information  arrows
    $('#deal_next').hover(function () {
        $('#deal_next img').stop(true)
        $('#deal_next img').animate({
            opacity: 1
        }, 500);
    });
    $('#deal_next').mouseleave(function () {
        $('#deal_next img').stop(true)
        $('#deal_next img').animate({
            opacity: 0.5
        }, 500);
    });
    
    $('#deal_prev').hover(function () {
        $('#deal_prev img').stop(true)
        $('#deal_prev img').animate({
            opacity: 1
        }, 500);
    });
    $('#deal_prev').mouseleave(function () {
        $('#deal_prev img').stop(true)
        $('#deal_prev img').animate({
            opacity: 0.5
        }, 500);
    });
    
    //rollover
    $('#lets_go_button').hover(function(){
        $('#lets_go_button img.default').css('display','none');
        $('#lets_go_button img.rollover').css('display','block');
    });
    $('#lets_go_button').mouseleave(function(){
        $('#lets_go_button img.default').css('display','block');
        $('#lets_go_button img.rollover').css('display','none');
    });
    
    
    $('#specific-text-field').blur(function() {
        if ($(this).val().length ==0) {
            $(this).css('color','gray');
            $(this).val(WHAT_PLACEHOLDER);
            hasValueWhat = false;
        }
    });
    $('#specific-text-field').blur();
    $('#specific-text-field').css('color','gray');
    $('#specific-text-field').focus(function() {
        $(this).css('color','black');
        if (!hasValueWhat) {
            $(this).val('');
        }
    });
    
    $('#location-text-field').blur(function() {
        if ($(this).val().length ==0) {
            $(this).css('color','gray');
            $(this).val(LOCATION_PLACEHOLDER);
            hasValueWhere = false;
        }
    });
    $('#location-text-field').blur();
    $('#location-text-field').css('color','gray');
    $('#location-text-field').focus(function() {
        $(this).css('color','black');
        if (!hasValueWhere) {
            $(this).val('');
        }
    });
    
    $('#list-load-more a').click(function() {
       currentMax=currentMax+currentMaxIncrement;
       listReceived = true;
       hideDealsButton();
       getMoreDealsForList();
    });
    
    $('#sidebar-top').corner();
    $('#sidebar-bottom').corner();
    $('#deal_container').corner();
    $('#loading-div').corner();
    $('#main_content').css('padding','0 0 10px 0');
    $('#footer').css('border-top','white thin solid')
// -->
});

//page initialize
function initialize() {
    
    // --> map init
    var latlng = new google.maps.LatLng(14.611326,121.003332);
    var myOptions = {
        zoom: 11,
        minZoom: 3,
        center: latlng,
        mapTypeId: google.maps.MapTypeId.ROADMAP
    }
    map = new google.maps.Map(document.getElementById("map_container"), myOptions);
    // -->
      
    //continuous timer check to see if bounds are aready loaded
    mapTimer = setInterval(checkIfBoundsIsLoaded,50);
    
    //initial offset value of si
    sidebar_offset = 75;
    predefinedLocations = 
    [
        {latlng : new google.maps.LatLng(14.580427419610178, 121.03354440234375) , zoom: 12 , name: 'manila'} , 
        {latlng : new google.maps.LatLng(7.098934125672977, 125.61235463500977) , zoom: 13 , name: 'davao'},
        {latlng : new google.maps.LatLng(10.322688175603334, 123.92063110058598) , zoom: 13 , name: 'cebu'}
    ]
    
    addMapEvents();
    
    //check for auto load ajax events
//    sidebar_offset = $('#sidebar').offset().top
    check();
    $(window).scroll(function(){
        check();
    });
    
    var divLeft = createList('By Location',
        ['Manila','Cebu','Davao'],
        4,'location-text-field');

    var divRight = createList('By Deal Sites',
        authors
        ,4, 'specific-text-field');
    
    divLeft.css('float','left');
    divLeft.css('margin','0 0 0 30px');
    
    divRight.css('float','right');
    divRight.css('margin','0 10px 0 0');
    
    var parentDiv = $('#keyword-links');
    parentDiv.append(divLeft);
    parentDiv.append(divRight);
    parentDiv.append($('<div/>').css('clear','both'));
    parentDiv.corner();
    
    prepareTabOne();
}

function check(){
    if (selectedTab==2) {
        // check for tab 2 ( List View )
        if(isScrolledIntoView($('#show-me-the-deals'))){
            getMoreDealsForList();
        }
        moveSidebar();
    }
}

function isScrolledIntoView(elem)
{
    var docViewTop = $(window).scrollTop();
    var docViewBottom = docViewTop + $(window).height();

    var elemTop = $(elem).offset().top;
    var elemBottom = elemTop + $(elem).height();

    return ((elemBottom >= docViewTop) && (elemTop <= docViewBottom));
}

function isPartiallyHiddenTop(elem) {
    var docViewTop = $(window).scrollTop();

    var elemTop = $(elem).offset().top;

    return (elemTop > docViewTop);
}

function moveSidebar() {
    if (!isPartiallyHiddenTop($('#sidebar')) &&  $('#sidebar').offset().top >= sidebar_offset) {
        $('#sidebar').css('position','fixed')
        $('#sidebar').css('top','0')
    }
    else if ($('#sidebar').offset().top < sidebar_offset) {
        $('#sidebar').css('position','fixed')
        $('#sidebar').css('top',sidebar_offset+'px')
    }
}

function addMapEvents() {
    google.maps.event.addListener(
        map,'dragend',checkSelectedDeal);
    google.maps.event.addListener(
        map,'zoom_changed',checkSelectedDeal);
}

function checkSelectedDeal() {
    if (currentDeal) {
        if (!map.getBounds().contains(currentDeal.marker.getPosition())) {
            resetDeal(currentDeal.deal_id);
            $('#deal_information_container').css('display','none');
        }
    }
}
 
//check if the map have bounds
function checkIfBoundsIsLoaded() {
    if (map) {
        if (map.getBounds()) {
            clearInterval(mapTimer);
            displayMarkers();
        }
    }
}

// perform ajax request  
function displayMarkers() {
    var ajax = jQuery.get(
        '/get_deals_within_bounds', 
        {
//            category: '%'+$('input[name="category[category_name]"]:checked','#categories').val()+'%',
//            what: '%'+ whatTextFieldValue() +'%',
//            location_name: "%"
            category: '%'+$('input[name="category[category_name]"]:checked','#categories').val()+'%',
            what: '%'+ whatTextFieldValue() +'%',
            location_name: '%',
            status: $('input[name="type[type_name]"]:checked','#types').val()=='new'?
                $('input[name="type[type_name]"]:checked','#types').val():'%',
            is_ad: 
                    $('input[name="type[type_name]"]:checked','#types').val()=='ad' ?
                    '1,1' : '1,0'
        })
   ajax.success(showMarkers);
   ajax.error();
}

// Can't understand why displayMarkers and showMarkers are named as such, so deal with it
function showMarkers(data) {
    // parse JSON
    var received = parse(data);
    
    var dealLength = received.length;
    // clear all deals stored in array
    removeAllDeals(deals);
    
//    for ( var j=0 ; j<dealLength ; j++) {
    var count = 0;
    for ( var k in received) {
        // store received data to deal array with the received data's deal_id as index
        var receivedData = received[k]
        deals[receivedData.deal_id] = received[k];
        
        // create markers array, which allows support for multiple locations per deal
        deals[receivedData.deal_id].markers = new Array();

        var length = deals[receivedData.deal_id].deal_locations.length;
        for ( var i=0; i < length ; i++ ) {
            // deal container
            var dealData = new Object();

            // --> marker information
            var marker = new google.maps.Marker ({
                position: new google.maps.LatLng(
                    deals[receivedData.deal_id].deal_locations[i].lat,
                    deals[receivedData.deal_id].deal_locations[i].lng),
                map:map
            });
            marker.setZIndex(receivedData.deal_id);
            
            // if no icon is specified for the received deal
            if (deals[receivedData.deal_id].icon_url)
                marker.setIcon(deals[receivedData.deal_id].icon_url)
            // -->

            dealData.deal_id = receivedData.deal_id;
            dealData.marker = marker;
//            dealData.info_window = info_window
            dealData.icon = deals[receivedData.deal_id].icon_url;

            // store marker specific information (info window and markers)
            deals[receivedData.deal_id].markers[i] = dealData;

            addEventListeners(dealData);
            
            if (start && focusedDeal > -1 && dealData.deal_id == focusedDeal) {
                loadDeal(dealData);
                centerDeal(dealData);
            }
            count++;
        }
    }
    console.log(count)
    
    // perform this  code fragment if this is the first time loading
    if (start) {
        start = false;
    }
}

function centerDeal(dealData) {
    if (deals[dealData.deal_id].markers.length > 0)
        map.panTo(deals[dealData.deal_id].markers[0].marker.getPosition())
}
   
function addEventListeners(data) {
    google.maps.event.addListener(data.marker,'click',
        function(){
//            openMarkerWindow = function(){data.info_window.open(map,data.marker);}
            loadDeal(data);
        });
}

var openMarkerWindow;
    
function updateVisibleDeals() {
    visibleDeals.length = 0;
    for (var id in deals) {
        var len = deals[id].markers.length;
        // for each marker in this deal's location'
        for ( var i=0;i<len;i++ )  {
            if (map.getBounds().contains(deals[id].markers[i].marker.getPosition())) {
                visibleDeals.push(deals[id].markers[i]);
            }
        }
    }
}

function nextDeal() {
    updateVisibleDeals();
    if (currentDealIndex+1>=visibleDeals.length) {
        currentDealIndex=0;
    }
    else {
        currentDealIndex++;
    }
    if (currentDeal == visibleDeals[currentDealIndex] && visibleDeals.length>1)
        nextDeal();
    else
        currentDeal = visibleDeals[currentDealIndex];
    loadDeal(currentDeal)
}
    
function previousDeal() {
    updateVisibleDeals();
    if (currentDealIndex-1<0) {
        currentDealIndex=visibleDeals.length-1;
    }
    else {
        currentDealIndex--;
    }
    if (currentDeal == visibleDeals[currentDealIndex] && visibleDeals.length>1)
        previousDeal();
    else
        currentDeal = visibleDeals[currentDealIndex];
    loadDeal(currentDeal)
}

// ajax for specific information regarding deal
function loadDeal(deal) {
    if(!deal)
        return;
    
    showLoadingScreen();
    currentDeal = deal;
    jQuery.get(
        '/get_deal', 
        { 
            deal_id: deal.deal_id
        }, 
        processDeal
        )
}

// perform processing before displaying deal;
function processDeal(data) {
    if (selectedTab==1)
        $('#deal_information_container').css('display','block')
    showDeal (parse(data));
}

function trimDown ( string , length ) {
    if (''+string.length > length)
        return ( string.substring(0,length) + "...");
    else
        return string;
}

function showDeal (deal) {
    if (!deal) {
        hideLoadingScreen();
        return;
    }
    
    resetMarkerInformation();
    $('#deal_image').attr('href',deal.deal_url);
    $('#deal_image img').attr('src',deal.image_url);
    
    $('#deal_title').html( deal.title );
    
    $('#deal_offer').html( deal.description  );
    
    $('#deal_location').empty();
    clearPopup();
    
    var len = deal.location.length;
    var doneAppending = false;
    for (var i=0;i<len;i++) {
        if (deal.location[i] != null) {
            var a = $('<a/>');
            a.attr('class','tooltip');
            a.css('cursor','default')
            a.html( deal.location[i].location_name );
            
            if (len==2 || i==0) {
                $('#deal_location').append(a);
                $('#deal_location').append('<br/>');
            }
            else if ( len > 2 ) {
                if (!doneAppending) {
                    $('#deal_location').append(createLinkForPopup());
                    doneAppending = true;
                }
                appendToPopup(a);
            }
        }
    }
    
    if (allowedToEdit(deal.author)) {
        $('#linkToLocation').attr('href',"/deals/" + deal.deal_id + "/edit");
        $('#linkToLocation').css('font-size',"0.75em");
        $('#linkToLocation').html('Edit Deal/Ad');
    }
      
    $('#deal_discount').html(deal.discount_description);
    
    isDeal = deal.is_ad ? 'Ad':'Deal'
    $('#deal_author').html(isDeal+' by:&nbsp;'+deal.author);
      
    $('#deal_external_link').attr('href',deal.deal_url?deal.deal_url:'');
    $('#deal_external_link').attr('target','_blank')
    $('#deal_external_link').html(
        '<img class="default" src="/assets/images/view_deal.png" width="110" height="36" style="display:block"/>' +
        '<img class="rollover" src="/assets/images/view_deal_rollover.png" style="display:none" width="110" height="36"/>');
    $('#deal_external_link img').hover(function(){
        $('#deal_external_link img.rollover').css('display','block');
        $('#deal_external_link img.default').css('display','none');
    });
    $('#deal_external_link img').mouseleave(function(){
        $('#deal_external_link img.rollover').css('display','none');
        $('#deal_external_link img.default').css('display','block');
    });
      
//    openMarkerWindow = function(){currentDeal.info_window.open(map,currentDeal.marker);}
    changeMarkerInformation(deal.deal_id);
    
    
    // -->

    hideLoadingScreen();
}

function allowedToEdit(author) {
    return user.isAdmin || user.username==author
}

function hideDealsButton(){
    $('#list-load-more').css('display','none');
}
    
function showLoadingScreen() {
    if (selectedTab==1) {
        $('#loading-div').css('display','inline');
        $('#loading-div').height($('#deal_container').height());
        $('#loading-div').width($('#deal_container').width());
        $('#loading-div').css('top', $('#deal_container').offsetParent().top +'px' )
        
        var midHeight=parseInt($('#deal_container').height()/2);
        $('#loading-image').css('margin-top','-'+(midHeight+1)+'px');
    }
    else if (selectedTab==2) {
        $('#list-load img').css('display','inline');
        $('#list-load').css('height','30px');
        $('#list-load').css('margin-top','25px');
        hideDealsButton();
    }
}
    
function hideLoadingScreen() {
    if (selectedTab==1) {
        $('#loading-div').css('display','none');
    }
    else if (selectedTab==2) {
        $('#list-load img').css('display','none');
        $('#list-load').css('height','0');
        $('#list-load').css('margin-top','0');
    }
}

function zoomDeal(lat,lng) {
    map.setCenter(new google.maps.LatLng(lat,lng));
    map.setZoom(15);
}
  
function getDealDisplayHeight() {
    var heights = 
    [   
        $('#deal_left_col').height(),
        $('#deal_right_col').height() ,
        $('#deal_info').height()
    ]
    var height=0;
    for(var i=0;i<3;i++)
        height= heights[i]>(height)?heights[i]:height
    // returns the tallest of the three divs;
    return height;
}
    
function changeMarkerInformation(id) {
    if (deals[id]) {
        var len = deals[id].markers.length;
        for (var i=0;i<len;i++) {
            if (map.getBounds().contains(deals[id].markers[i].marker.getPosition())) {
                deals[id].markers[i].marker.setZIndex(globalMaxInt);
                deals[id].markers[i].marker.setIcon(SELECTED_MARKER_ICON);
            }
        }
        if (openMarkerWindow) openMarkerWindow();
    }
}
    
function resetMarkerInformation() {
    for (var id in deals){
        resetDeal(id);
    }
}

function resetDeal(id) {
    var len = deals[id].markers.length;
    for (var i=0;i<len;i++) {
        deals[id].markers[i].marker.setZIndex(deals[id].deal_id);
        deals[id].markers[i].marker.setIcon(deals[id].markers[i].icon);
//        deals[id].markers[i].info_window.close();
    }
}
 
    
function removeAllDeals(deals) {
    for (var id in deals) {
        var len = deals[id].markers.length;
        for (var i=0;i<len;i++) {
            deals[id].markers[i].marker.setIcon(null)
            deals[id].markers[i].marker.setMap(null);
//            deals[id].markers[i].info_window.close();
            delete deals[id].markers[i]
        }
        deals[id].markers.length = 0;
        delete deals[id]
    }
    deals.length = 0;
}
    
function parse (data) {
    return JSON.parse(data,function (key, value) {
        return value;
    });
}

function textfieldEventListener(e , src,value) {
    var keycode;
    
    if ( src=='specific-text-field' ) {
        if (value) {
            hasValueWhat = true;
            $('#specific-text-field').val(value);
        }
        else
            hasValueWhat = $.trim( $('#specific-text-field').val() ).length>0;
    }
    else if ( src == 'location-text-field' )
        hasValueWhere = $.trim( $('#location-text-field').val() ).length>0;
        
    if (window.event){
        keycode = window.event.keyCode;
    }
    else if (e){
        keycode = e.which;
    }
    else{
        return;
    }
    if (keycode == 13){
        findDeals();
    }
}

function locationTextFieldValue() {
    return hasValueWhere?$('#location-text-field').val():'%';
}

function whatTextFieldValue() {
    return hasValueWhat? $('#specific-text-field').val() : '';
}

function findDeals() {
    if (selectedTab==1) {
        displayMarkers();
        resetMarkerInformation();
        reverseGeocode( locationTextFieldValue() );
        $('#deal_information_container').css('display','none');
    }
    else if (selectedTab==2) {
        applyFilter()
    }
}
      
function reverseGeocode(address)  {
    var len = predefinedLocations.length;
    for ( i=0; i<len; i++) {
        var c = predefinedLocations[i];
        if (c.name == address.toLowerCase()) {
            map.setZoom(c.zoom);
            map.panTo(c.latlng)
            return
        }
    } 
    var geocoder = new google.maps.Geocoder();
    geocoder.geocode({
        'address':address
    },
    function(results, status) {
        if (status == google.maps.GeocoderStatus.OK) {
            map.setZoom(12);
            map.panTo(results[0].geometry.location);
        }
    });
}

function prepareTabOne() {
    if (selectedTab != 1 ) {
        selectedTab = 1;
        applyFilter();
        
        $('#link_to_tab_one img.tab_active.').css('display','block');
        $('#link_to_tab_one img.tab_not_active').css('display','none');
        
        $('#link_to_tab_two img.tab_active').css('display','none');
        $('#link_to_tab_two img.tab_not_active').css('display','block');
        
        $('#header').css('position','absolute');
        $('#header').css('top','0');
        
        $('#white-line').css('position','inherit')
        
        $('#sidebar').css('position','inherit');
        $('#sidebar-mask').css('display','none');
        resetMarkerInformation()
    }
}

function hideDealInformationContainer() {
    $('#deal_information_container').css('display','none')
    resetMarkerInformation()
}

function prepareTabTwo() {
    if (selectedTab != 2) {
        selectedTab = 2;
        hideDealInformationContainer()
        applyFilter();
        
        $('#link_to_tab_one img.tab_active.').css('display','none');
        $('#link_to_tab_one img.tab_not_active').css('display','block');
        
        $('#link_to_tab_two img.tab_active').css('display','block');
        $('#link_to_tab_two img.tab_not_active').css('display','none');
        
//        $('#header-redirect').css('position','fixed')
//        $('#header-redirect').css('top','0')
//        $('#header-redirect').css('z-index','100000')
//        $('#header img').css('position','fixed')
//        $('#header img').css('top','0')
//        $('#header img').css('z-index','99999')
        $('#header').css('position','fixed');
        $('#header').css('top','0');
        $('#header').css('z-index','99999');
        
        $('#header-mask').css('display','block');
        
        $('#white-line').css('position','fixed')
        $('#white-line').css('top','72px');
        $('#white-line').css('width','1024px');
        $('#white-line').css('z-index','9100');
        
        $('#sidebar').css('width','190px')
        $('#sidebar').css('position','fixed')
        $('#sidebar').css('top','74px')
        
        $('#sidebar-mask').css('display','block')
        clearList();
    }
}

function showMoreDeals() {
    $('#list-load-more').css('display','block');
    hideLoadingScreen();
}

function getMoreDealsForList() {
    if (!listReceived)
        return;
    
    if (currentMax == offset) {
        showMoreDeals();
    }
    else{
        showLoadingScreen();
        jQuery.get(
            '/get_deals_for_view', 
            {
                offset: offset,
                location_name: '%'+locationTextFieldValue()+'%',
//                what:'%'+whatTextFieldValue()+'%',
//                category: '%'+$('input[name="category[category_name]"]:checked','#categories').val()+'%'
                what:'%'+whatTextFieldValue()+'%',
                category: '%'+$('input[name="category[category_name]"]:checked','#categories').val()+'%',
                status: '%'+$('input[name="type[type_name]"]:checked','#types').val()+'%',
                is_ad: 
                    $('input[name="type[type_name]"]:checked','#types').val()=='ad' ?
                    '1,1' : '1,0'
                
            }, appendToList);
        listReceived = false;
    }
}

function appendToList(data) {
    var ret = jQuery.trim(data)
    if ( ret=='empty'){
        listReceived = true;
        if ( $('#deals_wrapper').children('*').length == 0 ) {
            $('#deals_wrapper').append('<br/><br/><div style="text-align:center">No results found</div>')
        }
        hideLoadingScreen();
    }
    else if (data!=null) {
        if (currentMax==offset) {
            
        }
        else {
            $('#deals_wrapper').append(data);
            listReceived = true;
            offset = offset+limit; 
            hideLoadingScreen();
        }
        
    }
    $('.deal_single').corner();
}

function clearList() {
    offset = 0;
    $('#deals_wrapper').empty()
}

function applyFilter() {
    if (selectedTab==1) {
        hideDealInformationContainer()
        displayMarkers();
    }
    else if (selectedTab==2) {
        clearList();
        getMoreDealsForList()
    }
}

// ---------------------> location popup div
var popup = $('#popup')

function showDivPopup(e ) {
    if (window.event) {
        e = window.event;
    }
    else if (e) {
        
    }
    else  return;
    
    var x = e.pageX;
    var y = e.pageY;

    popup.css('display','block')
    popup.css('top',y+'px')
    popup.css('left',(x+17)+'px')
}

function getTextWidth(text) {
    var span = $('<div/>')
    span.html(text);
    return span.width();
}

function hideDivPopup() {
    popupShowing = false;
    popup.css('display','none')
}

function appendToPopup(element) {
    var width = getTextWidth(element);
    if ( width > popup.width() ) {
        popup.css('width', width+'px' )
    }
    
    popup.append(element);
    popup.append('<br/>');
}

function createLinkForPopup() {
    var link = $('<a/>')
    link.css('cursor','pointer')
    link.html( 'Multiple Locations<br/>' );
    
    link.attr('onmouseover',"showDivPopup(event)");
    link.attr('onmouseout',"hideDivPopup(event)");
    return link;
}

function showPopupWithText(e,text) {
    clearPopup()
    appendToPopup(text);
    showDivPopup(e);
}

function clearPopup() {
    popup.empty();
}
// --------------------->

// --------------------> add listeners to dealLocationLink

function addListenersToDealLocationLink() {
    $('.dealLocationLink').hover(
        function() {
            $(this).stop()
            $(this).animate({
                opacity:0.5
            },200)
        },
        function() {
            $(this).stop()
            $(this).animate({
                opacity:1
            },200)
        }
    )
}

function createList(title, contents, perBlock , forField) {
    var div = $('<div/>');
    div.attr('class','list');
    div.append($('<strong/>').html(title).css('text-decoration','underline'));
    div.css('background-color','white')
    
    var table = $('<table/>')
                    .css('border-spacing','0') 
                    .attr('border','0');
    
    var tr = $('<tr/>').css('border-spacing','0');
    table.append(tr);
    
    var td, ul;
    
    var len = contents.length;
    for (var i=0; i<len ; i++) {
        if ( i%perBlock == 0 ) {
            td = $('<td/>');
            td.css('vertical-align','top')
            ul = $('<ul/>');
            td.append(ul);
            tr.append(td);
        }
        createCallback(contents[i],ul , forField)
    }
    
    div.append(table);
    return div;
}

function createCallback(word , ul , forField) {
    var clickCallback = 
    function(){
        $('#'+forField).css('color','black');
        $('#'+forField).val(word);
        
        if (forField=='specific-text-field')
            hasValueWhat = true;
        if (forField=='location-text-field')
            hasValueWhere = true;
        findDeals();
    }
    var a = $('<a/>');
    a.html(word)
    a.hover(
            function(){
                $(this).css('cursor','pointer')
                $(this).css('text-decoration','underline')
            },
            function(){
                $(this).css('text-decoration','none')
            }
            );
    a.click(clickCallback);
    ul.append($('<li/>'));
    ul.append(a);
}
    
$(document).ready(initialize);
