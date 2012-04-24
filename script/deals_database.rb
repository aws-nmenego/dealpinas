=begin
==
== Author		: Advanced World Solutions, Inc.
== Created on	: January 19, 2012
==
== Description	:
==		All query for the cron-jobs will be done here.
== 		This is implemented using singleton.
== 		Use Database.instance to refer to this class.
==		
=end

require 'singleton'
require 'mysql2'
require 'logger'
require 'yaml'


class DealsDatabase

  $db_config =  nil
  $db_mode = nil
  
	attr_accessor :dbh, :log, :host, :user, :db_name, :password
	include Singleton
  
    	
	def initialize
    @log = Logger.new( "#{__FILE__}.log", 'daily'  )
	end
  
  def instantiate config,mode = "development"
    $db_config = config
    $db_mode = mode
    
    
			read_config
    @dbh = Mysql2::Client.new(:host => @host, :username => @user, :password => @password, :database => @db_name)
      
		rescue Mysql2::Error => e
			
    puts "#{__method__} An error has occured. Please check logs."

    @log.fatal "Error code: #{e.error_number}"
    @log.fatal "Error SQLSTATE: #{e.sql_state}" if e.respond_to?("sqlstate")
		@log.info "END #{__FILE__}.#{__method__}"
  end
	
	# close database connection
	def close
	
		@log.info "START #{__FILE__}.#{__method__}"
	
		begin
		
			@dbh.close if @dbh
			@log.info "Database closed."
		
		rescue Mysql2::Error => e
		
			puts "#{__method__} An error has occured. Please check logs."
			
			@log.fatal "Error code: #{e.error_number}"
			@log.fatal "Error SQLSTATE: #{e.sql_state}" if e.respond_to?("sqlstate")
			
		end
		
		@log.info "END #{__FILE__}.#{__method__}"
		
	end
	
	# read from config file database.yml
	def read_config
		
		@log.info "START #{__FILE__}.#{__method__}"
		
		begin
		
			config 		= YAML.load_file $db_config
			@host 		= config[$db_mode]["host"]	
			@user 		= config[$db_mode]["username"] 
			@db_name 	= config[$db_mode]["database"]
			@password 	= config[$db_mode]["password"]
		
		rescue Mysql2::Error => e
			
			puts "#{__FILE__}.#{__method__} An error has occured. Please check logs."
			
			@log.fatal "Error code: #{e.error_number}"
			@log.fatal "Error SQLSTATE: #{e.sql_state}" if e.respond_to?("sqlstate")
			
		end

		@log.info "END #{__FILE__}.#{__method__}"		
		
	end
  
  def esc(var)
