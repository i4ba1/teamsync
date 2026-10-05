module Teams
  class InviteMemberContract < ApplicationContract
    params do
      required(:email).filled(:string)
      optional(:role).maybe(:string)
    end
  end
end
