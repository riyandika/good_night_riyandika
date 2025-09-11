class Follow < ApplicationRecord
  belongs_to :follower, class_name: 'User'
  belongs_to :followee, class_name: 'User'
  
  validates :follower_id, uniqueness: { scope: :followee_id }
  validate :cannot_follow_self
  
  scope :recent, -> { order(created_at: :desc) }
  scope :for_follower, ->(user) { where(follower: user) }
  scope :for_followee, ->(user) { where(followee: user) }
  
  private
  
  def cannot_follow_self
    if follower_id == followee_id
      errors.add(:followee, "can't follow yourself")
    end
  end
end
