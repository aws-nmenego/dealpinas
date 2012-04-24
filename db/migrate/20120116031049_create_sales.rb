class CreateSales < ActiveRecord::Migration
  def change
    create_table :sales , :primary_key=>:sales_id do |t|
      t.integer :sales_id
      t.datetime :purchase_date
      t.decimal :total_amount
      t.integer :quantity
      t.string :status
      t.integer :user_id
      
      t.timestamps
    end
  end
  
  def down
    drop_table :sales
  end
end
