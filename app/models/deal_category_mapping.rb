
class DealCategoryMapping < ActiveRecord::Base
  set_primary_keys :deal_id , :category_id
  
  belongs_to :deal
  belongs_to :category
  
end

