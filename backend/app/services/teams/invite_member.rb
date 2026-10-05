module Teams
  class InviteMember < ApplicationService
    CONTRACT = InviteMemberContract.new

    def initialize(team:, email:, role: nil)
      @team = team
      @email = email
      @role = role
    end

    def call
      attrs = validate(CONTRACT, email: @email, role: @role)

      user = UserRepository.find_by_email(attrs[:email])
      raise Errors::NotFoundError, "User not found" if user.nil?
      raise Errors::ValidationError, "User is already a member of this team" if TeamMembershipRepository.exists?(@team, user)

      membership = TeamMembershipRepository.create(
        @team,
        user: user,
        role: attrs[:role] || :member,
        joined_at: Time.current
      )

      unless membership.persisted?
        raise Errors::ValidationError.new("Validation failed", details: membership.errors.full_messages)
      end

      membership
    end
  end
end
