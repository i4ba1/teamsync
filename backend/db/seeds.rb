# This file should ensure the existence of records required to run the application in every environment.
# The data can then be loaded with the bin/rails db:seed command.

puts "Creating seed data..."

# Create admin user
admin = User.find_or_create_by!(email: "admin@teamsync.app") do |user|
  user.password = "password123"
  user.first_name = "Admin"
  user.last_name = "User"
  user.timezone = "UTC"
  user.status = :active
  user.role = :super_admin
end
puts "Created admin user: #{admin.email}"

# Create demo team
team = Team.find_or_create_by!(slug: "demo-team") do |t|
  t.name = "Demo Team"
  t.timezone = "UTC"
  t.standup_time = "09:00"
  t.standup_days = [1, 2, 3, 4, 5]
  t.created_by = admin
  t.settings = {
    reminder_enabled: true,
    reminder_minutes_before: 30,
    allow_weekend_standups: false
  }
end
puts "Created demo team: #{team.name}"

# Create team membership for admin
TeamMembership.find_or_create_by!(team: team, user: admin) do |membership|
  membership.role = :owner
  membership.joined_at = Time.current
end

# Create additional demo users
demo_users = [
  { email: "john@example.com", first_name: "John", last_name: "Doe", timezone: "America/New_York" },
  { email: "jane@example.com", first_name: "Jane", last_name: "Smith", timezone: "Europe/London" },
  { email: "bob@example.com", first_name: "Bob", last_name: "Wilson", timezone: "Asia/Tokyo" }
]

demo_users.each do |user_data|
  user = User.find_or_create_by!(email: user_data[:email]) do |u|
    u.password = "password123"
    u.first_name = user_data[:first_name]
    u.last_name = user_data[:last_name]
    u.timezone = user_data[:timezone]
    u.status = :active
    u.role = :member
  end
  
  TeamMembership.find_or_create_by!(team: team, user: user) do |membership|
    membership.role = :member
    membership.joined_at = Time.current
  end
  
  puts "Created user: #{user.email}"
end

puts "Seed data created successfully!"
