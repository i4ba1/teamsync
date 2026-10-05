module Teams
  class JoinTeamContract < ApplicationContract
    params do
      optional(:invite_code).maybe(:string)
    end
  end
end
