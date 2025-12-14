require 'csv'

input_file = './airport-codes.csv'
output_file = 'airport-codes-processed.csv'

CSV.open(output_file, 'w') do |csv_out|
  CSV.foreach(input_file, headers: true, liberal_parsing: true).with_index do |row, index|
    # Write header on first row
    if index == 0
      headers = row.headers.dup
      # Remove coordinates column and add latitude and longitude
      headers.delete('coordinates')
      headers << 'latitude'
      headers << 'longitude'
      csv_out << headers
    end
    
    # Split coordinates
    coordinates = row['coordinates']
    if coordinates && !coordinates.strip.empty?
      lat, lon = coordinates.split(',').map(&:strip)
    else
      lat, lon = nil, nil
    end
    
    # Build new row
    new_row = row.to_h.except('coordinates')
    new_row['latitude'] = lat
    new_row['longitude'] = lon
    
    csv_out << new_row.values
  end
end

puts "✅ Processing complete!"
puts "📄 Output saved to: #{output_file}"
