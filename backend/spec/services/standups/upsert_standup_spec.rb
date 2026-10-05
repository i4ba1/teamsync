require "rails_helper"

RSpec.describe Standups::UpsertStandup do
  let(:user) { create(:user) }
  let(:team) { create(:team, created_by: user) }

  it "creates a draft standup with items" do
    standup = described_class.call(
      team: team,
      user: user,
      attributes: {
        standup_date: Date.current.to_s,
        items: [{ item_type: "today", content: "Ship the refactor", order: 0 }]
      }
    )

    expect(standup).to be_persisted
    expect(standup).to be_status_draft
    expect(standup.standup_items.count).to eq(1)
  end

  it "submits a standup when submit is true" do
    standup = described_class.call(
      team: team,
      user: user,
      attributes: {
        standup_date: Date.current.to_s,
        submit: true,
        items: [{ item_type: "today", content: "Ship the refactor" }]
      }
    )

    expect(standup).to be_status_submitted
    expect(standup.completed_at).to be_present
  end

  it "updates an existing standup" do
    standup = create(:standup, team: team, user: user, standup_date: Date.current)

    described_class.call(
      team: team,
      user: user,
      attributes: { status: "submitted" },
      record: standup
    )

    expect(standup.reload).to be_status_submitted
  end
end
