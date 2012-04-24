
class Category < ActiveRecord::Base
  set_primary_keys :category_id
  
#  has_many :deals , :include => :deal_locations
  has_many :deal_category_mappings
  has_many :deals , :include => :deal_locations , :through => :deal_category_mappings
  
  
  validates_length_of :category_name, :within => 1..20
  validates_uniqueness_of :category_name, :message => "already exists"
end
