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


class MegadealsScraper < Scraper
   def initialize 
    super ARGV[0],"megadeals"
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
    deal_data = from_parent_div deal_html , $deal_config[$site_name]['url_parent'] , 
      {
      :title => {
        :xml_path => $deal_config[$site_name]['title'] , 
        :target_attribute => nil
      } 
    }
    
    deal = combine_hash deal , deal_data[0]
    
    html = deal_html.to_s
    
    deal[:price] = deal[:price].gsub /\D/ , ''
    
    expiry = html[/heartBeat\s*\(\s*'.*'\s*,\s*\d+\s*,\s*\d+\s*,\s*\d+\s*,\s*\d+\s*,\s*\d+\s*,\s*\d+\s*,\s*\d+\s*\)\s*;/]
    expiry = expiry.gsub /\s*/ , ''
    expiry = expiry.gsub /heartBeat\('.*',/ , ''
    expiry = expiry.gsub /\);/ , ''
    expiry = expiry.split ','
    expiry =  trim_space(expiry[0]) +'-'+
        trim_space((expiry[1].to_i + 1 ).to_s) +'-'+
        trim_space(expiry[2]) +' '+
        trim_space(expiry[3]) +':'+
        trim_space(expiry[4]) +':'+
        trim_space(expiry[5])
    deal[:expiry] = expiry
    
    deal[:author] = $deal_config[$site_name]["author"]
    deal[:description] = ''
    deal
  end
end

MegadealsScraper.new.start