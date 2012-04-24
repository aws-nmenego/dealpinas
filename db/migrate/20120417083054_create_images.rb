class CreateImages < ActiveRecord::Migration
  def change
    create_table :images do |t|
      t.integer :deal_id
      t.string :url
      t.string :description

      t.timestamps
    end
  end
end
