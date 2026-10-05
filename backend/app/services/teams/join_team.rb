module Teams
  class JoinTeam < ApplicationService
    CONTRACT = JoinTeamContract.new

    def initialize(team:, user:, invite_code: nil)
      @team = team
      @user = user
      @invite_code = invite_code
    end

    def call
      attrs = validate(CONTRACT, invite_code: @invite_code)
      code = attrs[:invite_code]

      if code.present?
        unless @team.invite_code_valid? && @team.invite_code == code.upcase
          raise Errors::ValidationError, "Invalid or expired invite code"
        end
      end

      raise Errors::ValidationError, "You are already a member of this team" if TeamMembershipRepository.exists?(@team, @user)

      membership = TeamMembershipRepository.create(
        @team,
        user: @user,
        role: :member,
        joined_at: Time.current
      )

      unless membership.persisted?
        raise Errors::ValidationError.new("Validation failed", details: membership.errors.full_messages)
      end

      TeamRepository.clear_invite_code(@team) if code.present?

      @team
    end
  end
end
