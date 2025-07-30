class PowerMonitorJob < ApplicationJob
  queue_as :default
  
  def perform
    Rails.logger.info "PowerMonitorJob started at #{Time.current}"
    
    solarman = SolarmanApi.new
    status_data = solarman.get_grid_status
    
    return unless status_data
    
    # Extract data from the response
    grid_frequency = find_data_by_name(status_data, 'Grid Frequency')
    battery_level = find_data_by_name(status_data, 'SoC')
    solar_production = find_data_by_name(status_data, 'Total DC Input Power')
    consumption = find_data_by_name(status_data, 'Total Consumption Power')
    
    return unless grid_frequency
    
    current_status = grid_frequency['value'].to_f
    latest_record = GridStatus.latest
    
    # Check if status has changed
    grid_changed = status_changed?(current_status, latest_record)
    
    # Always save new data if status is different
    if !latest_record || current_status != latest_record.status
      GridStatus.create!(
        status: current_status,
        battery_level: battery_level&.dig('value')&.to_f || 0,
        production: solar_production&.dig('value')&.to_f || 0,
        consumption: consumption&.dig('value')&.to_f || 0
      )
      
      # Send alert if power status changed
      if grid_changed
        power_on = current_status > 0
        TelegramBot.send_status_alert(
          power_on,
          battery_level&.dig('value')&.to_f || 0,
          solar_production&.dig('value')&.to_f || 0,
          consumption&.dig('value')&.to_f || 0
        )
        
        Rails.logger.info "Power status changed - Power #{power_on ? 'ON' : 'OFF'}"
      end
    end
    
    Rails.logger.info "PowerMonitorJob completed at #{Time.current}"
  rescue => e
    Rails.logger.error "PowerMonitorJob failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
  
  private
  
  def find_data_by_name(data_list, name)
    data_list.find { |item| item['name'] == name }
  end
  
  def status_changed?(current_status, latest_record)
    return false unless latest_record
    
    previous_status = latest_record.status
    
    # Power turned on: was off (0), now on (> 0)
    return true if previous_status == 0 && current_status > 0
    
    # Power turned off: was on (> 0), now off (0)
    return true if previous_status > 0 && current_status == 0
    
    false
  end
end