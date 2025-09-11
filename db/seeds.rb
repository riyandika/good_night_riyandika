# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

require 'faker'

puts "🌱 Starting seed process..."

# Clear existing data in development
if Rails.env.development?
  puts "🧹 Clearing existing data..."
  Follow.destroy_all
  SleepRecord.destroy_all
  User.destroy_all
  
  # Reset auto-increment
  ActiveRecord::Base.connection.execute("ALTER TABLE users AUTO_INCREMENT = 1")
  ActiveRecord::Base.connection.execute("ALTER TABLE sleep_records AUTO_INCREMENT = 1") 
  ActiveRecord::Base.connection.execute("ALTER TABLE follows AUTO_INCREMENT = 1")
end

# Create 100 users with unique names
puts "👥 Creating 100 users..."
users = []

100.times do |i|
  user = User.create!(
    name: Faker::Name.unique.name
  )
  users << user
  print "." if (i + 1) % 10 == 0
end

puts "\n✅ Created #{users.count} users"

# Create sleep records for each user (10-20 records per user over last 60 days)
puts "😴 Creating sleep records..."
sleep_record_count = 0

users.each_with_index do |user, index|
  num_records = rand(10..20)
  
  num_records.times do
    # Random date within last 60 days
    sleep_date = Faker::Date.between(from: 60.days.ago, to: Date.current)
    
    # Random sleep time between 9 PM and 2 AM
    sleep_hour = rand(21..26) % 24 # 21, 22, 23, 0, 1, 2
    sleep_minute = [0, 15, 30, 45].sample
    sleep_at = sleep_date.beginning_of_day + sleep_hour.hours + sleep_minute.minutes
    
    # Sleep duration between 4-12 hours
    duration_hours = rand(4.0..12.0).round(1)
    wake_up_at = sleep_at + duration_hours.hours
    duration_in_seconds = (duration_hours * 3600).to_i
    
    SleepRecord.create!(
      user: user,
      sleep_at: sleep_at,
      wake_up_at: wake_up_at,
      duration_in_seconds: duration_in_seconds
    )
    
    sleep_record_count += 1
  end
  
  print "." if (index + 1) % 10 == 0
end

puts "\n✅ Created #{sleep_record_count} sleep records"

# Create follow relationships
puts "🤝 Creating follow relationships..."
follow_count = 0

users.each_with_index do |user, index|
  # Each user follows 3-8 random other users
  num_follows = rand(3..8)
  potential_followees = users - [user] # Can't follow yourself
  
  num_follows.times do
    followee = potential_followees.sample
    
    # Avoid duplicate follows
    unless Follow.exists?(follower: user, followee: followee)
      Follow.create!(
        follower: user,
        followee: followee
      )
      follow_count += 1
    end
    
    # Remove from potential list to avoid duplicates
    potential_followees.delete(followee)
    
    # Break if we run out of potential followees
    break if potential_followees.empty?
  end
  
  print "." if (index + 1) % 10 == 0
end

puts "\n✅ Created #{follow_count} follow relationships"

# Summary statistics
puts "\n📊 Seed Summary:"
puts "  Users: #{User.count}"
puts "  Sleep Records: #{SleepRecord.count}"
puts "  Follows: #{Follow.count}"
puts "  Average sleep records per user: #{(SleepRecord.count.to_f / User.count).round(1)}"
puts "  Average follows per user: #{(Follow.count.to_f / User.count).round(1)}"

puts "\n🎉 Seeding completed successfully!"
