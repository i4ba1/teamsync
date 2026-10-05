module Teams
  class UpdateTeam < ApplicationService
    CONTRACT = UpdateTeamContract.new

    def initialize(team:, attributes:)
      @team = team
      @attributes = attributes
    end

    def call
      attrs = validate(CONTRACT, @attributes)

      unless TeamRepository.update(@team, attrs)
        raise Errors::ValidationError.new("Validation failed", details: @team.errors.full_messages)
      end

      @team
    end
  end
end
