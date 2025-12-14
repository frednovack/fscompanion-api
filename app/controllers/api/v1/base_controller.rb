module Api
  module V1
    class BaseController < ApplicationController
      before_action :validate_api_key
      
      private
      
      def validate_api_key
        api_key = request.headers['X-API-Key']
        
        unless api_key.present? && api_key == Rails.application.config.api_key
          render json: { error: 'Unauthorized - Invalid or missing API key' }, status: :unauthorized
        end
      end
      
      def render_error(message, status = :bad_request)
        render json: { error: message }, status: status
      end
    end
  end
end
