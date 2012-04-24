class SaleDetailsController < ApplicationController
  before_filter :authenticate
  # GET /sale_details
  # GET /sale_details.json
  def index
    @sale_details = SaleDetail.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @sale_details }
    end
  end

  # GET /sale_details/1
  # GET /sale_details/1.json
  def show
    @sale_detail = SaleDetail.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @sale_detail }
    end
  end

  # GET /sale_details/new
  # GET /sale_details/new.json
  def new
    @sale_detail = SaleDetail.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @sale_detail }
    end
  end

  # GET /sale_details/1/edit
  def edit
    @sale_detail = SaleDetail.find(params[:id])
  end

  # POST /sale_details
  # POST /sale_details.json
  def create
    @sale_detail = SaleDetail.new(params[:sale_detail])

    respond_to do |format|
      if @sale_detail.save
        format.html { redirect_to @sale_detail, notice: 'Sale detail was successfully created.' }
        format.json { render json: @sale_detail, status: :created, location: @sale_detail }
      else
        format.html { render action: "new" }
        format.json { render json: @sale_detail.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /sale_details/1
  # PUT /sale_details/1.json
  def update
    @sale_detail = SaleDetail.find(params[:id])

    respond_to do |format|
      if @sale_detail.update_attributes(params[:sale_detail])
        format.html { redirect_to @sale_detail, notice: 'Sale detail was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @sale_detail.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sale_details/1
  # DELETE /sale_details/1.json
  def destroy
    @sale_detail = SaleDetail.find(params[:id])
    @sale_detail.destroy

    respond_to do |format|
      format.html { redirect_to sale_details_url }
      format.json { head :no_content }
    end
  end
end
