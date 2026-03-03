class TeamMembershipSerializer
  include JSONAPI::Serializer

  attributes :id, :role, :joined_at

  attribute :joined_at do |object|
    object.joined_at.iso8601
  end

  belongs_to :user, serializer: UserSerializer
  belongs_to :team, serializer: TeamSerializer
end
