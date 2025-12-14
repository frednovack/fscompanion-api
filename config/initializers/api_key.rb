# config/initializers/api_key.rb
# Generate a secure API key for your iOS app
# You can regenerate this with: SecureRandom.hex(32)

Rails.application.config.api_key = ENV.fetch('API_KEY', 'your_secure_api_key_here_change_in_production')
