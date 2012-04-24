=begin
==
== Author		: Advanced World Solutions, Inc.
== Created on	: January 19, 2012
==
== Description	:
== 		This class collects the data in a deal and cleans them with the clean_values() method.
==		The resulting deal is stored in the database.
==
=end

class Deal

	attr_accessor :price, 
    :deal_url, 
    :title, 
    :sold, 
    :items, 
    :location, 
    :category, 
    :deal_thumb, 
    :description,
    :longitude,
    :latitude,
    :discount,
    :expiry,
    :author
  
	# clean values, unless not found
	def clean_values
	
		# alphanumeric and '%&!\n'
    if !@title.nil?
      @title 		= @title.content.to_s.strip.gsub(/\s+/i,' ')
    end
		
    # $-_.+!*'(),/
    if !@deal_url.nil?
      @deal_url	= @deal_url.to_s.strip
    end
    
    if !@deal_thumb.nil?
      @deal_thumb	= @deal_thumb.to_s.strip
    end
    
		# numbers only
    if !@sold.nil?
      @sold		= @sold.content.to_s.strip.gsub(/[^0-9 ]/i, '')
    end
    
    if !@items.nil?
      @items		= @items.content.to_s.strip.gsub(/[^0-9 ]/i, '')
    end
    
		# numbers with decimal point
    if !@price.nil?
      @price		= @price.content.to_s.strip.gsub(/[^0-9. ]/i, '')	
    end

		# characters in address
		if !@location.nil?
      @location	= @location.content.to_s.strip.gsub(/\s+/i,' ')
    end
    
		# alphanumeric
		if !@category.nil?
      @category	= @category.content.to_s.strip.gsub(/[^0-9a-z ]/i, '')
    end
    
    #
    if !@description.nil?
      @description = @description.content.to_s.strip.gsub(/\s+/i,' ')
    end
    
    # todo: rss id
    #@rss_id = @rss_id.to_s.strip.gsub(/[^0-9a-z$-_.+!*'(),\/ ]/i, '')	unless @rss_id == ""
    
    if !@discount.nil?
      @discount = @discount.content.to_s.gsub(/[^0-9.%]/i, '')
    end
    
		
	end
	
	# initialize class depending on number of variables
	# depending on the data that can be retrieved from the site, you may modify values here.
	def initialize( *args )
    @title 		   = args[0]
    @deal_url	   = args[1]
    @deal_thumb	 = args[2]
    @price 		   = args[3]
    @location	   = args[4]
    @sold		     = args[5]
    @items		   = args[6]
    @category	   = args[7]
    @description = args[8]
    @latitude    = args[9]
    @longitude   = args[10]
    @discount    = args[11]
    if !args[12]
      clean_values
    end
  end
end