class SolarmanApi
  include HTTParty

  attr_reader :base_url, :app_id, :app_secret, :email, :password, :device_serial

  def initialize
    @base_url = Rails.application.credentials.solarman_base_api || ENV["SOLARMAN_BASE_API"]
    @app_id = Rails.application.credentials.app_id || ENV["APP_ID"]
    @app_secret = Rails.application.credentials.app_secret || ENV["APP_SECRET"]
    @email = Rails.application.credentials.email || ENV["EMAIL"]
    @password = Rails.application.credentials.password || ENV["PASSWORD"]
    @device_serial = Rails.application.credentials.device_serial || ENV["DEVICE_SERIAL"]
  end

  def get_grid_status
    Rails.logger.info "[SolarmanApi] get_grid_status called"
    Rails.logger.info "[SolarmanApi] base_url=#{base_url.present? ? 'set' : 'MISSING'}, app_id=#{app_id.present? ? 'set' : 'MISSING'}, device_serial=#{device_serial.present? ? 'set' : 'MISSING'}"

    access_token = get_access_token
    Rails.logger.info "[SolarmanApi] access_token=#{access_token.present? ? 'obtained' : 'FAILED'}"
    return nil unless access_token

    response = fetch_grid_data(access_token)

    # If we get a 401 (unauthorized), the token might be invalid even though we thought it was valid
    # Try to force a new token and retry once
    if response&.code == 401
      Rails.logger.warn "Received 401 from Solarman API, forcing token refresh"
      invalidate_current_token
      access_token = get_access_token
      return nil unless access_token
      response = fetch_grid_data(access_token)
    elsif response && !response.success?
      # Handle other non-success statuses by forcing a fresh token once
      Rails.logger.warn "Solarman API non-success #{response.code} - #{response.message}, retrying with new token"
      invalidate_current_token
      access_token = fetch_new_token
      return nil unless access_token
      response = fetch_grid_data(access_token)
    end

    if response&.success?
      data = response["dataList"]
      if data.nil?
        Rails.logger.error "Solarman API response missing dataList: #{response.parsed_response}"
        return nil
      end
      data
    elsif response.nil?
      Rails.logger.error "Solarman API error: response was nil"
      nil
    else
      Rails.logger.error "Solarman API error: #{response&.code} - #{response&.message}; body: #{response&.parsed_response}"
      nil
    end
  rescue => e
    Rails.logger.error "Solarman API exception: #{e.message}"
    nil
  end

  private

  def fetch_grid_data(access_token)
    url = "https://#{base_url}/device/v1.0/currentData"
    headers = {
      "Content-Type" => "application/json",
      "authorization" => "bearer #{access_token}"
    }
    body = {
      deviceSn: device_serial
    }

    HTTParty.post(url, {
      headers: headers,
      body: body.to_json,
      query: { appId: app_id, language: "en" }
    })
  rescue => e
    Rails.logger.error "Solarman API fetch_grid_data exception: #{e.message}"
    nil
  end

  def invalidate_current_token
    latest_token = Token.latest_record
    latest_token&.update(expires: 0)
  end

  def get_access_token
    latest_token = Token.latest_record
    Rails.logger.info "[SolarmanApi] get_access_token: latest_token exists=#{latest_token.present?}, valid=#{latest_token&.token_valid?}"

    if latest_token&.token_valid?
      Rails.logger.info "[SolarmanApi] Using existing valid token"
      return latest_token.access
    end

    # Try to refresh the token if we have a refresh token
    if latest_token&.refresh.present?
      Rails.logger.info "[SolarmanApi] Attempting token refresh"
      refreshed_token = refresh_access_token(latest_token.refresh)
      return refreshed_token if refreshed_token
    end

    # Fall back to fetching a completely new token
    Rails.logger.info "[SolarmanApi] Fetching brand new token"
    fetch_new_token
  end

  def refresh_access_token(refresh_token)
    url = "https://#{base_url}/account/v1.0/token"
    headers = { "Content-Type" => "application/json" }
    body = {
      grant_type: "refresh_token",
      refresh_token: refresh_token
    }

    response = HTTParty.post(url, {
      headers: headers,
      body: body.to_json,
      query: { appId: app_id, language: "en" }
    })

    Rails.logger.info "[SolarmanApi] refresh_access_token response: #{response.code} - #{response.parsed_response}"

    if response.success?
      data = response.parsed_response
      expires_in = (data["expires_in"].to_i * 1000) + (Time.current.to_i * 1000)

      Token.create!(
        access: data["access_token"],
        refresh: data["refresh_token"] || refresh_token,
        expires: expires_in
      )

      Rails.logger.info "Successfully refreshed Solarman API token"
      data["access_token"]
    else
      Rails.logger.warn "Token refresh failed: #{response.code} - #{response.message}, will try fetching new token"
      nil
    end
  rescue => e
    Rails.logger.warn "Token refresh exception: #{e.message}, will try fetching new token"
    nil
  end

  def fetch_new_token
    url = "https://#{base_url}/account/v1.0/token"
    headers = { "Content-Type" => "application/json" }

    body = {
      appSecret: app_secret,
      email: email,
      password: password
    }

    Rails.logger.info "[SolarmanApi] fetch_new_token: email=#{email.present? ? 'set' : 'MISSING'}, password=#{password.present? ? 'set' : 'MISSING'}, app_secret=#{app_secret.present? ? 'set' : 'MISSING'}"

    response = HTTParty.post(url, {
      headers: headers,
      body: body.to_json,
      query: { appId: app_id, language: "en" }
    })

    Rails.logger.info "[SolarmanApi] fetch_new_token response: #{response.code} - #{response.parsed_response}"

    data = response.parsed_response

    # Solarman returns HTTP 200 even on auth failure, so check the body's success field
    if response.success? && data["success"] != false && data["access_token"].present?
      expires_in = (data["expires_in"].to_i * 1000) + (Time.current.to_i * 1000)

      Token.create!(
        access: data["access_token"],
        refresh: data["refresh_token"],
        expires: expires_in
      )

      data["access_token"]
    else
      Rails.logger.error "[SolarmanApi] Token fetch error: #{response.code} - #{data['msg'] || response.message} - #{data}"
      nil
    end
  rescue => e
    Rails.logger.error "[SolarmanApi] Token fetch exception: #{e.message}"
    nil
  end
end
