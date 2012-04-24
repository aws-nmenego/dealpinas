
class UserType < ActiveRecord::Base
  
  set_primary_keys :id
  
  has_many :users
end
