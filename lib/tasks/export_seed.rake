namespace :data do
  desc "Export current data to seeds file for deployment"
  task export_to_seeds: :environment do
    seed_file_path = Rails.root.join('db', 'seeds_from_migration.rb')
    
    puts "📦 Exporting data to seeds file..."
    puts "📁 Output: #{seed_file_path}"
    
    File.open(seed_file_path, 'w') do |file|
      file.puts "# Seeds generated from data migration"
      file.puts "# Generated at: #{Time.current}"
      file.puts "# Run with: rails db:seed"
      file.puts ""
      file.puts "puts '🌱 Seeding data from migration...'"
      file.puts ""
      
      # Export GridStatus records only
      export_grid_statuses(file)
      
      file.puts ""
      file.puts "puts '✅ Seeding completed!'"
    end
    
    puts "✅ Seeds file created successfully!"
    puts "📝 To use on live server:"
    puts "   1. Copy db/seeds_from_migration.rb to your live server"
    puts "   2. Run: rails db:seed"
  end
  
  private
  
  def export_grid_statuses(file)
    file.puts "# Grid Status Records"
    file.puts "puts '📊 Creating grid status records...'"
    file.puts ""
    
    total_records = GridStatus.count
    batch_size = 1000
    processed_count = 0
    
    puts "📋 Exporting #{total_records} grid status records..."
    
    GridStatus.find_in_batches(batch_size: batch_size) do |batch|
      processed_count += batch.size
      percentage = (processed_count.to_f / total_records * 100).round(1)
      puts "\r📊 Export Progress: #{processed_count}/#{total_records} (#{percentage}%)"
      file.puts "GridStatus.insert_all(["
      
      batch.each_with_index do |record, index|
        comma = index == batch.size - 1 ? '' : ','
        
        file.puts "  {"
        file.puts "    status: #{record.status},"
        file.puts "    battery_level: #{record.battery_level},"
        file.puts "    production: #{record.production},"
        file.puts "    consumption: #{record.consumption},"
        file.puts "    created_at: Time.parse('#{record.created_at.iso8601}'),"
        file.puts "    updated_at: Time.parse('#{record.updated_at.iso8601}')"
        file.puts "  }#{comma}"
      end
      
      file.puts "], unique_by: [:status, :created_at])"
      file.puts ""
    end
    
    file.puts "puts '  ✅ #{total_records} grid status records processed'"
    file.puts ""
  end
  
end