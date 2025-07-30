class SolarmanApi
  include HTTParty
  
  attr_reader :base_url, :app_id, :app_secret, :email, :password, :device_serial
  
  def initialize
    @base_url = Rails.application.credentials.solarman_base_api || ENV['SOLARMAN_BASE_API']
    @app_id = Rails.application.credentials.app_id || ENV['APP_ID']
    @app_secret = Rails.application.credentials.app_secret || ENV['APP_SECRET']
    @email = Rails.application.credentials.email || ENV['EMAIL']
    @password = Rails.application.credentials.password || ENV['PASSWORD']
    @device_serial = Rails.application.credentials.device_serial || ENV['DEVICE_SERIAL']
  end
  
  def get_grid_status
    access_token = get_access_token
    return nil unless access_token
    
    url = "https://#{base_url}/device/v1.0/currentData"
    headers = {
      'Content-Type' => 'application/json',
      'authorization' => "bearer #{access_token}"
    }
    body = {
      deviceSn: device_serial
    }
    
    response = HTTParty.post(url, {
      headers: headers,
      body: body.to_json,
      query: { appId: app_id, language: 'en' }
    })
    
    if response.success?
      response['dataList']
    else
      Rails.logger.error "Solarman API error: #{response.code} - #{response.message}"
      nil
    end
  rescue => e
    Rails.logger.error "Solarman API exception: #{e.message}"
    nil
  end
  
  private
  
  def get_access_token
    latest_token = Token.latest_record
    
    if latest_token&.token_valid?
      return latest_token.access
    end
    
    fetch_new_token
  end
  
  def fetch_new_token
    url = "https://#{base_url}/account/v1.0/token"
    headers = { 'Content-Type' => 'application/json' }
    body = {
      appSecret: app_secret,
      email: email,
      password: password
    }
    
    response = HTTParty.post(url, {
      headers: headers,
      body: body.to_json,
      query: { appId: app_id, language: 'en' }
    })
    
    if response.success?
      data = response.parsed_response
      expires_in = (data['expires_in'] * 1000) + (Time.current.to_i * 1000)
      
      Token.create!(
        access: data['access_token'],
        refresh: data['refresh_token'],
        expires: expires_in
      )
      
      data['access_token']
    else
      Rails.logger.error "Token fetch error: #{response.code} - #{response.message}"
      nil
    end
  rescue => e
    Rails.logger.error "Token fetch exception: #{e.message}"
    nil
  end
end