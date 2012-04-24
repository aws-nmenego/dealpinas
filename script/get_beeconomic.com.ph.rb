=begin
==
== Author		: Advanced World Solutions, Inc.
== Created on	: January 19, 2012
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

# log file
$log = Logger.new( "#{__FILE__}.log", 'daily' )
$log.info "START #{__FILE__}"

# keep track insertions



class BeeconomicScraper < Scraper
  $insert_number = 0

  # global var to be stored in database
  $arr_deals = Array.new

  # the urls of the child nodes of the landing page
  $child_links = Array.new

  def initialize 
    super ARGV[0],"groupon"
    
    $url_root 	= $deal_config[$site_name]["site_url"]
    $url_root_shopping 	= $deal_config[$site_name]["shopping_url"]
    $url_root_travel	= $deal_config[$site_name]["travel_url"]
    $url_root_cebu = $deal_config[$site_name]["cebu_url"]
    $url_root_manila = $deal_config[$site_name]["manila_url"]
    $url_root_davao= $deal_config[$site_name]["davao_url"]
    
  end
  
  # method to parse url and search elements via xpath
  def scrape(url)
	
    $log.info "START #{__FILE__}.#{__method__}"
	
    
    def initialize 
      super ARGV[0],"groupon"
    end
  
    begin
      html = open(url)
      doc = Nokogiri::HTML(html.read)
      doc.encoding = "utf-8"
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
      expiry = doc.at_xpath($deal_config[$site_name]["expiry"])['value'] 
      city = doc.at_xpath($deal_config[$site_name]["location_city"])

      # check if there is an imagemap
      # if so, insert latitude and longitude
      # else try geocoding
      image_map = doc.at_xpath($deal_config[$site_name]["image_map"])
      lat = nil
      long = nil
      if !image_map.nil? && image_map.to_s != ""
        uri = URI.parse(URI.encode(image_map['src']))
        uri_params = CGI.parse(uri.query)
        if !uri_params["center"].nil?
          lat, long = uri_params["center"][0].chomp.split(',')
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
    
      # specialized code for expiry
      time = Time.now + expiry.to_i/1000
      $arr_deals[-1].expiry = time.strftime("%Y-%m-%d %H:%M:%S")
    
      # add city to location 20120328
      cit = city.content.to_s.strip
      $arr_deals[-1].location += ", #{cit}"
      #    puts $arr_deals[-1].location
    
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
    
      $log.info "Successfully retrieved data : #{url}"

    rescue Exception=>e
	
      print "Could not retrieve values. Maybe the site has changed?"
      $log.error e.to_s
      puts e.to_s
		
    end
	
    $log.info "END #{__FILE__}.#{__method__}"
	
  end

  # retrieve child nodes at the sidebar...
  def get_child_links(url)

    $log.info "START #{__FILE__}.#{__method__}"
	
    doc = Nokogiri::HTML(open(url))
	
    # append hostname to url
    if url == $url_root_shopping
      doc.xpath($deal_config[$site_name]["child_links"]["a"]).each do |link|
        $child_links << "#{URI.parse(url).host}#{link['href']}"
        #puts $child_links[-1]
      end

    else
      doc.xpath($deal_config[$site_name]["child_links"]["b"]).each do |link|
        $child_links << "#{URI.parse(url).host}#{link['href']}"
        #puts $child_links[-1]
      end
    end
  
    #puts doc.xpath($deal_config[$site_name]["child_links"]["1"])
	
    $log.info "END #{__FILE__}.#{__method__}"
	
  end

  # DRY
  def retrieve(url)
  
    begin
      $log.info "START #{__FILE__}.#{__method__}"

      scrape(url)

      # get child links
      $log.info "Retrieving sublinks of root page"
      get_child_links(url)

      $child_links.each do |link|
        scrape("http://#{link}")
      end

      $log.info "END #{__FILE__}.#{__method__}"
    rescue Exception=>e
	
      print "Could not retrieve values. Maybe the site has changed?"
      $log.error e.to_s
      puts e.to_s
		
    end
  end
  
  def start_retrieval
    
    retrieve($url_root_shopping)
    retrieve($url_root_travel)
    retrieve($url_root_cebu)
    retrieve($url_root_davao)
    retrieve($url_root_manila)
  end

  def esc(var)
    if !var.nil?
      var = var.gsub(/\//, "\\/")
    else
      return nil
    end
  end
end

#close db
$db.close
$log.info "Database closed"
$log.info "END #{__FILE__}"

BeeconomicScraper.new.start_retrieval