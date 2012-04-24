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

class CashCashPinoyScraper < Scraper

  def initialize 
    super ARGV[0],"cash_cash_pinoy"
  end
      
  def start_retrieval
    html = remove_br Nokogiri::HTML( open($url_root , :proxy=>$proxy) )
    
    deal = from_parent_div html , $deal_config[$site_name]['parent_container'] , 
      {
      :title => {
        :xml_path=> $deal_config[$site_name]['title'] , 
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
      :deal_url => {
        :xml_path=> $deal_config[$site_name]['deal_url'] , 
        :target_attribute=>'href'
      } ,
      :deal_thumb => {
        :xml_path => $deal_config[$site_name]['deal_thumb'] ,
        :target_attribute => 'src'
      }
    }
    deal.each do | d | 
      if d[:deal_url]
        d[:deal_url] = d[:deal_url]['http://'] ? 
          d[:deal_url] : ( $url_root + d[:deal_url] )
        d[:deal_thumb] = d[:deal_thumb]['http://'] ? 
          d[:deal_thumb] : ( $url_root + d[:deal_thumb] )

        deal_html = remove_br Nokogiri::HTML open(d[:deal_url], :proxy=>$proxy)

        deal_data = get_data  deal_html , d
        if deal_data
          insert deal_data
        end
      end
      
    end
  end
  
  def insert d
    if d[:title] && d[:price] && d[:discount] && 
        d[:deal_url] && d[:deal_thumb]
      
        deal = Deal.new(
          d[:title],
          d[:deal_url],
          d[:deal_thumb],
          d[:price],
          nil,
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
  end
  
  def get_data  deal_html, deal
    deal_data = from_parent_div deal_html , 
      $deal_config[$site_name]['url_parent'] , 
      {
      :description => {
        :xml_path=> $deal_config[$site_name]['description'] , 
        :target_attribute=>nil
      },
      :quantity => {
        :xml_path => $deal_config[$site_name]['quantity'] , 
        :target_attribute => nil
      } ,
      :expiry_h => {
        :xml_path => $deal_config[$site_name]['expiry_h'] , 
        :target_attribute => nil
      } ,
      :expiry_m => {
        :xml_path => $deal_config[$site_name]['expiry_m'] , 
        :target_attribute => nil
      } ,
      :expiry_s => {
        :xml_path => $deal_config[$site_name]['expiry_s'] , 
        :target_attribute => nil
      } 
    }
    
    deal = combine_hash deal , deal_data[0]
    if deal[:quantity]
      deal[:quantity] = deal[:quantity].gsub /\s*/ , ''
    end
    
    begin      
      deal[:price] = deal[:price].gsub /\D*/ , ''
      deal[:expiry_h] =deal[:expiry_h].gsub /\D*/ , ''
      deal[:expiry_m] =deal[:expiry_m].gsub /\D*/ , ''
      deal[:expiry_s] =deal[:expiry_s].gsub /\D*/ , ''
      deal[:expiry] = Time.now + 
        (deal[:expiry_h].to_i * 3600) +
        (deal[:expiry_m].to_i * 60) + 
        deal[:expiry_s].to_i
      deal[:expiry] = deal[:expiry].strftime("%Y-%m-%d %H:%M:%S")
      deal[:author] = $deal_config[$site_name]['author']
    rescue StandardError => e
      return nil;
    end
    
    deal
  end
end

CashCashPinoyScraper.new.start