class CreateCategories < ActiveRecord::Migration
  def change
    create_table :categories , :primary_key=>:category_id do |t|
      t.integer :category_id
      t.string :category_name
      t.string :code
      t.string :icon_image
      t.string :description

      t.timestamps
    end
  end
  
  def down 
    drop_table :categories
  end
end
