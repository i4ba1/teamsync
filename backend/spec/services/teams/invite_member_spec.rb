require "rails_helper"

RSpec.describe Teams::InviteMember do
  let(:owner) { create(:user) }
  let(:team) { create(:team, created_by: owner) }
  let(:invitee) { create(:user) }

  it "adds the invited user as a member" do
    membership = described_class.call(team: team, email: invitee.email)

    expect(membership).to be_persisted
    expect(membership.user).to eq(invitee)
    expect(membership).to be_role_member
  end

  it "raises NotFoundError when the user does not exist" do
    expect {
      described_class.call(team: team, email: "nobody@example.com")
    }.to raise_error(Errors::NotFoundError)
  end

  it "raises ValidationError when the user is already a member" do
    described_class.call(team: team, email: invitee.email)

    expect {
      described_class.call(team: team, email: invitee.email)
    }.to raise_error(Errors::ValidationError)
  end
end
