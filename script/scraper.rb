require 'nokogiri'
require 'open-uri'
require 'mysql2'
require 'uri'
require 'cgi'
require 'logger'
require 'geocoder'
require 'geokit'
require 'json'
require 'iconv'

include GeoKit::Geocoders

class Scraper
  
#  $deal_config =  YAML.load_file "../config/deal_sites.yml"
  $deal_config =  nil
  $proxy = nil
  $site_name = nil
  $db = DealsDatabase.instance
  $deal_site_dir = nil
  
  def initialize yml_dir  , site_name 
    $deal_site_dir = yml_dir+'/deal_sites.yml'
    $deal_config =  YAML.load_file $deal_site_dir
    $site_name = site_name
    $url_root 	= $deal_config[$site_name]["site_url"]
    $proxy = $deal_config["proxy"]["http"]
    $db.instantiate yml_dir+'/database.yml'
    
    GeoKit::Geocoders::proxy_addr=$deal_config["Geokit"]["address"]
    GeoKit::Geocoders::proxy_port=$deal_config["Geokit"]["port"] 
  end

  def remove_br html
    ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
    v = ic.iconv(html.to_s + ' ')[0..-2]
    html = v.to_s.gsub /<\s*br\s*\/?\s*>/ , ''
    html = Nokogiri::HTML html
  end

  def from_parent_div ( nokogiri_html , parent_xpath , target_elements = {} )
    parent_list = nokogiri_html.xpath parent_xpath
    ret = Array.new
    
    parent_list.each do | child_target |
      child_target = Nokogiri::XML(child_target.to_s)
      e = {}
      target_elements.each do |key,value|  
        if value[:as_list]
          c = child_target.xpath value[:xml_path]
          e[key] = c
        else
          if value[:xml_path].is_a? Array
            value[:xml_path].each do |x| 
              xpath_and_store child_target, 
                value[:xml_path], 
                value[:target_attribute], 
                key ,
                e
              break if e[key]
            end
          else
            xpath_and_store child_target, 
              value[:xml_path], 
              value[:target_attribute], 
              key,
              e
          end
          
        end
      end
      ret << e
    end
    ret
  end
  
  def xpath_and_store target, xml_path , target_attribute , key , e
    c = target.at_xpath xml_path
    if !c
      return nil
    end
    
    begin
      if target_attribute.is_a? Array
        target_attribute.each do |t|
          if t == :html
            e[key] = c.to_s
          elsif t
            e[key] = c[ t ]
            break if e[key]
          else
            e[key] = c.content
            break if e[key]
          end
        end
      else
        if target_attribute == :html
          e[key] = c.to_s
        elsif (!target_attribute)
          e[key] = c.content
        else
          e[key] = c[ target_attribute ]
        end
      end
    rescue NoMethodError
      puts 'No method error:'+ key.to_s+'-'+
        xml_path.to_s + 
        '['+(target_attribute ? target_attribute  : 'content')+']'
      e[key] = nil
    end
  end
  
  def remove_tags string
    ret = string.gsub /<\s*\S*>/ , ''
    ret
  end

  def get_element_by_id nokogiri_html , element , attribute , child=nil
    (nokogiri_html.at_xpath '//' + element + '[@id="' + attribute + '"]'+(child ? child : '')).content
  end
  
  def geocode address
    if not address.nil? 
      address = address.force_encoding 'UTF-8'
      begin 
        d = GoogleGeocoder3.geocode(address)
        return { :lat=>d.lat , :lng=>d.lng }
      rescue
        return { :lat=>nil , :lng=>nil }
      end
    end
    puts 'No matched location'
    return {:lat=>nil , :lng=>nil}
  end
  
  def reverse_geocode lat, lng
    c = GoogleGeocoder3.reverse_geocode(Geokit::LatLng.new(lat,lng))
    c = c.full_address
    c
  end
  
  # combines two hashes
  # if they share the same key with existing values,
  # an array is created containing the values of the two hashes 
  # of the specified key
  def combine_hash hash1, hash2
    hash1.each_pair do| key , value |
      if !hash2[key]
        hash2[key] = value
      else
        temp = hash2[key]
        hash2[key] = Array.new
        hash2[key] << temp;
        hash2[key] << value
      end
    end
    hash2
  end
  
  def start
    $deal_config =  YAML.load_file $deal_site_dir
    $deal_config[$site_name]['scraping'] = true
    YAML.dump  $deal_config , open($deal_site_dir,'w')
    
    begin
      start_retrieval
    rescue
    end
    
    
    $deal_config =  YAML.load_file $deal_site_dir
    $deal_config[$site_name]['scraping'] = false
    YAML.dump $deal_config , open($deal_site_dir,'w');
  end
  
  def start_retrieval
  end
  
  def trim_space str
    str = str.gsub /\s*/ , ''
    str
  end
  
end
