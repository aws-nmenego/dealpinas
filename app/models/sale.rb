

class Sale < ActiveRecord::Base
  set_primary_keys :sales_id

#  has_many :sale_details
#  has_many :deals, :through => :sale_details
end
