class DealsController < ApplicationController
  DEAL_LIMIT = 10;
  
  before_filter :authenticate , :except=>['index','get_deals_within_bounds','get_deal','get_deals_for_view',]
  # GET /deals
  # GET /deals.json
  def index
#    @deals = Deal.find( :all , :include => :deal_locations, 
#      :limit=>DEAL_LIMIT , 
#      :offset=>0)
    
    if (current_site_user)
      @username = current_site_user[:email]
      @is_admin = current_site_user.user_type[:type_name] == 'Admin'?'true':'false';
    else
      @username = ''
      @is_admin = 'false'
    end
    
    @categories = Category.find :all
    
    authors = YAML.load_file 'config/deal_sites.yml'
    i = 0
    @deal_sites = '['
    authors.each do |key , author|
      if author and author['author']
        @deal_sites += '"'+author['author']+'"'
        if i < authors.length-1
          @deal_sites+=','
        else
          @deal_sites+=''
        end
        i = i+1
      end
    end
    @deal_sites += ']'
    
    @offset = DEAL_LIMIT
    @limit = DEAL_LIMIT
    
    if params['deal_id']
      @focus_deal = params['deal_id']
    else
      @focus_deal = -1;
    end
      
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @categories }
    end
  end
  
  
  def get_deals_for_view
    @disable_layout = true;

    joins = '
               INNER JOIN `deal_category_mappings` ON `deal_category_mappings`.`deal_id` = `deals`.`deal_id`
               INNER JOIN `categories` ON `deal_category_mappings`.`category_id` = `categories`.`category_id`
               LEFT JOIN `deal_locations` ON `deal_locations`.`deal_id` = `deals`.`deal_id`
               LEFT JOIN `users` ON users.user_name = deals.author
               LEFT JOIN `user_types` ON users.user_type_id = user_types.id
      '
    where =[' (`deals`.`title` LIKE ? OR `deals`.`description` LIKE ? OR `deal_url` LIKE ? OR `deals`.`author` LIKE ?) 
              AND (`categories`.`category_name` LIKE ? OR `categories`.`category_name` IS NULL ) 
              AND (`location_name` LIKE ? OR location_name IS NULL ) AND expiry > now() AND reviewed AND (status LIKE ?)
              AND (is_ad = ? OR is_ad = ?)
        ',
       params['what'] , params['what'] , 
       params['what'] , params['what'] , 
       params['category'], params['location_name'] , 
       params['status'] , params['is_ad'].split(',')[0],
       params['is_ad'].split(',')[1]
     ]
    
    deals = Deal.find(:all,
      :limit=>DEAL_LIMIT,
#      :include=> [:deal_locations],
      :offset=>params['offset'].to_i,
      :joins=> joins,
      :conditions=>where,
      :select=>'DISTINCT deals.* , type_name'
    )
  
    @results = Array.new
    deals.each do |deal|
        hash = {
          :deal_id=>deal.id , 
          :title=>deal.title , 
          :deal_locations=> nil , 
          :deal_url=> deal.deal_url,
          :image_url=> deal.deal_thumb,
          :price=> deal.price > 0 ? number_to_currency(deal.price , :unit=>'P') : '',
          :description => deal.description,
          :discount=>deal.discount,
          :author => deal.type_name == 'Admin' ? 'Deal Pinas' : deal.author,
          :expiry => deal.expiry,
          :is_ad => deal.is_ad
        }
        @results << hash
    end
  end
  
  
  def get_deals_within_bounds 
    @disable_layout = true;
    
    joins = '
               INNER JOIN `deal_category_mappings` ON `deal_category_mappings`.`deal_id` = `deals`.`deal_id`
               INNER JOIN `categories` ON `deal_category_mappings`.`category_id` = `categories`.`category_id`
               LEFT JOIN `deal_locations` ON `deal_locations`.`deal_id` = `deals`.`deal_id`
      '
    where =[' (`deals`.`title` LIKE ? OR `deals`.`description` LIKE ? OR `deal_url` LIKE ? OR `deals`.`author` LIKE ?) 
              AND (`categories`.`category_name` LIKE ? OR `categories`.`category_name` IS NULL ) 
              AND (`location_name` LIKE ? OR location_name IS NULL ) 
              AND expiry > now() 
              AND reviewed 
              AND (status LIKE ?)
              AND (is_ad = ? OR is_ad = ?) 
        ',
        params['what'] , params['what'] , 
        params['what'] , params['what'] , 
        params['category'], params['location_name'],
        params['status'] , params['is_ad'].split(',')[0] ,
        params['is_ad'].split(',')[1]
     ]
      
    deals = Deal.find(:all,
      :conditions => where,
      :joins => joins,
      :select => ' DISTINCT 
          deals.deal_id, 
          title, 
          deal_url , 
          deals.description , 
          deal_locations.latitude,
          deal_locations.longitude,
          categories.icon_image
      '
    )
    
    @results = Hash.new
    
    deals.each do |deal|
      #search for boundary specific deals
      #deal_locations = deal.deal_locations.where 'latitude < ? AND longitude < ? AND latitude > ? AND longitude > ? ' , params['neLat'], params['neLng'],params['swLat'],params['swLng']
      
