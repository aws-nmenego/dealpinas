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


class CleverBuyScraper < Scraper
    
  def initialize 
    super ARGV[0],"clever_buy"
  end
  
  def start_retrieval
    html = remove_br Nokogiri::HTML( open($url_root , :proxy=>$proxy) )
    
    deals = from_parent_div html , $deal_config[$site_name]['parent_container'] , 
      {
      :title => { 
        :xml_path=> $deal_config[$site_name]['title'] , 
        :target_attribute=>nil
      } , 
      :description => { 
        :xml_path=> $deal_config[$site_name]['description'] , 
        :target_attribute=>nil
      } , 
      :price => { 
        :xml_path=> $deal_config[$site_name]['price'] , 
        :target_attribute=>nil
      } , 
      :quantity => { 
        :xml_path=> $deal_config[$site_name]['quantity'] , 
        :target_attribute=>nil
      } , 
      :deal_url => { 
        :xml_path=> $deal_config[$site_name]['deal_url'] , 
        :target_attribute=>'href'
      } , 
      :deal_thumb => { 
        :xml_path=> $deal_config[$site_name]['deal_thumb'] , 
        :target_attribute=>'source'
      } , 
      :deal_thumb2 => { 
        :xml_path=> $deal_config[$site_name]['deal_thumb'] , 
        :target_attribute=>'src'
      } , 
      :discount => { 
        :xml_path=> $deal_config[$site_name]['discount'] , 
        :target_attribute=>nil
      } , 
      :expiry => { 
        :xml_path=> $deal_config[$site_name]['expiry'] , 
        :target_attribute=>nil
      }
    }
    
    deals.each do |d| 
      if d[:expiry]        
        time = Time.now + d[:expiry].to_i
        d[:expiry] = time.strftime("%Y-%m-%d %H:%M:%S")
      end
    
      deal_page = remove_br Nokogiri::HTML( open( d[:deal_url] , :proxy=>$proxy) )
      
      main_office = deal_page.at_xpath( $deal_config[$site_name]['main_location_name'] ).content
      script = deal_page.at_xpath( $deal_config[$site_name]['map_script'] )
      script =(script ? script.content : nil)
      
      locs = from_parent_div deal_page ,  $deal_config[$site_name]['deal_page'] , 
      {
        :name => {
          :xml_path => $deal_config[$site_name]['branches'] , 
          :target_attribute=>nil
        },
        :address=> {
          :xml_path => $deal_config[$site_name]['address'] ,
          :target_attribute=>'href'
        }
      }
      
      loc_collection = Array.new
      if script
        s = script[/coordinates\s*=\s*new\s*google.maps.LatLng\s*\(\s*.\d*.\d*,\s*.\d*.\d*\)/]
        s = s[/.\d*.\d*,\s*.\d*.\d*/].gsub(/\s+/, '')
        latlng = s.strip ','
        loc_collection << { 
          :name=> main_office , 
          :latitude=>latlng[0].to_int , 
          :longitude=>latlng[1].to_int , 
        }
      else
        latlng = geocode main_office
        loc_collection << { 
          :name=> main_office , 
          :latitude=>  latlng[:lat], 
          :longitude=> latlng[:lng] , 
        }
      end
      
      locs.each do |loc| 
        latlng = geocode loc[:name]
        loc_collection << { 
          :name=> loc[:name] , 
          :latitude=> latlng[:lat] , 
          :longitude=> latlng[:lng] , 
        }
      end
      
      deal = Deal.new(
        d[:title],
        d[:deal_url],
        d[:deal_thumb] ? ($url_root + d[:deal_thumb]) : 
          ( d[:deal_thumb2]['http://'] ? d[:deal_thumb2]:
            $url_root + d[:deal_thumb2]),
        d[:price],
        nil,
        nil,
        nil,
        nil,
        d[:description],
        nil,
        nil,
        d[:discount],
        true
      )
      deal.expiry = d[:expiry]
      deal.author = $deal_config[$site_name]['author'] 
      deal.location = loc_collection
      $db.insert_deal(deal)
    end
  end
end

CleverBuyScraper.new.start