class SleepRecordSerializer < ActiveModel::Serializer
  attributes :id, :user_id, :sleep_at, :wake_up_at, :duration_in_seconds, :created_at
  belongs_to :user, serializer: UserSerializer

  def created_at
    object.created_at.iso8601
  end
end
