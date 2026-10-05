module Auth
  class RegisterUserContract < ApplicationContract
    params do
      required(:email).filled(:string)
      required(:password).filled(:string)
      required(:first_name).filled(:string)
      required(:last_name).filled(:string)
      optional(:timezone).filled(:string)
    end
  end
end
