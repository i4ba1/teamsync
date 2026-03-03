class NotificationSerializer
  include JSONAPI::Serializer

  attributes :id, :notification_type, :title, :message, :data, :read, :read_at

  attribute :read do |object|
    object.read?
  end

  attribute :read_at do |object|
    object.read_at&.iso8601
  end

  attribute :created_at do |object|
    object.created_at.iso8601
  end

  belongs_to :team, serializer: TeamSerializer
end
