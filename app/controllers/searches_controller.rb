class SearchesController < ApplicationController
    before_filter :authenticate
  def new
    @search = Search.new
  end

  def create
    @search = Search.new(params[:search])
    if @search.save
      redirect_to @search, :notice => "Successfully created search."
    else
      render :action => 'new'
    end
  end

  def show
    @search = Search.find(params[:id])
  end
end
