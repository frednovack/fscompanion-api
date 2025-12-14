# Add indexes for better query performance

class AddIndexesToAirports < ActiveRecord::Migration[7.1]
  def change
    add_index :airports, :iata_code
    add_index :airports, :name
    add_index :airports, [:latitude, :longitude]
  end
end
