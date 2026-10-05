module Teams
  class DeleteTeam < ApplicationService
    def initialize(team:)
      @team = team
    end

    def call
      TeamRepository.destroy(@team)
    end
  end
end
