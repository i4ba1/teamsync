class StandupItem < ApplicationRecord
  # Associations
  belongs_to :standup

  # Enums
  enum item_type: {
    yesterday: 0,
    today: 1,
    blockers: 2,
    notes: 3
  }, _prefix: true

  # Validations
  validates :item_type, presence: true
  validates :content, presence: true, allow_blank: true
  validates :sort_order, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Callbacks
  before_validation :set_default_order, on: :create

  # Scopes
  scope :by_type, ->(type) { where(item_type: type) }
  scope :ordered, -> { order(:sort_order, :created_at) }

  private

  def set_default_order
    return if sort_order.present?

    max_order = standup.standup_items.where(item_type: item_type).maximum(:sort_order) || 0
    self.sort_order = max_order + 1
  end
end
