# Solar Robot Rails

A Ruby on Rails application for monitoring solar power systems and sending alerts via Telegram when power status changes.

## Features

- 🔌 **Power Monitoring**: Tracks grid frequency to detect power outages and restoration
- 🔋 **Battery Monitoring**: Monitors battery level, solar production, and power consumption
- 📱 **Telegram Alerts**: Sends notifications when power status changes
- 📊 **Data Storage**: Stores historical data for analysis
- 🤖 **Bot Commands**: Interactive Telegram commands for manual status checks

## Setup

### Prerequisites

- Ruby 3.3+
- Rails 8.0+
- SQLite3

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   bundle install
   ```

3. Set up the database:
   ```bash
   rails db:migrate
   ```

4. Configure your credentials (choose one approach):

   **Option A: Rails Credentials (Recommended for production)**
   ```bash
   rails credentials:edit
   ```
   Add your credentials:
   ```yaml
   solarman_base_api: your_solarman_api_base_url
   app_id: your_app_id
   app_secret: your_app_secret
   email: your_solarman_email
   password: your_solarman_password
   device_serial: your_device_serial_number
   telegram_token: your_telegram_bot_token
   recipient_id: your_telegram_chat_id
   ```

   **Option B: Environment Variables (Development/Testing)**
   ```bash
   cp .env.example .env
   ```
   Then edit `.env` with your values. The `dotenv-rails` gem will load these automatically.

### Running the Application

1. Start the Rails server:
   ```bash
   rails server
   ```

2. Start the job queue (in another terminal):
   ```bash
   bundle exec solid_queue start
   ```

3. (Optional) Start the Telegram bot listener:
   ```bash
   rails telegram:listen
   ```

### Telegram Bot Commands

- `/now` - Get current solar system status
- `/debug` - Get raw debug data from the API
- `/outages` - View power outage statistics
- `/start` - Show available commands

### Testing

Test the Telegram bot connection:
```bash
rails telegram:test
```

## Architecture

- **PowerMonitorJob**: Runs every 4 minutes to check solar system status
- **SolarmanApi**: Service for fetching data from Solarman API
- **TelegramBot**: Service for sending notifications
- **TelegramBotCommands**: Handles interactive bot commands
- **GridStatus**: Model for storing power status data
- **Token**: Model for managing API authentication tokens

## Deployment

The application uses Kamal for deployment. Configure your deployment settings and run:
```bash
kamal deploy
```
