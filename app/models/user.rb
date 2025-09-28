class User < ApplicationRecord
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }

  has_many :sleep_records, dependent: :destroy

  # Following relationships
  has_many :follower_relationships, class_name: "Follow", foreign_key: "follower_id", dependent: :destroy
  has_many :followee_relationships, class_name: "Follow", foreign_key: "followee_id", dependent: :destroy

  has_many :following, through: :follower_relationships, source: :followee
  has_many :followers, through: :followee_relationships, source: :follower

  def follow(user)
    following << user unless following.include?(user) || self == user
  end

  def unfollow(user)
    following.delete(user)
  end

  def following?(user)
    following.include?(user)
  end

  def follower_count
    followers.count
  end

  def following_count
    following.count
  end
end
