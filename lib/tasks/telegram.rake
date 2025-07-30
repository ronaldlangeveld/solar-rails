namespace :telegram do
  desc "Start Telegram bot webhook listener"
  task listen: :environment do
    puts "Starting Telegram bot listener..."
    
    bot_commands = TelegramBotCommands.new
    bot_commands.setup_webhook
  rescue Interrupt
    puts "\nTelegram bot listener stopped."
  rescue => e
    puts "Error starting Telegram bot: #{e.message}"
    Rails.logger.error "Telegram bot error: #{e.message}"
  end
  
  desc "Test Telegram bot connection"
  task test: :environment do
    begin
      puts "Testing Telegram bot connection..."
      puts "Token: #{ENV['TELEGRAM_TOKEN'] ? 'Present' : 'Missing'}"
      puts "Recipient ID: #{ENV['RECIPIENT_ID'] ? 'Present' : 'Missing'}"
      
      bot = TelegramBot.new
      result = bot.send_message("🤖 Telegram bot connection test successful!")
      
      if result
        puts "✅ Telegram bot test successful!"
      else
        puts "❌ Telegram bot test failed!"
      end
    rescue => e
      puts "❌ Telegram bot test failed with error: #{e.message}"
      puts "Error class: #{e.class}"
      puts e.backtrace.first(5).join("\n")
    end
  end
end