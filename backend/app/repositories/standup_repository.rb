class StandupRepository < ApplicationRepository
  class << self
    def for_team(team)
      team.standups
    end

    def filtered(scope, filters)
      scope = scope.includes(:user, :standup_items).order(standup_date: :desc, created_at: :desc)

      if filters[:start_date].present? && filters[:end_date].present?
        scope = scope.for_date_range(filters[:start_date], filters[:end_date])
      elsif filters[:date].present?
        scope = scope.for_date(filters[:date])
      end

      scope = scope.where(user_id: filters[:user_id]) if filters[:user_id].present?
      scope = scope.where(status: filters[:status]) if filters[:status].present?

      scope
    end

    def paginate(scope, page, per_page)
      scope.page(page).per(per_page)
    end

    def find!(team, id)
      team.standups.find(id)
    end

    def find_or_initialize(team:, user:, standup_date:)
      Standup.find_or_initialize_by(team: team, user: user, standup_date: standup_date)
    end

    def find_or_initialize_today(team, user)
      find_or_initialize(team: team, user: user, standup_date: Date.current)
    end

    def today_for(team)
      team.standups.for_date(Date.current)
    end

    def submitted_user_ids(team)
      today_for(team).where(status: :submitted).select(:user_id)
    end

    def for_date(team, date)
      team.standups.where(standup_date: date)
    end

    def create(attributes)
      Standup.create!(attributes)
    end

    def destroy(standup)
      standup.destroy!
    end

    def transaction(&block)
      Standup.transaction(&block)
    end
  end
end
