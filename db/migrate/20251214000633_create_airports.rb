class CreateAirports < ActiveRecord::Migration[7.1]
  def change
    create_table :airports do |t|
      t.string :ident
      t.string :airport_type
      t.string :name
      t.decimal :elevation_ft
      t.string :continent
      t.string :iso_country
      t.string :iso_region
      t.string :municipality
      t.string :icao_code
      t.string :gps_code
      t.string :iata_code
      t.string :local_code
      t.decimal :longitude
      t.decimal :latitude

      t.timestamps
    end
    
    add_index :airports, :ident, unique: true
  end
end
