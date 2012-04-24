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

# DRY
class DealsTentScraper < Scraper
    
  def initialize 
    super ARGV[0],"dealstent"
  end
  
  def start_retrieval
    html = remove_br Nokogiri::HTML( open($url_root , :proxy=>$proxy) )
    
    deal = from_parent_div html , $deal_config[$site_name]['parent_container'] , 
      {
      :deal_url => {
        :xml_path=> $deal_config[$site_name]['deal_url'] , 
        :target_attribute=>'href'
      },
      :price => {
        :xml_path=> $deal_config[$site_name]['price'] , 
        :target_attribute=>nil
      },
      :original_price=> {
        :xml_path => $deal_config[$site_name]['original_price'] , 
        :target_attribute=>nil
      } ,
      :deal_thumb=> {
        :xml_path => $deal_config[$site_name]['deal_thumb'] , 
        :target_attribute=>'src'
      } ,
      :discount => {
        :xml_path => $deal_config[$site_name]['discount'] , 
        :target_attribute=>nil
      }  ,
      :description => {
        :xml_path => $deal_config[$site_name]['description'] , 
        :target_attribute=>nil
      } ,
      :title=> {
        :xml_path => $deal_config[$site_name]['title'] , 
        :target_attribute=>nil
      } 
    }    
    
    deal.each do | d | 
      d[:deal_url] = d[:deal_url]['http://'] ? 
        d[:deal_url] : ( $url_root + d[:deal_url] )
      d[:deal_thumb] = d[:deal_thumb]['http://'] ? 
        d[:deal_thumb] : ( $url_root + d[:deal_thumb] )
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
    html = deal_html.to_s
    
    expiry = html[/austDay\s*=\s*'\d*'/]
    expiry = expiry.gsub /austDay\s*=\s*/ , ''
    expiry = expiry.gsub /'/ , ''
    time = Time.now + ( expiry.to_i )
    deal[:expiry] = time.strftime("%Y-%m-%d %H:%M:%S")
        
    loc_collection = Array.new
    links = deal_html.xpath '//a'
    links.each do |a|
      if a.content
        if a.content.to_s[/VIEW\s*GOOGLE\s*MAP/i]
          begin
            loc = a['href'].to_s()[/\?.*/]
            loc = loc.split '&'
            loc = loc[0]
            loc = loc.gsub /\?q=/ , ''
            loc = loc.gsub /\+/ , ' '

            latlng = geocode loc

            loc_collection << { 
              :name=> loc , 
              :latitude=>latlng[:lat] , 
              :longitude=>latlng[:lng] , 
            }
          rescue
            puts 'Can\'t parse URI'
          end
        end
      end
    end
    deal[:location] = loc_collection
    
    deal[:author] = $deal_config[$site_name]["author"]
    deal[:price] = deal[:price].gsub /\D*/ , ''
    
    deal
  end
end

DealsTentScraper.new.start