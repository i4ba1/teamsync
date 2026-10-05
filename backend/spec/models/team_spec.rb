require 'rails_helper'

RSpec.describe Team, type: :model do
  describe 'associations' do
    it { should belong_to(:created_by).class_name('User') }
    it { should have_many(:team_memberships).dependent(:destroy) }
    it { should have_many(:members).through(:team_memberships).source(:user) }
    it { should have_many(:standups).dependent(:destroy) }
    it { should have_many(:notifications).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:timezone) }
    it { should validate_presence_of(:standup_days) }
    it { should validate_length_of(:name).is_at_most(100) }

    it 'validates slug format' do
      team = build(:team, slug: 'Invalid Slug!')
      expect(team).not_to be_valid
    end
  end

  describe 'callbacks' do
    describe '#generate_slug' do
      it 'generates a slug from name if not provided' do
        team = create(:team, name: 'My Awesome Team', slug: nil)
        expect(team.slug).to eq('my-awesome-team')
      end

      it 'handles duplicate slugs' do
        create(:team, name: 'Test Team', slug: 'test-team')
        team2 = create(:team, name: 'Test Team', slug: nil)
        expect(team2.slug).to eq('test-team-1')
      end
    end

    describe '#add_creator_as_owner' do
      it 'adds creator as owner after create' do
        user = create(:user)
        team = create(:team, created_by: user)
        
        expect(team.members).to include(user)
        expect(team.team_memberships.find_by(user: user)).to be_role_owner
      end
    end
  end

  describe '#standup_due_today?' do
    it 'returns true when today is in standup_days' do
      team = build(:team, standup_days: [Date.current.wday])
      expect(team.standup_due_today?).to be true
    end

    it 'returns false when today is not in standup_days' do
      team = build(:team, standup_days: [])
      expect(team.standup_due_today?).to be false
    end
  end

  describe '#generate_invite_code!' do
    it 'generates and saves an invite code' do
      team = create(:team)
      code = team.generate_invite_code!
      
      expect(code).to be_present
      expect(team.invite_code).to eq(code)
      expect(team.invite_code_expires_at).to be > Time.current
    end
  end

  describe '#invite_code_valid?' do
    it 'returns true for valid invite code' do
      team = create(:team)
      team.generate_invite_code!
      
      expect(team.invite_code_valid?).to be true
    end

    it 'returns false for expired invite code' do
      team = create(:team)
      team.update(invite_code: 'TEST123', invite_code_expires_at: 1.day.ago)
      
      expect(team.invite_code_valid?).to be false
    end

    it 'returns false when no invite code' do
      team = create(:team)
      expect(team.invite_code_valid?).to be false
    end
  end
end
