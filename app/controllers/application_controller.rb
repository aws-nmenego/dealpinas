class ApplicationController < ActionController::Base

  protect_from_forgery
  include SessionsHelper
  include Geokit::Geocoders
  include ActionView::Helpers::NumberHelper
    
  Geokit::Geocoders::proxy_addr = '192.168.179.202'
  Geokit::Geocoders::proxy_port =  3128
  
  def authenticate
    deny_user_access unless user_signed_in?
  end
 
end
