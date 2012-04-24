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


class DealSpotScraper < Scraper
  
  def initialize 
    super ARGV[0],"dealspot"
  end
  
  def start_retrieval
    html = remove_br Nokogiri::HTML( open($url_root , :proxy=>$proxy) )
    
    deal = from_parent_div html , $deal_config[$site_name]['parent_container'] , 
      {
      :deal_url => {
        :xml_path=> $deal_config[$site_name]['deal_url'] , 
        :target_attribute=>'href'
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
        :target_attribute=> nil
      } , 
      :quantity => {
        :xml_path => $deal_config[$site_name]['quantity'] ,
        :target_attribute => nil
      } ,
      :deal_thumb => {
        :xml_path => $deal_config[$site_name]['deal_thumb'] ,
        :target_attribute => 'src'
      }
    }
    
    deal.each do | d | 
      d[:deal_url] = d[:deal_url]['http://'] ? 
        d[:deal_url] : ( $url_root + d[:deal_url] )
      d[:deal_thumb] = d[:deal_thumb]['http://'] ? 
        d[:deal_thumb] : ( $url_root + d[:deal_thumb] )
      
      begin
        deal_html = remove_br Nokogiri::HTML open(d[:deal_url], :proxy=>$proxy)
        deal_data = get_data  deal_html , d
        insert deal_data
      rescue
        puts 'Cant get/parse data from '+d[:deal_url]
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
      nil,
      nil,
      d[:discount],
      true
    )
    deal.author = d[:author]
    deal.expiry = d[:expiry]
    
    $db.insert_deal deal
  end
  
  def get_data  deal_html, deal
    deal_data = from_parent_div deal_html , 
      $deal_config[$site_name]['url_parent'] , 
      {
      :expiry_days => {
        :xml_path => $deal_config[$site_name]['expiry_days'] , 
        :target_attribute => nil
      } , 
      :expiry_hours => {
        :xml_path => $deal_config[$site_name]['expiry_hours'] , 
        :target_attribute => nil
      } , 
      :expiry_minutes => {
        :xml_path => $deal_config[$site_name]['expiry_minutes'] , 
        :target_attribute => nil
      } 
    }
    
    html = deal_html.to_s
    deal = combine_hash deal , deal_data[0]
    
    time = Time.now + 
      (deal[:expiry_days].to_i * 24 * 3600) +
      (deal[:expiry_hours].to_i * 3600) +
      (deal[:expiry_hours].to_i * 60) 
    deal[:expiry] = time.strftime("%Y-%m-%d %H:%M:%S")
    
    deal[:title] = html[/(<h3>\s*About.*<\/h3>){1}/]
    deal[:title] = deal[:title].gsub /<(\/)?h3>\s*/ , ''
    deal[:title] = deal[:title].gsub /(About){1}/ , ''
    
    deal[:location] = Array.new
    loc_list = deal_html.xpath '//p[@class="store-location-item"]'
    loc_list.each do |loc|  
      hash = {}
      name = loc.content
      name = name.gsub 'View Map' , ''
      hash[:name] = name
      
      content = loc.to_s
      latlng = content[/(loadMap\s*\(.*\)){1}/]
      latlng = latlng[/\(.*\){1}/]
      latlng = latlng[/\d*\.\d*\s*,\s*\d*\.\d*/]
      if latlng
        latlng = latlng.split ','
        hash[:latitude] = latlng[0].chomp 
        hash[:longitude] = latlng[1].chomp 
      else
        hash[:latitude] = nil
        hash[:longitude] = nil
      end
      
      deal[:location] << hash
    end
    
    deal[:price] = deal[:price].gsub /\D*/ , ''
#    deal[:price] = deal[:price].to_s.slice 2..-1
    deal[:author] = $deal_config[$site_name]['author']
      
    deal
  end
end

DealSpotScraper.new.start