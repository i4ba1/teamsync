class UserSerializer
  include JSONAPI::Serializer

  attributes :id, :email, :first_name, :last_name, :full_name, :initials, :timezone, :avatar_url, :status, :role

  attribute :full_name do |object|
    object.full_name
  end

  attribute :initials do |object|
    object.initials
  end

  attribute :created_at do |object|
    object.created_at.iso8601
  end
end
