module Standups
  class UpsertStandupContract < ApplicationContract
    params do
      optional(:standup_date).maybe(:string)
      optional(:status).maybe(:string)
      optional(:submit).maybe(:bool)
      optional(:items).array(:hash)
    end
  end
end
