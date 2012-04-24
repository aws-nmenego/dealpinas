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
    super ARGV[0],"kuponan_ph"
  end  
  
  def start_retrieval
    html = remove_br Nokogiri::HTML( open($url_root , :proxy=>$proxy) )
    
    deal = from_parent_div html , $deal_config[$site_name]['parent_container'] , 
      {
      :deal_url => {
        :xml_path=> $deal_config[$site_name]['deal_url'] , 
        :target_attribute=>'href'
      },
      :deal_thumb => {
        :xml_path=> $deal_config[$site_name]['deal_thumb'] , 
        :target_attribute=>'data-original'
      },
      :price => {
        :xml_path=> $deal_config[$site_name]['price'] , 
        :target_attribute=>nil 
      },
      :discount => {
        :xml_path=> $deal_config[$site_name]['discount'] , 
        :target_attribute=>nil
      }
    }
    
    # get last parent with different identifier
    z = from_parent_div html , $deal_config[$site_name]['parent_container_last'] , 
      {
      :deal_url => {
        :xml_path=> $deal_config[$site_name]['deal_url'] , 
        :target_attribute=>'href'
      },
      :deal_thumb => {
        :xml_path=> $deal_config[$site_name]['deal_thumb'] , 
        :target_attribute=>'data-original'
      },
      :price => {
        :xml_path=> $deal_config[$site_name]['price'] , 
        :target_attribute=>nil 
      },
      :discount => {
        :xml_path=> $deal_config[$site_name]['discount'] , 
        :target_attribute=>nil
      }
    }
    
    deal << z[0]
      
    s = html.to_s
    expiry = s.scan(/end_date\s*=\s*new\s*Date\s*\(\s*'.*'\s*\)\s*;/)
    if expiry.size != deal.size
      raise StandardError.new 'Apparently, separating the expiry date 
            and the main deal content won\'t work, '+
            expiry.size.to_s+':'+deal.size.to_s+''
    end
    
    for i in 0..deal.size-1
      d = deal[i]
      d[:deal_url] = d[:deal_url]['https://'] ?
        d[:deal_url].gsub(/https:\/\// , 'http://') : 
        deal[:deal_url]
       
      expiry[i] = expiry[i][/'.*'/]
      expiry[i] = expiry[i].gsub /'/ , ''
      time = Time.parse expiry[i]
      d[:expiry] = time.strftime("%Y-%m-%d %H:%M:%S")
      
      d[:price] = d[:price].gsub /\D*/ , ''
      d[:discount] = d[:discount].gsub /OFF/ , ''

      deal_html = remove_br Nokogiri::HTML(open(d[:deal_url], :proxy=>$proxy))
      
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
      :description=> {
        :xml_path => $deal_config[$site_name]['description'] , 
        :target_attribute => nil
      } ,
      :title => {
        :xml_path => $deal_config[$site_name]['title'] , 
        :target_attribute => nil
      } , 
      :location => {
        :xml_path => $deal_config[$site_name]['location'] ,
        :target_attribute => nil
      }
    }
    
    deal = combine_hash deal , deal_data[0]
    
    deal[:location] = deal[:location].gsub /Address\s*:/ , ''
    latlng = geocode deal[:location]
    deal[:latitude] = latlng[:lat]
    deal[:longitude] = latlng[:lng]
    
    deal[:author] = $deal_config[$site_name]['author']
    
    deal
  end
end

TcatScraper.new.start