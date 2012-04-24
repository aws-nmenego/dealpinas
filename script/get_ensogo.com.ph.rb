require 'nokogiri'
require 'open-uri'
require 'mysql2'
require 'uri'
require 'cgi'
require 'geocoder'
require 'geokit'
require 'json'

require_relative 'deal'
require_relative 'deals_database_rev'
require_relative 'scraper'

class EnsogoScraper < Scraper
   def initialize 
    super ARGV[0],"ensogo"
  end  
  
  def start_retrieval
    html = remove_br Nokogiri::HTML( open($url_root , :proxy=>$proxy) )
    
    deal = from_parent_div html , $deal_config[$site_name]['parent_container'] , 
      {
      :deal_url => {
        :xml_path=> $deal_config[$site_name]['deal_url'] , 
        :target_attribute=>'href'
      },
      :title => {
        :xml_path=> $deal_config[$site_name]['title'] , 
        :target_attribute=>nil
      },
      :description => {
        :xml_path=> $deal_config[$site_name]['description'] , 
        :target_attribute=>nil
      },
      :price => {
        :xml_path=> $deal_config[$site_name]['price'] , 
        :target_attribute=>nil
      },
      :discount => {
        :xml_path => $deal_config[$site_name]['discount'] , 
        :target_attribute=>nil
      } ,
      :deal_thumb => {
        :xml_path => $deal_config[$site_name]['deal_thumb'] , 
        :target_attribute=>'src'
      } 
    }
    
    deal.each do | d | 
      d[:deal_url] = d[:deal_url]['http://'] ? 
        d[:deal_url] : ( $url_root + d[:deal_url] )
      d[:deal_thumb] = d[:deal_thumb]['http://'] ? 
        d[:deal_thumb] : ( $url_root + d[:deal_thumb] )
      
      deal_html = remove_br Nokogiri::HTML open(d[:deal_url], :proxy=>$proxy)
   
      begin
        deal_data = get_data  deal_html , d
        puts deal_data
        insert deal_data
      rescue StandardError=> e
        puts 'Deal processing error occured, check '+d[:deal_url]
        puts e.backtrace
      end

    end
  end
  
  def insert d
    deal = Deal.new(
      d[:title],
      d[:deal_url],
      d[:deal_thumb],
      d[:price],
      d[:location],
      d[:quantity],
      nil,
      nil,
      d[:description],
      d[:latitude],
      d[:longitude],
      d[:discount],
      true
    )
    deal.author = d[:author]
    deal.expiry = d[:expiry]
    
    $db.insert_deal deal
  end
  
  def get_data  deal_html, deal
    html = deal_html.to_s
    time = html[/targetDate\s*:\s*'\s*\d*\s*'/]
    time = time.gsub /targetDate\s*:\s*/, ''
    time = time.gsub /'/, ''
    time = trim_space time
    current_time = html[/currentDate\s*:\s*\d*\s*/]
    current_time = current_time.gsub /currentDate\s*:\s*/, ''
    current_time = trim_space current_time
    time = Time.now + (time.to_i - current_time.to_i)
    deal[:expiry] = time.strftime("%Y-%m-%d %H:%M:%S")
  
    p = deal_html.xpath '//div[@class="location-details f-left"]/p'
    loc_collection = Array.new
    p.each do |a|
      if a.content
        begin
          loc = a.content
          latlng = geocode loc
          
          if !latlng[:lat].nil? && !latlng[:lng].nil?
            loc_collection << { 
              :name=> loc , 
              :latitude=>latlng[:lat] , 
              :longitude=>latlng[:lng] , 
            }
          end
        rescue
          puts 'Can\'t parse '+loc
        end
      end
    end
    deal[:location] = loc_collection
    deal[:author] = $deal_config[$site_name]['author']
    deal[:price] = deal[:price].gsub /\D*/ , ''
     
    deal
  end
end

EnsogoScraper.new.start