class ImportsController < ApplicationController
  before_filter :authenticate
  require 'fastercsv'
  require 'FasterCSV'
  require 'fcsv'
  
  def csv_import
    #@parsed_file=CSV::Reader.parse(params[:dump][:file]) 
    #@parsed_file=CSV::read(params[:dump][:file])
    if request.post?
          parsed_rows=FasterCSV.parse(params[:file])
           parsed_rows.each do |row|
            puts "#{row[name]}"
           end
      
      #@parsed_file=CSV::Reader.parse(params[:dump][:file])
      #@parsed_file = FasterCSV.parse(params[:dump][:file])    
      #n=0
      #@parsed_file.each do |row|
        #c=Student.new
        #c.admission_no=row[0]
        #c.class_roll_no=row[1]
        #c.admission_date=row[2]
        #c.first_name= row[3]
         # if c.save
         # n=n+1
         # flash[:notice]="CSV Import Successful, #{n} new records added to data base"
         # end
     # end
    end
  end
end
