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


class TcatScraper < Scraper
    
  def initialize 
    super ARGV[0],"tcat"
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
      }
    }
    
    deal.each do | d | 
      d[:deal_url] = d[:deal_url]['http://'] ? 
        d[:deal_url] : ( $url_root + d[:deal_url] )
      deal_html = remove_br Nokogiri::HTML open(d[:deal_url], :proxy=>$proxy)
      
      deal_data = get_data  deal_html , d
      insert deal_data
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
    deal_data = from_parent_div deal_html , 
      $deal_config[$site_name]['url_parent'] , 
      {
      :quantity => {
        :xml_path => $deal_config[$site_name]['quantity'] , 
        :target_attribute => nil
      } ,
      :expiry => {
        :xml_path => $deal_config[$site_name]['expiry'] , 
        :target_attribute => 'diff'
      } , 
      :deal_thumb => {
        :xml_path => $deal_config[$site_name]['deal_thumb'] ,
        :target_attribute => 'src'
      }
    }
    deal = combine_hash deal , deal_data[0]
    
    time = Time.now + ( deal[:expiry] ? deal[:expiry].to_i/1000 : 0)
    deal[:expiry] = time.strftime("%Y-%m-%d %H:%M:%S")
    
    deal[:discount] = deal[:discount] ? deal[:discount]+'%':''
    
    site = deal_html.to_s
    latlng = site[/new\s*google\.maps.LatLng\s*\(\s*\d*\.\d*\s*,\s*\d*\.\d*\s*\)/]
    latlng = latlng[/\s*\d*\.\d*\s*,\s*\d*\.\d*\s*/]
    latlng = latlng.split ','
    deal[:latitude] = latlng[0].gsub(/\s*/, '')
    deal[:longitude] = latlng[1].gsub(/\s*/, '')
    
    location_name = site[/var\s*contentString\s*=\s*((".*")*\s*\+?)*;/]
    location_name = location_name.gsub /var\s*contentString\s*=\s*/ , ''
    location_name = location_name.gsub /\+/ , ''
    location_name = location_name.gsub /<{1}([\/a-zA-Z0-9])*\s*(([a-zA-Z])*\s*=\s*(.*)*)*>{1}/ , ''
    location_name = location_name.gsub /"/ , ''
    location_name = location_name.gsub /$/ , ''
    location_name = location_name.gsub /&?\w*;/ , ''
    
    deal[:location] = location_name
    deal[:author] = $deal_config[$site_name]['author']
    
    deal[:price] = deal[:price].gsub /\D*/ , ''
    
    deal
  end
end

TcatScraper.new.start