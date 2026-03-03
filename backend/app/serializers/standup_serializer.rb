class StandupSerializer
  include JSONAPI::Serializer

  attributes :id, :standup_date, :status, :completed_at, :editable

  attribute :standup_date do |object|
    object.standup_date.to_s
  end

  attribute :completed_at do |object|
    object.completed_at&.iso8601
  end

  attribute :editable do |object|
    object.editable?
  end

  attribute :items_summary do |object|
    object.standup_items.group_by(&:item_type).transform_values do |items|
      items.map(&:content)
    end
  end

  attribute :created_at do |object|
    object.created_at.iso8601
  end

  belongs_to :user, serializer: UserSerializer
  belongs_to :team, serializer: TeamSerializer
  has_many :standup_items, serializer: StandupItemSerializer
end
