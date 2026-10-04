# Seeds idempotent demo data for local development and screenshots.
# Run with: bin/rails db:seed

puts "Seeding TeamSync demo data..."

PASSWORD = "password123"

def upsert_user(email, first_name, last_name, timezone, role)
  user = User.find_or_initialize_by(email: email)
  user.assign_attributes(
    first_name: first_name,
    last_name: last_name,
    timezone: timezone,
    status: :active,
    role: role
  )
  user.password = PASSWORD if user.new_record? || !user.authenticate(PASSWORD)
  user.save!
  user
end

def upsert_membership(team, user, role)
  membership = TeamMembership.find_or_initialize_by(team: team, user: user)
  membership.role = role
  membership.joined_at ||= Time.current
  membership.save!
  membership
end

admin = upsert_user("admin@teamsync.app", "Admin", "User", "UTC", :super_admin)

team = Team.find_or_initialize_by(slug: "demo-team")
team.assign_attributes(
  name: "Demo Team",
  timezone: "UTC",
  standup_time: "09:00",
  standup_days: [1, 2, 3, 4, 5],
  created_by: admin,
  settings: {
    reminder_enabled: true,
    reminder_minutes_before: 30,
    allow_weekend_standups: false
  }
)
team.save!

upsert_membership(team, admin, :owner)

member_data = [
  { email: "grace@teamsync.app", first_name: "Grace", last_name: "Hopper", timezone: "America/New_York", role: :admin },
  { email: "alan@teamsync.app", first_name: "Alan", last_name: "Turing", timezone: "Europe/London", role: :member },
  { email: "ada@teamsync.app", first_name: "Ada", last_name: "Lovelace", timezone: "Europe/London", role: :member },
  { email: "margaret@teamsync.app", first_name: "Margaret", last_name: "Hamilton", timezone: "Asia/Jakarta", role: :member },
  { email: "linus@teamsync.app", first_name: "Linus", last_name: "Torvalds", timezone: "Asia/Tokyo", role: :member }
]

members = member_data.map do |data|
  user = upsert_user(data[:email], data[:first_name], data[:last_name], data[:timezone], data[:role])
  upsert_membership(team, user, data[:role])
  user
end

team_members = [admin, *members]

yesterday_samples = [
  "Shipped the billing refactor and merged the PR",
  "Reviewed two pull requests and unblocked the team",
  "Fixed the flaky integration test",
  "Wrote the database migration for invite codes",
  "Paired with Grace on the API serializer"
]
today_samples = [
  "Start the standup history filters",
  "Design the team invite flow",
  "Harden the JSON:API serializer output",
  "Draft the release notes for v1.2",
  "Refactor the notification repository"
]
blocker_samples = [
  "Waiting on staging access",
  "",
  "Need a design review before continuing",
  "",
  "Blocked by an upstream outage"
]

standup_days = (0..20)
  .map { |offset| Date.current - offset }
  .select { |date| team.standup_days.include?(date.wday) }
  .first(10)

standup_days.each_with_index do |date, day_index|
  team_members.each_with_index do |member, member_index|
    seed = day_index + member_index

    status = seed % 9 == 0 ? :missed : :submitted
    status = :draft if date == Date.current && member == members.first

    standup = Standup.find_or_initialize_by(team: team, user: member, standup_date: date)
    standup.status = status
    standup.completed_at = status == :submitted ? date.to_time.change(hour: 9) : nil
    standup.save!

    standup.standup_items.destroy_all
    StandupItem.create!(
      standup: standup, item_type: :yesterday, content: yesterday_samples[seed % 5], sort_order: 0
    )
    StandupItem.create!(
      standup: standup, item_type: :today, content: today_samples[seed % 5], sort_order: 0
    )

    blocker = blocker_samples[seed % 5]
    if blocker.present?
      StandupItem.create!(standup: standup, item_type: :blockers, content: blocker, sort_order: 0)
    end
  end
end

puts "Seeded #{team.members.count} members and #{team.standups.count} standups for '#{team.name}'."
puts "Login with #{admin.email} / #{PASSWORD}"
