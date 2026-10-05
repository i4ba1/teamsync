module Teams
  class CreateTeam < ApplicationService
    CONTRACT = CreateTeamContract.new

    def initialize(user:, attributes:)
      @user = user
      @attributes = attributes
    end

    def call
      attrs = validate(CONTRACT, @attributes)
      team = TeamRepository.build_for(@user, attrs)

      unless team.save
        raise Errors::ValidationError.new("Validation failed", details: team.errors.full_messages)
      end

      team
    end
  end
end
