module TeamMembers
  class UpdateRoleContract < ApplicationContract
    params do
      required(:role).filled(:string)
    end
  end
end
