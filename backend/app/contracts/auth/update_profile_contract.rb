module Auth
  class UpdateProfileContract < ApplicationContract
    params do
      optional(:first_name).filled(:string)
      optional(:last_name).filled(:string)
      optional(:timezone).filled(:string)
      optional(:avatar_url).maybe(:string)
    end
  end
end
