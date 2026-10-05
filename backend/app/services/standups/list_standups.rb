module Standups
  class ListStandups < ApplicationService
    CONTRACT = ListStandupsContract.new

    def initialize(team:, filters:, page: nil, per_page: nil)
      @team = team
      @filters = filters
      @page = page
      @per_page = per_page
    end

    def call
      attrs = validate(CONTRACT, @filters)
      scope = StandupRepository.filtered(StandupRepository.for_team(@team), attrs)

      StandupRepository.paginate(scope, @page || 1, @per_page || 20)
    end
  end
end
