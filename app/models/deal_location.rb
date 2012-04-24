
class DealLocation < ActiveRecord::Base
  set_primary_keys :location_id
  
  belongs_to  :deal
  
  validates :location_name , :presence=>true
  
  scope :location_name, where(true)
  
end
