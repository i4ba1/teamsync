module Standups
  class ListStandupsContract < ApplicationContract
    params do
      optional(:start_date).maybe(:string)
      optional(:end_date).maybe(:string)
      optional(:date).maybe(:string)
      optional(:user_id).maybe(:string)
      optional(:status).maybe(:string)
    end
  end
end
