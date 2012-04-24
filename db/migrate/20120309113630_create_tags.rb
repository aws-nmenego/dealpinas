class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.integer :id
      t.integer :category_id
      t.string :tag, :unique => true

      t.timestamps
    end
  end
  
  def down
    drop_table :tags
  end
end
