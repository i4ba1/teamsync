module Standups
  # Creates or updates a standup for a team member.
  #
  # When `record` is provided the standup is updated, otherwise it is created
  # (or reused for the given date). Persistence and item management live here
  # rather than on the model.
  class UpsertStandup < ApplicationService
    CONTRACT = UpsertStandupContract.new

    def initialize(team:, user:, attributes:, record: nil)
      @team = team
      @user = user
      @attributes = attributes
      @record = record
    end

    def call
      attrs = validate(CONTRACT, @attributes)
      date = attrs[:standup_date].presence || Date.current
      items = attrs[:items] || []
      standup = @record || StandupRepository.find_or_initialize(team: @team, user: @user, standup_date: date)

      if attrs[:submit] == true
        submit!(standup, items)
      elsif @record.nil?
        save_draft(standup, items)
      else
        update_existing(standup, items, attrs[:status])
      end

      standup
    end

    private

    def submit!(standup, items)
      StandupRepository.transaction do
        update_items(standup, items)
        standup.update!(status: :submitted, completed_at: Time.current)
      end
    rescue ActiveRecord::RecordInvalid => e
      raise Errors::ValidationError.new(
        "Validation failed",
        details: e.record&.errors&.full_messages || [e.message]
      )
    end

    def save_draft(standup, items)
      standup.status = :draft

      unless standup.save
        raise Errors::ValidationError.new("Validation failed", details: standup.errors.full_messages)
      end

      update_items(standup, items) if items.present?
    end

    def update_existing(standup, items, status)
      update_items(standup, items) if items.present?

      return if standup.update(status: status.presence || standup.status)

      raise Errors::ValidationError.new("Validation failed", details: standup.errors.full_messages)
    end

    def update_items(standup, items)
      return if items.blank?

      items.each do |item_data|
        item_type = item_data[:item_type] || item_data["item_type"]
        content = item_data[:content] || item_data["content"]
        sort_order = item_data[:order] || item_data["order"] || 0

        next if item_type.blank?

        item = standup.standup_items.find_or_initialize_by(item_type: item_type)
        item.content = content || ""
        item.sort_order = sort_order
        item.save!
      end
    end
  end
end
