class StandupItemSerializer
  include JSONAPI::Serializer

  attributes :id, :item_type, :content, :sort_order

  attribute :created_at do |object|
    object.created_at.iso8601
  end

  belongs_to :standup
end
