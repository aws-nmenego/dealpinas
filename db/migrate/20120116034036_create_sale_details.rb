class CreateSaleDetails < ActiveRecord::Migration
  def change
    create_table :sale_details , :primary_key => :sales_id do |t|
      t.integer :sales_id
      t.integer :deal_id

      t.timestamps
    end
  end
  
  def down
    drop_table :sale_details
  end
end
