class CreateDeals < ActiveRecord::Migration
  def up
    create_table :deals , :primary_key=>:deal_id do |t|
      t.integer :deal_id
      t.string :title
      t.text :description
      t.datetime :expiry
      t.integer :no_of_items_sold
      t.integer :quantity
      t.decimal :original_price, {:precision=>16,:scale=>8, :default => 0, :null => false} 
      t.decimal :price , {:precision=>16,:scale=>8, :null => false, :default => 0}
      t.string :discount
      t.string :deal_url
      t.string :deal_thumb
      t.string :rss_deal_id
      t.integer :category_id
      t.string :author
      t.string :merchant_name
      t.string :contact_name
      t.string :contact_number
      t.string :contact_email
      t.string :contact_address
      t.string :contact_url

      t.boolean :is_ad, {:null => false, :default => false}
      t.string :promo
      t.boolean :support_print
      t.string :permit
      t.datetime :display_until

      t.string :status , {:default=>'' , :null=>false}

      t.boolean :reviewed      

      t.timestamps
    end
    
  end
  
  def down
    drop_table :deals
  end
end
