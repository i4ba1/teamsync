module Standups
  class DeleteStandup < ApplicationService
    def initialize(standup:)
      @standup = standup
    end

    def call
      StandupRepository.destroy(@standup)
    end
  end
end
