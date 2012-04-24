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

class Lucky7Scraper < Scraper
    
  def initialize 
    super ARGV[0],"lucky7"
  end  
  
  def start_retrieval
    html = remove_br Nokogiri::HTML( open($url_root , :proxy=>$proxy) )
    
    deal_url = from_parent_div html , $deal_config[$site_name]['url_parent'] , 
      {
      :deal_url => {
        :xml_path=> $deal_config[$site_name]['deal_url'] , 
        :target_attribute=>'href'
      }
    }
    
    featured_deal = nil;
    
    deal_url.each do | url | 
      url[:deal_url] = url[:deal_url]['http://'] ? url[:deal_url] : ( $url_root + url[:deal_url] )
      deal_html = remove_br(Nokogiri::HTML open(url[:deal_url], :proxy=>$proxy))
      
      deal_data = get_data  deal_html , url[:deal_url]
      insert deal_data[0]
      
      
      if !featured_deal
        featured_deal_url = deal_html.at_xpath('//div[@class="sidedealbox-mid"]')['href'].to_s
        featured_deal_url = featured_deal_url['http://'] ? 
          featured_deal_url : ( $url_root + featured_deal_url)
        featured_deal = get_data  remove_br(Nokogiri::HTML(open( featured_deal_url , :proxy=>$proxy) )) , featured_deal_url
        insert featured_deal[0]
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
  
  def get_data  deal_html, url
    deal_data = from_parent_div deal_html , $deal_config[$site_name]['parent_container'] , 
      {
      :title => {
        :xml_path => $deal_config[$site_name]['title'] , 
        :target_attribute => nil
      } ,
      :price => {
        :xml_path => $deal_config[$site_name]['price'] , 
        :target_attribute => nil
      } ,
      :quantity => {
        :xml_path => $deal_config[$site_name]['quantity'] , 
        :target_attribute => nil
      } ,
      :discount => {
        :xml_path => $deal_config[$site_name]['discount'] , 
        :target_attribute => nil
      } ,
      :expiry => {
        :xml_path => $deal_config[$site_name]['expiry'] , 
        :target_attribute => nil
      } , 
      :location => {
        :xml_path => $deal_config[$site_name]['location'] ,
        :target_attribute => nil
      } ,
      :deal_thumb => {
        :xml_path => $deal_config[$site_name]['deal_thumb'] ,
        :target_attribute => 'src'
      } ,
      :description => {
        :xml_path => $deal_config[$site_name]['description'] ,
        :target_attribute => nil
      }
    }
    deal_data[0][:deal_url] = url
    deal_data[0][:title] = deal_data[0][:title].gsub(/\\n/ , '').strip
    deal_data[0][:price] = deal_data[0][:price].gsub /\D*/ , ''
    
    deal_data[0][:discount] = deal_data[0][:discount][/\d?\d\%/]
    
    deal_data[0][:location] = deal_data[0][:location].gsub(/\d+-\d+-\d+(\s*\S*)*/ , '')
    deal_data[0][:expiry] = deal_data[0][:expiry].gsub /\s*/ , ''
    deal_data[0][:deal_thumb] = deal_data[0][:deal_thumb]['http://'] ?
      deal_data[0][:deal_thumb] : ( $url_root + deal_data[0][:deal_thumb] )
    
    puts deal_data[0][:title]
#    deal_data[0][:title] = deal_data[0][:title].gsub /<b>/ , ''
#    deal_data[0][:title] = deal_data[0][:title].gsub /\s*<\s*b\s*\/\s*>(\s*\S*)*/ , ''
    
    
    expiry = deal_data[0][:expiry];
    time = Time.now + 
      (expiry[0..1].to_i * 3600 * 24) + 
      (expiry[2..3].to_i * 3600) + 
      (expiry[4..5].to_i * 60) + 
      (expiry[6..7].to_i * 60)
    
    deal_data[0][:expiry] = time.strftime("%Y-%m-%d %H:%M:%S")
    
    latlng = geocode deal_data[0][:location]
    
    deal_data[0][:latitude] = latlng[:lat]
    deal_data[0][:longitude] = latlng[:lng]
    deal_data[0][:author] = $deal_config[$site_name]['author']
    
    deal_data
  end
end

Lucky7Scraper.new.start