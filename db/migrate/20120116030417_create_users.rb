class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :email
      t.string :user_name
      t.string :first_name
      t.string :last_name
      t.string :company_name
      t.string :site_url
      t.string :encrypted_password
      t.string :salt
      t.integer :user_type_id

      t.timestamps
    end
  end
  
  def down
    drop_table :users
  end
end
