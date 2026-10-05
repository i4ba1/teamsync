module Teams
  class UpdateTeamContract < ApplicationContract
    params do
      optional(:name).filled(:string)
      optional(:timezone).filled(:string)
      optional(:standup_time).filled(:string)
      optional(:standup_days).array(:integer)
    end
  end
end
