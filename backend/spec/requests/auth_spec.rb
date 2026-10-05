require 'rails_helper'

RSpec.describe "Authentication", type: :request do
  describe "POST /api/v1/auth/signup" do
    let(:valid_params) do
      {
        user: {
          email: "newuser@example.com",
          password: "password123",
          first_name: "New",
          last_name: "User",
          timezone: "UTC"
        }
      }
    end

    it "creates a new user" do
      expect {
        post "/api/v1/auth/signup", params: valid_params
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_body[:data][:email]).to eq("newuser@example.com")
      expect(json_body[:data][:token]).to be_present
      expect(json_body[:data][:refresh_token]).to be_present
    end

    it "returns validation errors for invalid data" do
      post "/api/v1/auth/signup", params: { user: { email: "invalid" } }
      
      expect(response).to have_http_status(422)
      expect(json_body[:error]).to eq("Validation failed")
    end

    it "does not allow duplicate emails" do
      create(:user, email: "newuser@example.com")
      post "/api/v1/auth/signup", params: valid_params
      
      expect(response).to have_http_status(422)
    end
  end

  describe "POST /api/v1/auth/login" do
    let!(:user) { create(:user, email: "test@example.com", password: "password123") }

    it "authenticates with valid credentials" do
      post "/api/v1/auth/login", params: { email: "test@example.com", password: "password123" }
      
      expect(response).to have_http_status(:ok)
      expect(json_body[:data][:email]).to eq("test@example.com")
      expect(json_body[:data][:token]).to be_present
    end

    it "rejects invalid credentials" do
      post "/api/v1/auth/login", params: { email: "test@example.com", password: "wrongpassword" }
      
      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects inactive users" do
      user.update(status: :inactive)
      post "/api/v1/auth/login", params: { email: "test@example.com", password: "password123" }
      
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/auth/me" do
    let!(:user) { create(:user) }

    it "returns current user when authenticated" do
      get "/api/v1/auth/me", headers: auth_headers(user)
      
      expect(response).to have_http_status(:ok)
      expect(json_body[:data][:id]).to eq(user.id.to_s)
    end

    it "returns unauthorized without token" do
      get "/api/v1/auth/me"
      
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PUT /api/v1/auth/me" do
    let!(:user) { create(:user) }

    it "updates user profile" do
      put "/api/v1/auth/me", 
          params: { user: { first_name: "Updated" } },
          headers: auth_headers(user)
      
      expect(response).to have_http_status(:ok)
      expect(json_body[:data][:first_name]).to eq("Updated")
    end
  end

  describe "DELETE /api/v1/auth/logout" do
    let!(:user) { create(:user) }
    let(:tokens) { PasetoService.generate_tokens(user) }

    it "revokes the refresh token" do
      delete "/api/v1/auth/logout", 
             params: { refresh_token: tokens[:refresh_token] },
             headers: { "Authorization" => "Bearer #{tokens[:access_token]}" }
      
      expect(response).to have_http_status(:no_content)
    end
  end

  describe "POST /api/v1/auth/refresh" do
    let!(:user) { create(:user) }
    let!(:tokens) { PasetoService.generate_tokens(user) }

    it "refreshes access token with valid refresh token" do
      post "/api/v1/auth/refresh", params: { refresh_token: tokens[:refresh_token] }
      
      expect(response).to have_http_status(:ok)
      expect(json_body[:token]).to be_present
      expect(json_body[:refresh_token]).to be_present
    end

    it "rejects invalid refresh token" do
      post "/api/v1/auth/refresh", params: { refresh_token: "invalid" }
      
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
