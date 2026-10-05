require "rails_helper"

RSpec.describe Auth::AuthenticateUser do
  let!(:user) { create(:user, email: "login@example.com", password: "password123") }

  it "returns the user and tokens with valid credentials" do
    result = described_class.call(attributes: { email: user.email, password: "password123" })

    expect(result[:user]).to eq(user)
    expect(result[:tokens][:access_token]).to be_present
  end

  it "raises UnauthorizedError with invalid credentials" do
    expect {
      described_class.call(attributes: { email: user.email, password: "wrong" })
    }.to raise_error(Errors::UnauthorizedError, "Invalid email or password")
  end

  it "raises UnauthorizedError for inactive users" do
    user.update!(status: :inactive)

    expect {
      described_class.call(attributes: { email: user.email, password: "password123" })
    }.to raise_error(Errors::UnauthorizedError)
  end
end
