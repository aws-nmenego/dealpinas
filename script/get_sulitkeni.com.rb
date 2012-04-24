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


class SulitKeniScraper < Scraper
    
  def initialize 
    super ARGV[0],"sulitkeni"
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
      :discount => {
        :xml_path => $deal_config[$site_name]['discount'] , 
        :target_attribute=>nil
      } ,
      :title => {
        :xml_path => $deal_config[$site_name]['title'] , 
        :target_attribute=>nil
      } , 
      :deal_thumb => {
        :xml_path => $deal_config[$site_name]['deal_thumb'] , 
        :target_attribute => 'src'
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
    html = deal_html.to_s
    deal[:expiry] = html[/setTZCountDown\('\d*','\d*','\d*','.*','\d*'\)/x]
    deal[:expiry] = deal[:expiry].gsub /setTZCountDown\(/x , ''
    deal[:expiry] = deal[:expiry].gsub /\)/x , ''
    deal[:expiry] = deal[:expiry].gsub /'/x , ''
    time = deal[:expiry].split ','
    deal[:expiry] = trim_space(time[4])+'-'+
                    trim_space(time[0])+'-'+
                    trim_space(time[1])+' '+
                    trim_space(time[2])+':00:00'
    
    
    deal[:author] = $deal_config[$site_name]["author"]
    deal[:price] = deal[:price].gsub /\D*/ , ''
    deal[:original_price] = deal[:original_price].gsub /\D*/ , ''
    
    deal[:description] = ''
    deal
  end
end

SulitKeniScraper.new.start