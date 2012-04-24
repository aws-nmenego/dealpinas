class DealLocationsController < ApplicationController
  # GET /deal_locations
  # GET /deal_locations.json
  def index
    
    if !allowed_to_edit_locations?
      redirect_to root_path
      return
    end  
    #@deal_locations =  DealLocation.all
    @deal_locations = DealLocation.where( :deal_id => params[:deal_id] )
    @deal_locations_form = DealLocation.new
    @deal_name = Deal.where( :deal_id => params[:deal_id] )
    @deal_id = params[:deal_id]
    #@deal_locations = DealLocation.where( :deal_id=> params[:deal_id] )
    
    respond_to do |format|
      format.html
      format.json { render json: @deal_name }
      format.json { render json: @deal_locations }
    end
  end

  # GET /deal_locations/1
  # GET /deal_locations/1.json
  def show
    @deal_location = DealLocation.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @deal_location }
    end
  end

  # GET /deal_locations/new
  # GET /deal_locations/new.json
  def new
    @deal_location = DealLocation.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @deal_location }
    end
  end

  # GET /deal_locations/1/edit
  def edit
    @deal_location = DealLocation.find(params[:id])
  end

  # POST /deal_locations
  # POST /deal_locations.json
  def create
#    @deal_location = DealLocation.new(params[:deal_location])
#
#    respond_to do |format|
#      if @deal_location.save
#        format.html { redirect_to @deal_location, notice: 'Deal location was successfully created.' }
#        format.json { render json: @deal_location, status: :created, location: @deal_location }
#      else
#        format.html { render action: "new" }
#        format.json { render json: @deal_location.errors, status: :unprocessable_entity }
#      end
#    end
#    
    DealLocation.transaction do
      begin 
        @prev_location = DealLocation.where( :deal_id => params[:deal_location][:deal_id] )
        @prev_location.delete_all( :deal_id => params[:deal_location][:deal_id] )
      rescue ActiveRecord::Rollback
        logger.info "[DEAL_LOCATIONS CREATE]An error has occured."
        redirect_to :deal_locations
      end
    end
    
    # make sure if there is anything to insert
    if params[:deal_location][:empty] != 'empty'
      # insert gracefully
      DealLocation.transaction do
        # delete previous records
        begin
          # todo: rollback on error
          params[:deal_location][:name].each do |t|

            new_location = ActiveSupport::JSON.decode(t)
            deal = DealLocation.new

            logger.info new_location
            deal.location_name = new_location["location_name"] || nil
            deal.longitude = new_location["longitude"] || nil
            deal.latitude = new_location["latitude"] || nil
            deal.deal_id = new_location["deal_id"] || nil
            if deal.save
              logger.info "Successfully inserted"
            else
              raise ActiveRecord::Rollback
            end

          end


        rescue ActiveRecord::Rollback
          logger.info "An error has occured."
          redirect_to :deal_locations
        end
      end
    end
    
    redirect_to :deals
    
  end

  # PUT /deal_locations/1
  # PUT /deal_locations/1.json
  def update
    @deal_location = DealLocation.find(params[:id])

    respond_to do |format|
      if @deal_location.update_attributes(params[:deal_location])
        format.html { redirect_to @deal_location, notice: 'Deal location was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @deal_location.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /deal_locations/1
  # DELETE /deal_locations/1.json
  def destroy
    @deal_location = DealLocation.find(params[:id])
    @deal_location.destroy

    respond_to do |format|
      format.html { redirect_to deal_locations_url }
      format.json { head :no_content }
    end
  end
end
