
class Deal < ActiveRecord::Base
  set_primary_keys :deal_id
  
#  belongs_to :category
  has_many :deal_category_mappings
  has_many :categories , :through => :deal_category_mappings
  has_many :images
  has_many :deal_locations 
  
#  has_many :sale_details
#  has_many :sales, :through => :sale_details
  
  # some model validations
#  validates_associated :deal_locations
#  validates_associated :deal_category_mappings
  validates  :title , :description, :price, :expiry, :deal_thumb, :presence=> true 
  validates :title, :length => { :maximum => 255 }

  validates :price, :original_price,
    :format => { :with => /^\d+(\.?\d*)?$/, :message => "invalid price format."}
  
  validates :deal_url, 
    :uniqueness => { :case_sensitive => false }
end
