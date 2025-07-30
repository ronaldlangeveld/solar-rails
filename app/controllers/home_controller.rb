class HomeController < ApplicationController
  def index
    @latest_status = GridStatus.latest_record
    @outages = calculate_outages
    @last_updated = @latest_status&.updated_at
  end

  private

  def calculate_outages
    outages = []
    current_outage = nil
    
    GridStatus.all.order(:created_at).each do |status|
      if status.status == 0 && current_outage.nil?
        current_outage = { start_time: status.created_at, end_time: nil, duration: nil }
      elsif status.status > 0 && current_outage
        current_outage[:end_time] = status.created_at
        current_outage[:duration] = calculate_duration(current_outage[:start_time], current_outage[:end_time])
        outages << current_outage
        current_outage = nil
      end
    end
    
    # Handle ongoing outage
    if current_outage
      current_outage[:end_time] = Time.current
      current_outage[:duration] = calculate_duration(current_outage[:start_time], current_outage[:end_time])
      current_outage[:ongoing] = true
      outages << current_outage
    end
    
    outages
  end

  def calculate_duration(start_time, end_time)
    duration = end_time - start_time
    hours = (duration / 3600).to_i
    minutes = ((duration % 3600) / 60).to_i
    
    if hours > 0
      "#{hours}h #{minutes}m"
    else
      "#{minutes}m"
    end
  end
end