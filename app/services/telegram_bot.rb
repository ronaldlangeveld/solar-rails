require 'telegram/bot'

class TelegramBot
  attr_reader :bot, :recipient_id
  
  def initialize
    @bot = Telegram::Bot::Client.new(Rails.application.credentials.telegram_token || ENV['TELEGRAM_TOKEN'])
    @recipient_id = Rails.application.credentials.recipient_id || ENV['RECIPIENT_ID']
  end
  
  def send_message(message, chat_id = nil)
    target_id = chat_id || recipient_id
    bot.api.send_message(
      chat_id: target_id,
      text: message,
      parse_mode: 'HTML'
    )
  rescue => e
    Rails.logger.error "Telegram bot error: #{e.message}"
    false
  end
  
  def format_status_message(power_on, battery_level, solar_production, consumption)
    status_emoji = power_on ? "⚡️ POWER IS ON" : "🚨 POWER IS OFF"
    
    <<~MESSAGE
      #{status_emoji}

      🔋 at #{battery_level}%

      ☀️ Producing #{(solar_production / 1000.0).round(2)} kW

      🏡 Current Consumption #{(consumption / 1000.0).round(2)} kW
    MESSAGE
  end
  
  def self.send_status_alert(power_on, battery_level, solar_production, consumption)
    bot = new
    message = bot.format_status_message(power_on, battery_level, solar_production, consumption)
    bot.send_message(message)
  end
end