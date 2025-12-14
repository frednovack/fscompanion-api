module Api
  module V1
    class AirportsController < BaseController
      # POST /api/v1/airports/nearby
      # Params: { latitude: float, longitude: float, radius: float (in km) }
      def nearby
        lat = params[:latitude]&.to_f
        lon = params[:longitude]&.to_f
        radius = params[:radius]&.to_f || 50 # Default 50km
        
        # Validation
        if lat.nil? || lon.nil?
          return render_error('Missing latitude or longitude')
        end
        
        unless lat.between?(-90, 90) && lon.between?(-180, 180)
          return render_error('Invalid coordinates')
        end
        
        unless radius.between?(1, 500) # Max 500km radius
          return render_error('Radius must be between 1 and 500 km')
        end
        
        # Find nearby airports
        airports = Airport.nearby(lat, lon, radius)
        
        render json: {
          count: airports.length,
          radius_km: radius,
          center: { latitude: lat, longitude: lon },
          airports: airports.map { |airport| serialize_airport(airport) }
        }
      end
      
      # GET /api/v1/airports/search?q=query
      def search
        query = params[:q]
        
        if query.blank?
          return render_error('Missing search query parameter (q)')
        end
        
        airports = Airport.search(query).limit(50)
        
        render json: {
          count: airports.length,
          query: query,
          airports: airports.map { |airport| serialize_airport(airport) }
        }
      end
      
      private
      
      def serialize_airport(airport)
        {
          id: airport.id,
          ident: airport.ident,
          type: airport.airport_type,
          name: airport.name,
          elevation_ft: airport.elevation_ft,
          continent: airport.continent,
          iso_country: airport.iso_country,
          iso_region: airport.iso_region,
          municipality: airport.municipality,
          gps_code: airport.gps_code,
          iata_code: airport.iata_code,
          local_code: airport.local_code,
          latitude: airport.latitude,
          longitude: airport.longitude,
          distance_km: airport.try(:distance)&.round(2)
        }.compact
      end
    end
  end
end
