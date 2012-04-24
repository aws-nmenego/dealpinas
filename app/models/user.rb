require 'rubygems'
require 'composite_primary_keys'
require 'digest'

class User < ActiveRecord::Base
    
  attr_accessor :password
#  attr_accessible :name, 
#    :email, 
#    :password, 
#    :password_confirmation, 
#    :last_name, 
#    :first_name, 
#    :user_type_id,
#    :company_name
  
  belongs_to :user_type
  has_many :deal
  has_many :sale
     
  # Automatically create the virtual attribute 'password_confirmation'.
  validates :password, :presence     => true,
                       :confirmation => true,
                       :length       => { :within => 6..40 }

  before_save :encrypt_password

  def has_password?(submitted_password)
    encrypted_password == encrypt(submitted_password)
  end
  
  # public static methods
  
  def self.authenticate(email, submitted_password)
    user = User.find_by_email( email, :include=>:user_type )
    return nil if user.nil?
    return user if user.has_password?(submitted_password)
  end

  def self.authenticate_with_salt(id, cookie_salt)
    user = find_by_id(id)
    (user && user.salt == cookie_salt) ? user : nil
  end

  
  private

    # some encryption shit..
    
    def encrypt_password
      self.salt = make_salt unless has_password?(password)
      self.encrypted_password = encrypt(password)
    end
    
    def encrypt(string)
      secure_hash("#{salt}--#{string}")
    end

    def make_salt
      secure_hash("#{Time.now.utc}--#{password}")
    end

    def secure_hash(string)
      Digest::SHA2.hexdigest(string)
    end
    
end
