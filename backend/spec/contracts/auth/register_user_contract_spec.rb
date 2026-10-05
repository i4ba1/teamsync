require "rails_helper"

RSpec.describe Auth::RegisterUserContract do
  subject(:contract) { described_class.new }

  let(:valid_attributes) do
    {
      email: "contract@example.com",
      password: "password123",
      first_name: "Contract",
      last_name: "Tester",
      timezone: "UTC"
    }
  end

  it "is valid with all required attributes" do
    expect(contract.call(valid_attributes)).to be_success
  end

  it "requires an email" do
    result = contract.call(valid_attributes.except(:email))

    expect(result).not_to be_success
    expect(result.errors.to_h).to include(:email)
  end

  it "requires a password" do
    result = contract.call(valid_attributes.except(:password))

    expect(result).not_to be_success
    expect(result.errors.to_h).to include(:password)
  end
end
