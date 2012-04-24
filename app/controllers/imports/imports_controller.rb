class ImportsController < ApplicationController
  
  def index
    respond_to do |format|
      format.html # index.html.erb
    end
  end

   def csv_import
     @parsed_file = CSV::parse(params[:dump][:file])
     #@parsed_file=CSV::Reader.parse()
     n=0
     
     @parsed_file.each  do |row|
       c=CustomerInformation.new
       c.job_title=row[1]
       c.first_name=row[2]
       c.last_name=row[3]
         if c.save
            n=n+1
            GC.start
         end
         if n%50==0
            flash.now[:message]="CSV Import Successful,  #{n} new
                                records added to data base"
         end
     end
   end
  
end
