require "rails_helper"

RSpec.describe Teams::CreateTeam do
  let(:user) { create(:user) }
  let(:attributes) do
    { name: "Platform Team", timezone: "America/New_York", standup_days: [1, 2, 3, 4, 5] }
  end

  it "persists the team and makes the creator an owner" do
    team = described_class.call(user: user, attributes: attributes)

    expect(team).to be_persisted
    expect(team.created_by).to eq(user)
    expect(user.member_of?(team)).to be true
    expect(team.team_memberships.find_by(user: user)).to be_role_owner
  end

  it "raises a ValidationError for invalid attributes" do
    expect {
      described_class.call(user: user, attributes: { name: "" })
    }.to raise_error(Errors::ValidationError)
  end
end
