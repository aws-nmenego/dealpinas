class SalesController < ApplicationController
  before_filter :authenticate
  # GET /sales
  # GET /sales.json
  def index
    @sales = Sale.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @sales }
    end
  end

  # GET /sales/1
  # GET /sales/1.json
  def show
    @sale = Sale.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @sale }
    end
  end

  # GET /sales/new
  # GET /sales/new.json
  def new
    @deal = Deal.find(params[:deal_id])
    @sale = Sale.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @sale }
      format.json { render json: @deal }
    end
  end

  # GET /sales/1/edit
  def edit
    @sale = Sale.find(params[:id])
  end

  # POST /sales
  # POST /sales.json
  def create
    @deal = Deal.find(params[:deal][:deal_id]);
    
    
    
    sale_hash = {
      :purchase_date => DateTime.now,
      :total_amount => (@deal.price.to_f * params[:sale]['quantity'].to_f),
      :user_id => current_user.id,
      :quantity => params[:sale][:quantity]
    }
    @sale = Sale.new(sale_hash)
    
    success = nil;
    
    ActiveRecord::Base.transaction do
      success = @sale.save
      
      sale_detail = SaleDetail.new( { :sale_id => @sale.id , :deal_id => @deal.id } )
      
      success = success && sale_detail.save
    end

    respond_to do |format|
      if success
        format.html { redirect_to @sale, notice: 'Sale was successfully created.' }
        format.json { render json: @sale, status: :created, location: @sale }
      else
        format.html { render action: "new" }
        format.json { render json: @sale.errors, status: :unprocessable_entity }
      end
    end
    
  end

  # PUT /sales/1
  # PUT /sales/1.json
  def update
    @sale = Sale.find(params[:id])

    respond_to do |format|
      if @sale.update_attributes(params[:sale])
        format.html { redirect_to @sale, notice: 'Sale was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @sale.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sales/1
  # DELETE /sales/1.json
  def destroy
    @sale = Sale.find(params[:id])
    @sale.destroy

    respond_to do |format|
      format.html { redirect_to sales_url }
      format.json { head :no_content }
    end
  end
end
