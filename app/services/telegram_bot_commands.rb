require "telegram/bot"

class TelegramBotCommands
  attr_reader :bot

  def initialize
    @bot = Telegram::Bot::Client.new(Rails.application.credentials.telegram_token || ENV["TELEGRAM_TOKEN"])
  end

  def setup_webhook
    bot.listen do |message|
      case message.text
      when "/now"
        handle_now_command(message)
      when "/debug"
        handle_debug_command(message)
      when "/outages"
        handle_outages_command(message)
      when "/start"
        handle_start_command(message)
      end
    end
  end

  private

  def handle_now_command(message)
    Rails.logger.info "[TelegramBot] /now received from chat #{message.chat.id}"

    solarman = SolarmanApi.new
    status_data = solarman.get_grid_status

    if status_data
      Rails.logger.info "[TelegramBot] /now fetched #{status_data.length} data points"
      grid_frequency = find_data_by_name(status_data, "Grid Frequency")
      battery_level = find_data_by_name(status_data, "SoC")
      solar_production = find_data_by_name(status_data, "Total DC Input Power")
      consumption = find_data_by_name(status_data, "Total Consumption Power")

      power_on = grid_frequency&.dig("value")&.to_f&.> 0
      telegram_bot = TelegramBot.new

      response = telegram_bot.format_status_message(
        power_on,
        battery_level&.dig("value")&.to_f || 0,
        solar_production&.dig("value")&.to_f || 0,
        consumption&.dig("value")&.to_f || 0
      )
    else
      Rails.logger.warn "[TelegramBot] /now failed to fetch data"
      response = "❌ Unable to fetch current data from solar system"
    end

    bot.api.send_message(
      chat_id: message.chat.id,
      text: response,
      parse_mode: "HTML"
    )
  end

  def handle_debug_command(message)
    solarman = SolarmanApi.new
    status_data = solarman.get_grid_status

    response = if status_data
      status_data.to_json
    else
      "❌ Unable to fetch debug data"
    end

    bot.api.send_message(
      chat_id: message.chat.id,
      text: response
    )
  end

  def handle_outages_command(message)
    outages = GridStatus.outages.order(:created_at)
    outage_count = outages.count

    response = if outage_count > 0
      last_outage = outages.last
      "📊 #{outage_count} outages since #{last_outage.created_at.to_s(:long)}"
    else
      "✅ No power outages recorded"
    end

    bot.api.send_message(
      chat_id: message.chat.id,
      text: response
    )
  end

  def handle_start_command(message)
    response = <<~TEXT
      🌞 Solar Robot is online!

      Available commands:
      /now - Get current solar system status
      /debug - Get raw debug data
      /outages - View outage statistics

      I'll automatically notify you when power status changes.
    TEXT

    bot.api.send_message(
      chat_id: message.chat.id,
      text: response
    )
  end

  def find_data_by_name(data_list, name)
    data_list.find { |item| item["name"] == name }
  end
end