#      deal_locations = deal.deal_locations
#      deal_locations = deal_locations.find :all,:conditions=> [' location_name LIKE ?', params['location_name'] ]
#      locArray = Array.new
      
#      if (deal_locations.size > 0 )
#        deal_locations.each do |loc|
#          if loc.latitude && loc.longitude
#            locArray << { 'lat'=>loc.latitude.to_f, 'lng' => loc.longitude.to_f }
#          end
#        end
        
#        category = deal.categories.find :all , :conditions=>[' category_name LIKE ? ',params['category']];
#        category = category[0];
        loc = nil
        if deal and deal.respond_to?('latitude') and 
            deal.respond_to?('longitude') and 
            deal.longitude and 
            deal.latitude
              loc = { 'lat'=>deal.latitude.to_f , 'lng' => deal.longitude.to_f }
        end
        hash = { 
          :deal_id=>deal.id , 
          :title=>deal.title , 
#          :icon_url=> category.respond_to?('icon_image') ? category.icon_image : nil,
          :icon_url=> deal.respond_to?('icon_image') ? deal.icon_image : nil,
          :description => deal.description,
          :deal_url => deal.deal_url
        }
        
        if !@results[deal.id]  and loc
          hash[:deal_locations] = Array.new
          hash[:deal_locations] << loc
          @results[deal.id] = hash
        elsif loc
          @results[deal.id][:deal_locations] << loc
        end
