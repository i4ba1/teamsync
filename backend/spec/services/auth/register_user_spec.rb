require "rails_helper"

RSpec.describe Auth::RegisterUser do
  let(:attributes) do
    {
      email: "newuser@example.com",
      password: "password123",
      first_name: "New",
      last_name: "User",
      timezone: "UTC"
    }
  end

  it "creates a user and returns auth tokens" do
    result = described_class.call(attributes: attributes)

    expect(result[:user]).to be_persisted
    expect(result[:tokens][:access_token]).to be_present
    expect(result[:tokens][:refresh_token]).to be_present
    expect(result[:tokens][:expires_in]).to be_present
  end

  it "raises a ValidationError when the contract fails" do
    expect {
      described_class.call(attributes: { email: "invalid" })
    }.to raise_error(Errors::ValidationError, "Validation failed")
  end

  it "raises a ValidationError when the model is invalid" do
    create(:user, email: attributes[:email])

    expect {
      described_class.call(attributes: attributes)
    }.to raise_error(Errors::ValidationError)
  end
end
