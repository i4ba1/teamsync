module Auth
  class RefreshSessionContract < ApplicationContract
    params do
      required(:refresh_token).filled(:string)
    end
  end
end