#    if !var.nil?
#      return @dbh.escape(var)
#    else
#      return nil
#    end
    if !var.nil?
      var = var.gsub(/'/, "\\'")
    else
      return nil
    end
  end

###############################################################################
# all querries below 
###############################################################################
	
	# TODO optimize the following to receive an array of deals instead of just 1 deal at a time.
	def insert_deal(deal)
		
		@log.info "START #{__FILE__}.#{__method__}"
    if @dbh.nil?
      puts "nil"
    end
    
		begin

			@dbh.query("begin")
      
      ################### DEAL INSERTION
			# check to see if deal already exists
      deal_id = 0
			sql	= "SELECT * FROM `deals` WHERE `deal_url` = '#{deal.deal_url}'"
			@log.info "EXECUTE: #{sql}"
			res	= @dbh.query(sql)
			@log.info "QUERY OK"
			
      # NOTE: the following is done with the assumption that deal URL does not change
			if res.none?
				# insert deal
        deal.description = @dbh.escape(deal.description)
				sql	= "INSERT INTO `deals`( `rss_deal_id`, `title`, `description`, `deal_url`, `deal_thumb`, 
						`price`, `no_of_items_sold`, `quantity`, `discount`, `author`, `expiry`, `created_at`, `updated_at` , `status`) 
						VALUES ('','#{esc deal.title}','#{esc deal.description}','#{esc deal.deal_url}','#{esc deal.deal_thumb}',
						'#{esc deal.price}','#{esc deal.sold}','#{esc deal.items}','#{esc deal.discount}', '#{esc deal.author}', '#{esc deal.expiry}', NOW(),NOW() , 'new');"
        
				@log.info "EXECUTE: #{sql}"
				@dbh.query(sql)
				@log.info "QUERY OK"
				
				# deal id for the deal_location
				deal_id	= @dbh.last_id
        puts "deal_id: #{deal_id}"
			else
        # update existing deal
        sql = "UPDATE `deals` SET `rss_deal_id`='',`title`='#{esc deal.title}',`description`='#{esc deal.description}',
              `price`='#{esc deal.price}',`quantity`='#{esc deal.items}',`deal_thumb`='#{esc deal.deal_thumb}',
              `updated_at`=NOW(),`no_of_items_sold`='#{esc deal.sold}', 
              `discount` = '#{esc deal.discount}', `author` = '#{esc deal.author}' , `expiry` = '#{esc deal.expiry}',
              status = 'old'
              WHERE `deal_url` = '#{deal.deal_url}'"
        @log.info "EXECUTE: #{sql}"
				@dbh.query(sql)
				@log.info "QUERY OK"
        
        res.each do |row|
          deal_id = row["deal_id"]
        end
				puts "deal_id: #{deal_id}"
			end
      
      ################### CATEGORIES SETTING
      
      # first, retrieve cat_id for 'others'
      others_cat_id = 0
      sql = "SELECT * FROM `categories` WHERE `category_name` = 'Others'"
      @log.info "EXECUTE: #{sql}"
      others_cat_id_res = @dbh.query(sql)
      others_cat_id_res.each do |row|
        others_cat_id = row["category_id"]
      end
      @log.info "QUERY OK"
      
      # TODO: improve the following. Insert first before categorizing.
      # loop each tag and check if it is in the description
      # if so, insert cat_id to array
      
      # retrieve the tags
      sql = "SELECT * FROM `tags` WHERE 1"
      @log.info "EXECUTE: #{sql}"
      tags = @dbh.query(sql)
      @log.info "QUERY OK"
      
      cat_ids = Array.new
      tags.each do |tag|
        #if description or title contains the tag
        #puts "#{tag["tag"]}"
        if /(^|\s+)#{tag["tag"]}(\s+|$)/i.match(deal.description) 
          #puts "#{deal.description} => #{tag["tag"]}"
          cat_ids << tag["category_id"]
        elsif /(^|\s+)#{tag["tag"]}(\s+|$)/i.match(deal.title)
          #puts "#{deal.title} => #{tag["tag"]}"          
          cat_ids << tag["category_id"]       
        elsif /(^|\s+)#{tag["tag"]}(\s+|$)/i.match(deal.category)
          #puts "#{deal.category} => #{tag["tag"]}"          
          cat_ids << tag["category_id"]       
        end
      end 
      
      # delete all mappings having the deal_id
      sql = "DELETE FROM `deal_category_mappings` WHERE `deal_id` = #{deal_id}"
      @log.info "EXECUTE #{sql}"
      @dbh.query sql
      @log.info "QUERY OK"
      
      if cat_ids.empty?
        puts "cat_id: #{others_cat_id}"
        sql = "INSERT INTO `deal_category_mappings` (`category_id`,`deal_id`) VALUES (#{others_cat_id},#{deal_id})"
      else
        sql = "INSERT INTO `deal_category_mappings`(`category_id`,`deal_id`) VALUES "
        str_cat_id = "cat_ids: ["
        cat_ids = cat_ids.uniq
        last_cat_id = cat_ids.pop
        cat_ids.each do |cat_id|
          sql += "(#{cat_id},#{deal_id}), "
          str_cat_id += "#{cat_id}, "
        end
        sql += "(#{last_cat_id},#{deal_id})"
        str_cat_id += "#{last_cat_id}]"
        puts str_cat_id
      end

      @log.info "EXECUTE: #{sql}"
      @dbh.query sql
      @log.info "QUERY OK"

					
			# TODO support for multiple location insertion
			# insert location/s
			# something like this...
#			deal.location.each do |deal|
#				sql	= "INSERT INTO `deal_locations`(`deal_location`, `deal_id`, `created_at`, `updated_at`)
#					VALUES ('#{deal}','#{deal_id}',NOW(), NOW());#"
#				@log.info "EXECUTE: #{sql}"		
#				@dbh.query(sql)
#				@log.info "QUERY OK"
#			end

      ################### DEAL_LOCATION INSERTION
      # delete all locations for the deal
      sql = "DELETE FROM `deal_locations` WHERE `deal_id` = #{deal_id}"
      @log.info "EXECUTE: #{sql}"		
			@dbh.query(sql)
			@log.info "QUERY OK"
      
      # insert updated/new locations
      if deal.latitude.nil? || deal.longitude.nil?
        sql	= "INSERT INTO `deal_locations`(`location_name`, `deal_id`, `created_at`, `updated_at`)
					VALUES ('#{esc deal.location}','#{deal_id}',NOW(), NOW());"  
      else
        sql	= "INSERT INTO `deal_locations`(`location_name`, `deal_id`, `latitude`, `longitude`, `created_at`, `updated_at`)
					VALUES ('#{esc deal.location}','#{deal_id}','#{deal.latitude}','#{deal.longitude}',NOW(), NOW());"       
      end
      
			@log.info "EXECUTE: #{sql}"		
			@dbh.query(sql)
			@log.info "QUERY OK"

			@dbh.query("commit")
			
		rescue Mysql2::Error => e
		
			puts "#{__FILE__}.#{__method__} An error has occured. Please check logs."
			
			@log.fatal "Error code: #{e.error_number}"
			@log.fatal "Error SQLSTATE: #{e.sql_state}" if e.respond_to?("sqlstate")
			
			@dbh.query("rollback")
						
		ensure
			# closing will cause error, call close function
			# @dbh.close
			
		end
		
		@log.info "END #{__FILE__}.#{__method__}"
		
	end
  
end

