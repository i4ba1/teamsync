require "rails_helper"

RSpec.describe "Related records in JSON:API responses", type: :request do
  let(:user) { create(:user) }
  let(:team) { create(:team, created_by: user) }

  it "includes standup authors and items in the standups index" do
    create(:standup, :with_items, :submitted, team: team, user: user, standup_date: Date.current)

    get "/api/v1/teams/#{team.slug}/standups", headers: auth_headers(user)

    expect(response).to have_http_status(:ok)
    included_types = json_body[:included].map { |resource| resource[:type] }
    expect(included_types).to include("user")
    expect(included_types).to include("standup_item")
  end

  it "includes member users in the team members index" do
    get "/api/v1/teams/#{team.slug}/members", headers: auth_headers(user)

    expect(response).to have_http_status(:ok)
    included_types = json_body[:included].map { |resource| resource[:type] }
    expect(included_types).to include("user")
  end
end
