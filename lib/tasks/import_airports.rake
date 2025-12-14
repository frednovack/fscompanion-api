require 'csv'

namespace :airports do
  desc "Import airports from CSV file"
  task import: :environment do
    csv_file = Rails.root.join('airport-codes-processed.csv')
    
    unless File.exist?(csv_file)
      puts "❌ Error: #{csv_file} not found!"
      puts "Please make sure the CSV file exists in the project root."
      exit
    end
    
    puts "📂 Reading CSV file: #{csv_file}"
    
    imported_count = 0
    skipped_count = 0
    error_count = 0
    
    CSV.foreach(csv_file, headers: true, liberal_parsing: true) do |row|
      begin
        # Skip if ident is blank
        if row['ident'].blank?
          skipped_count += 1
          next
        end
        
        airport = Airport.find_or_initialize_by(ident: row['ident'])
        
        airport.assign_attributes(
          airport_type: row['type'],
          name: row['name'],
          elevation_ft: row['elevation_ft'],
          continent: row['continent'],
          iso_country: row['iso_country'],
          iso_region: row['iso_region'],
          municipality: row['municipality'],
          gps_code: row['gps_code'],
          iata_code: row['iata_code'],
          local_code: row['local_code'],
          longitude: row['longitude'],
          latitude: row['latitude']
        )
        
        if airport.save
          imported_count += 1
          print "\r✅ Imported: #{imported_count} | Skipped: #{skipped_count} | Errors: #{error_count}"
        else
          error_count += 1
          puts "\n⚠️  Error saving airport #{row['ident']}: #{airport.errors.full_messages.join(', ')}"
        end
        
      rescue => e
        error_count += 1
        puts "\n❌ Error processing row: #{e.message}"
      end
    end
    
    puts "\n"
    puts "="*50
    puts "✅ Import complete!"
    puts "   Imported: #{imported_count}"
    puts "   Skipped: #{skipped_count}"
    puts "   Errors: #{error_count}"
    puts "="*50
  end
end
