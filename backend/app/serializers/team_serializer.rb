class TeamSerializer
  include JSONAPI::Serializer

  attributes :id, :name, :slug, :timezone, :standup_time, :standup_days, :settings, :invite_code

  attribute :standup_time do |object|
    object.standup_time.strftime("%H:%M")
  end

  attribute :member_count do |object|
    object.member_count
  end

  attribute :current_user_role do |object, params|
    current_user = params[:current_user]
    object.member_role(current_user) if current_user
  end

  attribute :today_stats do |object|
    {
      submitted: object.today_submitted_count,
      missed: object.today_missed_count,
      total: object.member_count
    }
  end

  attribute :invite_code do |object|
    object.invite_code if object.invite_code_valid?
  end

  attribute :created_at do |object|
    object.created_at.iso8601
  end

  has_many :members, serializer: UserSerializer
  belongs_to :created_by, serializer: UserSerializer
end
