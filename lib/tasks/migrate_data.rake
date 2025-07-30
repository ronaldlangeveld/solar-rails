require 'sqlite3'

namespace :data do
  desc "Migrate data from old JavaScript app SQLite database"
  task migrate_from_old_db: :environment do
    old_db_path = Rails.root.join('db', 'backedup.sqlite3')
    
    unless File.exist?(old_db_path)
      puts "❌ Database file not found at: #{old_db_path}"
      exit 1
    end
    
    puts "🚀 Starting data migration from old database..."
    puts "📁 Source: #{old_db_path}"
    
    begin
      old_db = SQLite3::Database.new(old_db_path.to_s)
      old_db.results_as_hash = true
      
      migrate_grid_statuses(old_db)
      # Skip token migration as requested
      puts "\n🔑 Skipping token migration (not needed)"
      
      old_db.close
      puts "✅ Data migration completed successfully!"
      
    rescue => e
      puts "❌ Migration failed: #{e.message}"
      puts e.backtrace.first(5).join("\n")
    end
  end
  
  private
  
  def migrate_grid_statuses(old_db)
    puts "\n📊 Migrating grid status data..."
    
    # Get all records from old database
    old_records = old_db.execute("SELECT * FROM grid_status ORDER BY id")
    
    migrated_count = 0
    skipped_count = 0
    
    old_records.each do |record|
      # Convert timestamp from JavaScript epoch to Ruby Time
      timestamp = if record['timestamp'].is_a?(String)
                    Time.parse(record['timestamp'])
                  else
                    # JavaScript timestamp (milliseconds) to Ruby Time
                    Time.at(record['timestamp'] / 1000.0)
                  end
      
      # Check if record already exists (avoid duplicates)
      existing = GridStatus.find_by(
        status: record['status'],
        created_at: timestamp..timestamp + 1.second # Small time window for matching
      )
      
      if existing
        skipped_count += 1
        next
      end
      
      # Create new record
      GridStatus.create!(
        status: record['status'] || 0,
        battery_level: record['battery_level'] || 0,
        production: record['production'] || 0,
        consumption: record['consumption'] || 0,
        created_at: timestamp,
        updated_at: timestamp
      )
      
      migrated_count += 1
      
      # Progress indicator
      print "." if migrated_count % 100 == 0
    end
    
    puts "\n✅ Grid status migration complete:"
    puts "   📥 Migrated: #{migrated_count} records"
    puts "   ⏭️  Skipped: #{skipped_count} duplicates"
  end
  
  def migrate_tokens(old_db)
    puts "\n🔑 Migrating token data..."
    
    # Get all tokens from old database
    old_tokens = old_db.execute("SELECT * FROM tokens ORDER BY id")
    
    migrated_count = 0
    skipped_count = 0
    
    old_tokens.each do |record|
      # Check if token already exists (avoid duplicates)
      existing = Token.find_by(access: record['access'])
      
      if existing
        skipped_count += 1
        next
      end
      
      # Convert expires timestamp
      expires_time = if record['expires'].is_a?(String)
                       Time.parse(record['expires'])
                     else
                       # JavaScript timestamp to Unix timestamp for Rails
                       record['expires']
                     end
      
      Token.create!(
        access: record['access'],
        refresh: record['refresh'],
        expires: expires_time
      )
      
      migrated_count += 1
    end
    
    puts "✅ Token migration complete:"
    puts "   📥 Migrated: #{migrated_count} tokens"
    puts "   ⏭️  Skipped: #{skipped_count} duplicates"
  end
end