module Teams
  class CreateTeamContract < ApplicationContract
    params do
      required(:name).filled(:string)
      optional(:timezone).filled(:string)
      optional(:standup_time).filled(:string)
      optional(:standup_days).array(:integer)
    end
  end
end
