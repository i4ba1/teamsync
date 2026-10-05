module Teams
  class ListUserTeams < ApplicationService
    def initialize(user:)
      @user = user
    end

    def call
      TeamRepository.for_user(@user)
    end
  end
end
