=begin
==
== Author		: Advanced World Solutions, Inc.
== Created on	: March 9, 2012
==
=end

require 'nokogiri'
require 'open-uri'
require 'mysql2'
require 'uri'
require 'cgi'
require 'logger'
require_relative 'deal'
require_relative 'deals_database'
require_relative 'scraper'
require 'geocoder'
require 'geokit'
require 'json'

# log file
$log = Logger.new( "#{__FILE__}.log", 'daily' )
$log.info "START #{__FILE__}"

class MetroDealScraper < Scraper
  
  # global var to be stored in database
  $arr_deals = Array.new
  
  ## the urls of the child nodes of the landing page
  $child_links = Array.new
  
  ## database connection
  $db = DealsDatabase.instance
  
  ## keep track insertions
  $insert_number = 0
  
  # method to parse url and search elements via xpath
  def initialize
    super ARGV[0],"metrodeal"
    $url_root 	= $deal_config[$site_name]["site_url"]
  end
  
  def scrape(url)
	
    $log.info "START #{__FILE__}.#{__method__}"
	
    begin
      doc = Nokogiri::HTML(open(url))
      $log.info "Open url : #{url}"

      $log.info "Fetching from : #{url}"
      
      title 		= doc.at_xpath($deal_config[$site_name]["title"])
      deal_url	= URI.parse(url) 
      price 		= doc.at_xpath($deal_config[$site_name]["price"]) 
      location 	= doc.at_xpath($deal_config[$site_name]["location"])	
      sold 		= doc.at_xpath($deal_config[$site_name]["sold"]) 
      items		= doc.at_xpath($deal_config[$site_name]["items"]) 
      category	= doc.at_xpath($deal_config[$site_name]["category"])	
      deal_thumb	= doc.at_xpath($deal_config[$site_name]["deal_thumb"])['src'] 
      description = doc.at_xpath($deal_config[$site_name]["description"]) 
      discount = doc.at_xpath($deal_config[$site_name]["discount"]) 
      image_map = doc.at_xpath($deal_config[$site_name]["image_map"]) 
      link_to_map = doc.at_xpath($deal_config[$site_name]["link_to_map"])
      expiry = doc.at_xpath($deal_config[$site_name]["expiry"])
    
      # MetroDeal has no imagemap
      # check if there is an imagemap
      # if so, insert latitude and longitude
      # else check if there is a link to a google map
      # if so, parse tag to extract directions
      # else try geocoding
      lat = nil
      long = nil
      if !link_to_map.nil?
        uri = URI.parse(URI.encode(link_to_map['href']))
        uri_params = CGI.parse(uri.query)
        if !uri_params["q"].nil?
          lat, long = uri_params["q"][0].chomp.split(',')
          lat = lat.strip
          long = long.strip
        end
      else
        # geocode address
        loc=GeoKit::Geocoders::MultiGeocoder.geocode(location.content.to_s.strip)
        if !loc.success
          #if loc.lat.nil?
          lat = nil 
          long = nil
        elsif loc.success
          lat = loc.lat
          long = loc.lng
        end
      end
              		
      $arr_deals << Deal.new(title, deal_url, deal_thumb, price, location, sold, items, category, description, lat, long, discount)
    
      # set the following to site name
      $arr_deals[-1].author = $deal_config[$site_name]["author"]
      # slight fix for deal_thumb incomplete url
      $arr_deals[-1].deal_thumb = "http://#{URI.parse($url_root).host}/#{$arr_deals[-1].deal_thumb}"
    
      # specialized for expiry
      if !expiry.nil?
        k = expiry.content.to_s.strip.gsub(/\s+/,' ')
        jso = k.match(/targetDate:\s+(.*?)}\)/m)[1].gsub("\'", "\"").gsub(/\b0*(\d+)/, '\1')
        test = JSON.parse(jso)
        $arr_deals[-1].expiry = "#{test['year']}-#{test['month']}-#{test['day']} #{test['hour']}:#{test['min']}:#{test['sec']}"
      end
    
      # update: 20120315 to remove branches 
      # geocode the latlng
      if /(^|\s+)Branches(\s+|$)/i.match($arr_deals[-1].location)
        if !$arr_deals[-1].latitude.nil? && !$arr_deals[-1].longitude.nil?
          $arr_deals[-1].location = GeoKit::Geocoders::MultiGeocoder.reverse_geocode(GeoKit::LatLng.new($arr_deals[-1].latitude,$arr_deals[-1].longitude) ).full_address
          puts $arr_deals[-1].location
        end
      end
    
      # print ...
      #		puts "#{$arr_deals[-1].title} \n"
      #		puts "#{$arr_deals[-1].price} \n"
      #		puts "#{$arr_deals[-1].sold} \n"
      #  	puts "#{$arr_deals[-1].items} \n"
      #		puts "#{$arr_deals[-1].location} \n"
      #		puts "#{$arr_deals[-1].deal_url} \n"
      #		puts "#{$arr_deals[-1].deal_thumb} \n"
      #		puts "#{$arr_deals[-1].category} \n"
      #		puts "#{$arr_deals[-1].description} \n"
      #		puts "#{$arr_deals[-1].latitude} \n"
      #		puts "#{$arr_deals[-1].longitude} \n"
      #		puts "#{$arr_deals[-1].discount} \n"


      $insert_number += 1
      puts "inserting deal #{$insert_number}..."
      $db.insert_deal($arr_deals[-1])
    
      $log.info "Successfully inserted data : #{url}"

    rescue Exception=>e
	
      print "Could not retrieve values. Maybe the site has changed?"
      $log.error e.to_s
      puts e.to_s
		
    end
	
    $log.info "END #{__FILE__}.#{__method__}"
	
  end

  # retrieve child nodes
  def get_child_links

    $log.info "START #{__FILE__}.#{__method__}"
	
    doc = Nokogiri::HTML(open($url_root))

    doc.xpath($deal_config[$site_name]["child_links"]).each do |link|
      $child_links << "#{URI.parse($url_root).host}/#{link['href']}"
      #puts $child_links[-1]
    end
	
    $log.info "END #{__FILE__}.#{__method__}"
	
  end


  # DRY
  def start_retrieval

    $log.info "START #{__FILE__}.#{__method__}"

    # get values in root page
    # the following was commented out since the root pages change
    # scrape(url) 

    # get child links
    $log.info "Retrieving sublinks of root page"
    get_child_links

    $child_links.each do |link|
      #puts "\nscraping http://#{link}"
      scrape("http://#{link}")
    end

    $log.info "END #{__FILE__}.#{__method__}"
  end
end


#close db
$db.close
$log.info "Database closed"
$log.info "END #{__FILE__}"

MetroDealScraper.new.start_retrieval