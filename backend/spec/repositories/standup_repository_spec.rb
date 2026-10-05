require "rails_helper"

RSpec.describe StandupRepository do
  let(:team) { create(:team) }

  describe ".find_or_initialize_today" do
    it "builds a new standup for the current date" do
      user = create(:user)

      standup = described_class.find_or_initialize_today(team, user)

      expect(standup).to be_new_record
      expect(standup.standup_date).to eq(Date.current)
    end
  end

  describe ".filtered" do
    let(:owner) { team.created_by }
    let!(:member) { create(:user) }

    before do
      create(:team_membership, team: team, user: member)
      create(:standup, :submitted, team: team, user: owner, standup_date: Date.current)
      create(:standup, :draft, team: team, user: member, standup_date: Date.current - 3.days)
    end

    it "filters by status" do
      results = described_class.filtered(team.standups, status: "submitted")

      expect(results.map(&:status).uniq).to eq(["submitted"])
    end

    it "filters by date range" do
      results = described_class.filtered(
        team.standups,
        start_date: Date.current.to_s,
        end_date: Date.current.to_s
      )

      expect(results.count).to eq(1)
    end
  end
end