#      end
    end
    
  end
  
  
  def get_deal
    @disable_layout = true;
    deal = Deal.find(
      params['deal_id'],
      :include=>:deal_locations , 
      :conditions=>[' reviewed '] ,
      :joins => '
            LEFT JOIN `users` ON users.user_name = deals.author
            LEFT JOIN `user_types` ON users.user_type_id = user_types.id
      ',
      :select => 'DISTINCT deals.* , user_types.type_name '
    );
    
    deal_location = Array.new;
    
    for i in 0..deal.deal_locations.size 
      deal_location << deal.deal_locations[i]
    end 
    
    @results = { 
        :deal_id => deal.id ,
        :image_url=> deal.deal_thumb, 
        :title => deal.title,
        :location=> deal_location,
        :description=> deal.description.length > 200 ?
          deal.description[0..200]+'...' :
          deal.description ,
        :discount_description=> deal.price>0 ? 
          number_to_currency(deal.price,:unit=>'P').to_s : '',
        :author=> deal.type_name == 'Admin' ? 'Deal Pinas' : deal.author,
        :is_ad => deal.is_ad,
        :deal_url=> deal.deal_url 
      };
  end

  
  # GET /deals/1
  # GET /deals/1.json
  def show
    @deal = Deal.find(params[:id])
    
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @deal }
    end
  end

  
  # GET /deals/new
  # GET /deals/new.json
  def new
    

    
    @deal = Deal.new
    if params[:ad] == 'true'
      @deal.is_ad = true
    end
    
    @category = Category.find(:all)
    @result = []

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @deal }
    end
  end

  
  # GET /deals/1/edit
  def edit
    
    if !user_signed_in?
      deny_user_access
      return
    end
    
    @result = []
    @category = Category.find(:all)
    @deal = Deal.find(params[:id])
  end

  
  # POST /deals
  # POST /deals.json
  def create
    
    @deal = Deal.new( params[:deal].except(:locations).except(:cat_ids).except(:images) );

    logger.info @deal
    
    # array of deal locations
    deal_locs = Array.new
    if !params[:deal][:locations].nil?
      params[:deal][:locations].each do |loc|
        # convert from json string to hash
        deal_loc = ActiveSupport::JSON.decode( loc )
        deal_locs << DealLocation.new(deal_loc)
      end
    end
    logger.info deal_locs
    
    # array of category ids
    deal_cats = Array.new
    if !params[:deal][:cat_ids].nil?
      params[:deal][:cat_ids].each do |cat_id|
        deal_cats << DealCategoryMapping.new(:category_id => cat_id)
      end
    end
    
    ad_images = Array.new
    if !params[:deal][:images].nil?
      params[:deal][:images].each do |image|
        deal_image = ActiveSupport::JSON.decode(image)
        ad_images << Image.new(deal_image)
      end
    end
    
    @result = save_deal @deal, deal_locs, deal_cats, ad_images
    if @result.blank?
      
      if @deal.is_ad == true
        flash[:notice] = 'Advertisement was successfully saved.' 
        redirect_to @deal
        return
      else
        flash[:notice] = 'Deal was successfully saved.'
        redirect_to "/deals?deal_id=#{@deal.deal_id}"
        return
      end

      
    else
      
      logger.info "An error has occured. Errors: #{@result}"
      @deal_category_mappings = deal_cats
      @deal_locations = deal_locs
      @deal_images = ad_images
      @category = Category.find(:all)
      respond_to do |format| 
        format.html { render action: 'new' }
        format.json { render json: @result, status: :unprocessable_entity }
      end
          
    end 
    
  end # end of create

  
  # PUT /deals/1
  # PUT /deals/1.json
  def update
    
    @deal = Deal.find(params[:id])
    @deal_category_mappings = DealCategoryMapping.where(:deal_id => params[:id])
    @deal_images = Image.where(:deal_id => params[:id])
    @deal_locations = DealLocation.where(:deal_id => params[:id])
    @result = []

    ActiveRecord::Base.transaction do
      if !@deal.update_attributes(params[:deal].except(:cat_ids).except(:locations).except(:images))
        @result = @result + @deal.errors.full_messages 
        raise ActiveRecord::Rollback
      end
      
      
      # delete previous entries
      @deal_category_mappings.each do |dcm|
        if !dcm.delete
          @result = @result + dcm.errors.full_messages
          raise ActiveRecord::Rollback
        end
      end      
      @deal_locations.each do |locs|
        if !locs.delete
          @result = @result + locs.errors.full_messages
          raise ActiveRecord::Rollback
        end
      end
      @deal_images.each do |img|
        if !img.delete
          @result = @result + img.errors.full_messages
          raise ActiveRecord::Rollback
        end
      end    

      # insert new entries
      @deal_category_mappings = []
      @deal_locations = []
      @deal_images = []
      
      if !params[:deal][:locations].nil?
        params[:deal][:locations].each do |loc|
          # convert from json string to hash
          deal_loc = ActiveSupport::JSON.decode( loc )
          @deal_locations << DealLocation.new(deal_loc)
          @deal_locations[-1].deal_id = params[:id]
          if !@deal_locations[-1].save
            @result = @result + @deal_locations[-1].errors.full_messages
            raise ActiveRecord::Rollback
          end
        end
      end
      
      if !params[:deal][:cat_ids].nil?
        params[:deal][:cat_ids].each do |cat_id|
          @deal_category_mappings << DealCategoryMapping.new(:category_id => cat_id)
          @deal_category_mappings[-1].deal_id = params[:id]
          if !@deal_category_mappings[-1].save
            @result = @result + @deal_category_mappings[-1].errors.full_messages
            raise ActiveRecord::Rollback
          end
        end
      end      
      
      if !params[:deal][:images].nil?
        params[:deal][:images].each do |image|
          img = ActiveSupport::JSON.decode(image)
          @deal_images << Image.new(img)
          @deal_images[-1].deal_id = params[:id]
          if !@deal_images[-1].save
            @result = @result + @deal_images[-1].errors.full_messages
            raise ActiveRecord::Rollback
          end
        end
      end
      
    end
    
    # redirect
    @category = Category.find(:all)
    respond_to do |format|
      if @result.blank?
        if @deal.is_ad == true
          format.html { redirect_to @deal, notice: 'Advertisement was successfully updated.' }
        else
          format.html { redirect_to @deal, notice: 'Deal was successfully updated.' }
        end
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @result, status: :unprocessable_entity }
      end
    end
  end # end of update
  

  # DELETE /deals/1
  # DELETE /deals/1.json
  def destroy
    @deal = Deal.find(params[:id])
    @deal.destroy

    respond_to do |format|
      format.html { redirect_to deals_url }
      format.json { head :no_content }
    end
  end
  
  
  # GET /deals/import
  def import
    @category = Category.find(:all)
    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  
  # POST /deal/upload
  def upload
    uploaded_io = params[:file]
    @category = Category.find(:all)
    #logger.info uploaded_io.read
    begin
      doc = Nokogiri::XML uploaded_io.read
    rescue
      @result = ["File read error"]
      logger.info "An error has occured. Errors: #{@result}"
      
      respond_to do |format| 
        format.html { render action: 'import' }
        format.json { render json: @result, status: :unprocessable_entity }
      end
      return
    end
    
    # loop around <deals>
    doc.xpath('//deal').each do |xml_deal|
      deal_locs = Array.new
      deal_cats = Array.new
      deal = Deal.new(
      :title => get_text(xml_deal.xpath('title')),
      :description => get_text(xml_deal.xpath('description')),
      :deal_url => get_text(xml_deal.xpath('deal_url')),
      :deal_thumb => get_text(xml_deal.xpath('deal_thumb')),
      :original_price => get_text(xml_deal.xpath('original_price')),
      :price => get_text(xml_deal.xpath('discounted_price')),
      :discount => get_discount( get_text(xml_deal.xpath('original_price')), get_text(xml_deal.xpath('discounted_price')) ),
      :expiry => get_text(xml_deal.xpath('expiry')),
      :merchant_name => get_text(xml_deal.xpath('merchant_name')),
      :contact_name => get_text(xml_deal.xpath('contact_name')),
      :contact_number => get_text(xml_deal.xpath('contact_number')),
      :contact_email => get_text(xml_deal.xpath('contact_email')),
      :contact_address => get_text(xml_deal.xpath('contact_address')),
      :contact_url => get_text(xml_deal.xpath('contact_url')),
      :author => User.find(current_site_user.id).user_name
      )

      # loop around <locations>
      xml_deal.xpath('locations/location').each do |xml_location|
        location = DealLocation.new
        
        location.location_name = get_text xml_location.xpath('location_name')
        location.latitude = get_text xml_location.xpath('latitude')
        location.longitude = get_text xml_location.xpath('longitude')
        
        deal_locs << location
      end 

      # loop around <categories>
      xml_deal.xpath('categories/category').each do |xml_categories|
        deal_category_mapping = DealCategoryMapping.new        
        cat_id = Category.where(:code => xml_categories.text).first
        
        deal_category_mapping.category_id = cat_id.category_id
        
        deal_cats << deal_category_mapping

      end
      
      # save deals stop on error
      @result = save_deal deal, deal_locs, deal_cats
      break if !@result.blank?

    end # end of deal loop


    if !@result.blank?
      
      logger.info "An error has occured. Errors: #{@result}"
      
      respond_to do |format| 
        format.html { render action: 'import' }
        format.json { render json: @result, status: :unprocessable_entity }
      end
    else
      
      flash[:notice] = 'Your deals were successfully saved.'

      respond_to do |format| 
        format.html { render action: 'import' }
        format.json { render json: @result }
      end
          
    end 
 
  end # end of import  
  
  
  def print
    @disable_layout = true
    @deal = Deal.find(params[:deal_id])        
  end
  
  
  
  private
  
  
  # use this when saving deal
  # returns errors
  def save_deal( deal, deal_locs = [], deal_cats = [], ad_images = [])
    
    errors = Array.new
    ActiveRecord::Base.transaction do
        # STEP1: save deal
        deal.author = User.find(current_site_user.id).user_name
        if deal.save
          deal_id = deal.deal_id
          
          logger.info "\n\n!!!HERE #{deal_id}!!!\n\n"
          # insert a url corresponding to site page when deal_url is blank
          if deal.deal_url.blank? 

            if deal.update_attributes({ :deal_url =>"/deals/#{deal_id}" })
              logger.info "deal_url #{deal.deal_url} was updated!"
            else
              logger.info deal.errors.full_messages
              logger.info "Deal update error"
              errors = errors + deal.errors.full_messages
              raise ActiveRecord::Rollback
            end
          end

        else
          logger.info deal.errors.full_messages
          logger.info "Deal save error."
          errors = errors + deal.errors.full_messages
          raise ActiveRecord::Rollback
        end

        # STEP2: save locations
        #if !deal_locs.blank?
          deal_locs.each do |loc|
            loc.deal_id = deal_id

            if loc.save
              logger.info "location_id: #{loc.location_id}-deal: #{deal_id} was saved!"
            else 
              logger.info loc.errors.full_messages
              logger.info "Locations save error."
              errors = errors + loc.errors.full_messages
              raise ActiveRecord::Rollback
            end        

          end
        #end

        #STEP3: save category mapping
        #if !deal_cats.blank?
          deal_cats.each do |cat|
            cat.deal_id = deal_id

            if cat.save
              logger.info "cat: #{cat.category_id}-deal: #{deal_id} was saved!"
            else
              logger.info cat.errors.full_messages
              logger.info "Category save error."
              errors = errors + cat.errors.full_messages
              raise ActiveRecord::Rollback
            end
          end
        #end
        
        #STEP4: save images
        ad_images.each do |image|
          image.deal_id = deal_id
          
          if image.save
            logger.info "image: #{image.url}-deal: #{deal_id} was saved!"
          else
            logger.info image.errors.full_messages
            logger.info "Image save error"
            errors = errors + image.errors.full_messages
            raise ActiveRecord::Rollback
          end
        
        end
        
    end # end of transaction  
    
    # return true when everything is OK
    return errors    
    
  end # end of save_deal
    
  
  # utility functions
  def get_text( node = nil )
    
    if !node.nil?
      return node.text
    end
    
  end 
  
  def get_discount(orig_price = nil , disc_price = nil)
    
    if !orig_price.nil? && orig_price != 0 && !disc_price.nil?
      return "#{ ((Float(disc_price)/Float(orig_price))*100).round }%"
    else
      return nil
    end
    
  end 
  
  def scrape_schedule
    
  end
  
  def authenticate
    if !user_signed_in?
      store_location
      redirect_to signin_path, notice: "Sorry. You must login before you can view this page."
    end
  end
  
end # class end
