class CreateDealLocations < ActiveRecord::Migration
  def change
    create_table :deal_locations , :primary_key=>:location_id do |t|
      t.integer :location_id
      t.string :location_name
      t.decimal :latitude, {:precision=>8,:scale=>5}
      t.decimal :longitude, {:precision=>8,:scale=>5}
      t.integer :deal_id      
      
      t.timestamps
    end
  end

  def down
    drop_table :deal_locations
  end
end
