require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:team_memberships).dependent(:destroy) }
    it { should have_many(:teams).through(:team_memberships) }
    it { should have_many(:owned_teams).class_name('Team').with_foreign_key('created_by_id') }
    it { should have_many(:standups).dependent(:destroy) }
    it { should have_many(:notifications).dependent(:destroy) }
    it { should have_many(:refresh_tokens).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_presence_of(:timezone) }
    it { should validate_length_of(:first_name).is_at_most(50) }
    it { should validate_length_of(:last_name).is_at_most(50) }
    it { should validate_length_of(:password).is_at_least(8).on(:create) }
    
    it 'validates email format' do
      user = build(:user, email: 'invalid')
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include('is invalid')
    end

    it 'validates timezone inclusion' do
      user = build(:user, timezone: 'Invalid/Timezone')
      expect(user).not_to be_valid
    end
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(active: 0, inactive: 1, suspended: 2).with_prefix }
    it { should define_enum_for(:role).with_values(member: 0, admin: 1, super_admin: 2).with_prefix }
  end

  describe 'callbacks' do
    describe '#downcase_email' do
      it 'downcases email before validation' do
        user = create(:user, email: 'TEST@EXAMPLE.COM')
        expect(user.email).to eq('test@example.com')
      end
    end
  end

  describe 'scopes' do
    describe '.active' do
      it 'returns only active users' do
        active_user = create(:user, status: :active)
        create(:user, :inactive)
        
        expect(User.active).to eq([active_user])
      end
    end
  end

  describe '#full_name' do
    it 'returns the full name' do
      user = build(:user, first_name: 'John', last_name: 'Doe')
      expect(user.full_name).to eq('John Doe')
    end
  end

  describe '#initials' do
    it 'returns the initials' do
      user = build(:user, first_name: 'John', last_name: 'Doe')
      expect(user.initials).to eq('JD')
    end
  end

  describe '#member_of?' do
    let(:user) { create(:user) }
    let(:team) { create(:team) }

    it 'returns true when user is a member' do
      create(:team_membership, user: user, team: team)
      expect(user.member_of?(team)).to be true
    end

    it 'returns false when user is not a member' do
      expect(user.member_of?(team)).to be false
    end
  end

  describe '#admin_of?' do
    let(:user) { create(:user) }
    let(:team) { create(:team) }

    it 'returns true when user is an admin' do
      create(:team_membership, :admin, user: user, team: team)
      expect(user.admin_of?(team)).to be true
    end

    it 'returns true when user is an owner' do
      create(:team_membership, :owner, user: user, team: team)
      expect(user.admin_of?(team)).to be true
    end

    it 'returns false when user is a regular member' do
      create(:team_membership, user: user, team: team)
      expect(user.admin_of?(team)).to be false
    end
  end
end
