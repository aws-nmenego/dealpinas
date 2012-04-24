class CreateDealCategoryMappings < ActiveRecord::Migration
  def up
    create_table :deal_category_mappings do |t|
      t.integer :deal_id
      t.integer :category_id
      
      t.timestamps
    end
  end

  def down
    drop_table :deal_category_mappings
  end
end
