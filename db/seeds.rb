# This file should ensure the development environment is seeded safely
# 
# The seeds are duplicate-safe and can be run multiple times
#
# Usage:
#   rails db:seed                    # Run this file
#   rails data:migrate_from_old_db   # Migrate from old JavaScript database
#   rails data:export_to_seeds       # Export current data to seeds file

puts "🌱 Running seeds..."

# Load seeds from migration if the file exists
migration_seeds_path = Rails.root.join('db', 'seeds_from_migration.rb')
if File.exist?(migration_seeds_path)
  puts "📦 Loading seeds from migration file..."
  load migration_seeds_path
else
  puts "ℹ️ No migration seeds file found. Run 'rails data:migrate_from_old_db' first if you have old data to import."
end

puts "✅ Seeds completed!"
