require 'rails_helper'

RSpec.describe "Teams", type: :request do
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }
  # Creating the team adds the creator as owner (Team#add_creator_as_owner).
  let!(:team) { create(:team, created_by: user) }

  describe "GET /api/v1/teams" do
    it "returns user's teams" do
      get "/api/v1/teams", headers: auth_headers(user)
      
      expect(response).to have_http_status(:ok)
      expect(json_body[:data]).to be_an(Array)
      expect(json_body[:data].first[:attributes][:name]).to eq(team.name)
    end
  end

  describe "GET /api/v1/teams/:slug" do
    it "returns team details" do
      get "/api/v1/teams/#{team.slug}", headers: auth_headers(user)
      
      expect(response).to have_http_status(:ok)
      expect(json_body[:data][:attributes][:name]).to eq(team.name)
    end

    it "returns 404 for non-existent team" do
      get "/api/v1/teams/non-existent", headers: auth_headers(user)
      
      expect(response).to have_http_status(:not_found)
    end

    it "returns forbidden for non-members" do
      get "/api/v1/teams/#{team.slug}", headers: auth_headers(other_user)
      
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/teams" do
    let(:valid_params) do
      {
        team: {
          name: "New Team",
          timezone: "America/New_York",
          standup_time: "10:00",
          standup_days: [1, 2, 3, 4, 5]
        }
      }
    end

    it "creates a new team" do
      expect {
        post "/api/v1/teams", params: valid_params, headers: auth_headers(user)
      }.to change(Team, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_body[:data][:attributes][:name]).to eq("New Team")
    end

    it "automatically adds creator as owner" do
      post "/api/v1/teams", params: valid_params, headers: auth_headers(user)
      
      new_team = Team.last
      expect(new_team.members).to include(user)
      expect(new_team.team_memberships.find_by(user: user)).to be_role_owner
    end
  end

  describe "PUT /api/v1/teams/:slug" do
    it "updates team for admin/owner" do
      put "/api/v1/teams/#{team.slug}", 
          params: { team: { name: "Updated Team" } },
          headers: auth_headers(user)
      
      expect(response).to have_http_status(:ok)
      expect(json_body[:data][:attributes][:name]).to eq("Updated Team")
    end

    it "returns forbidden for regular members" do
      create(:team_membership, user: other_user, team: team)
      
      put "/api/v1/teams/#{team.slug}", 
          params: { team: { name: "Updated Team" } },
          headers: auth_headers(other_user)
      
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/v1/teams/:slug" do
    it "deletes team for owner" do
      expect {
        delete "/api/v1/teams/#{team.slug}", headers: auth_headers(user)
      }.to change(Team, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "returns forbidden for non-owners" do
      create(:team_membership, :admin, user: other_user, team: team)
      
      delete "/api/v1/teams/#{team.slug}", headers: auth_headers(other_user)
      
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/teams/:slug/invite" do
    let!(:new_member) { create(:user) }

    it "invites a user to the team" do
      expect {
        post "/api/v1/teams/#{team.slug}/invite",
             params: { email: new_member.email },
             headers: auth_headers(user)
      }.to change(team.members, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it "returns error for already member" do
      create(:team_membership, user: new_member, team: team)
      
      post "/api/v1/teams/#{team.slug}/invite",
           params: { email: new_member.email },
           headers: auth_headers(user)
      
      expect(response).to have_http_status(422)
    end
  end

  describe "POST /api/v1/teams/:slug/join" do
    before do
      team.generate_invite_code!
    end

    it "allows joining with valid invite code" do
      expect {
        post "/api/v1/teams/#{team.slug}/join",
             params: { invite_code: team.invite_code },
             headers: auth_headers(other_user)
      }.to change(team.members, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it "rejects invalid invite code" do
      post "/api/v1/teams/#{team.slug}/join",
           params: { invite_code: "INVALID" },
           headers: auth_headers(other_user)
      
      expect(response).to have_http_status(422)
    end
  end
end
