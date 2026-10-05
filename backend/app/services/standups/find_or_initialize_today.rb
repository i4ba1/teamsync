module Standups
  class FindOrInitializeToday < ApplicationService
    def initialize(team:, user:)
      @team = team
      @user = user
    end

    def call
      StandupRepository.find_or_initialize_today(@team, @user)
    end
  end
end
