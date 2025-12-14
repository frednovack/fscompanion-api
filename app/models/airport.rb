class Airport < ApplicationRecord
  validates :ident, presence: true, uniqueness: true
  
  # Search airports by ident, iata_code, or name
  def self.search(query)
    sanitized_query = sanitize_sql_like(query)
    
    # Priority order: exact ident/iata match, then partial name match
    where("ident ILIKE ? OR iata_code ILIKE ? OR name ILIKE ?", 
          "#{sanitized_query}%", 
          "#{sanitized_query}%", 
          "%#{sanitized_query}%")
      .order(Arel.sql("
        CASE 
          WHEN ident ILIKE '#{sanitized_query}' THEN 1
          WHEN iata_code ILIKE '#{sanitized_query}' THEN 2
          WHEN ident ILIKE '#{sanitized_query}%' THEN 3
          WHEN iata_code ILIKE '#{sanitized_query}%' THEN 4
          ELSE 5
        END
      "))
  end
  
  # Find airports within a radius (in km) from given coordinates
  def self.nearby(lat, lon, radius_km)
    # Approximate bounding box to reduce dataset before calculating exact distance
    # 1 degree ≈ 111km
    lat_delta = radius_km / 111.0
    lon_delta = radius_km / (111.0 * Math.cos(lat * Math::PI / 180))
    
    airports = where(
      "latitude BETWEEN ? AND ? AND longitude BETWEEN ? AND ?",
      lat - lat_delta, lat + lat_delta,
      lon - lon_delta, lon + lon_delta
    ).to_a
    
    # Calculate exact distance and filter
    airports_with_distance = airports.map do |airport|
      next unless airport.latitude && airport.longitude
      
      distance = haversine_distance(lat, lon, airport.latitude.to_f, airport.longitude.to_f)
      
      if distance <= radius_km
        airport.define_singleton_method(:distance) { distance }
        airport
      end
    end.compact
    
    # Sort by distance
    airports_with_distance.sort_by(&:distance)
  end
  
  # Haversine formula to calculate distance between two points on Earth
  # Returns distance in kilometers
  def self.haversine_distance(lat1, lon1, lat2, lon2)
    earth_radius_km = 6371.0
    
    d_lat = to_radians(lat2 - lat1)
    d_lon = to_radians(lon2 - lon1)
    
    a = Math.sin(d_lat / 2) ** 2 +
        Math.cos(to_radians(lat1)) * Math.cos(to_radians(lat2)) *
        Math.sin(d_lon / 2) ** 2
    
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    
    earth_radius_km * c
  end
  
  def self.to_radians(degrees)
    degrees * Math::PI / 180
  end
end
