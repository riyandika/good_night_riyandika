class SleepRecord < ApplicationRecord
  belongs_to :user
  
  validates :sleep_at, presence: true
  validates :wake_up_at, presence: true
  validates :duration_in_seconds, presence: true, numericality: { greater_than: 0 }
  
  validate :wake_up_after_sleep
  
  scope :recent, -> { order(created_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }
  scope :between_dates, ->(start_date, end_date) { where(sleep_at: start_date..end_date) }
  
  private
  
  def wake_up_after_sleep
    return unless sleep_at && wake_up_at
    
    if wake_up_at <= sleep_at
      errors.add(:wake_up_at, 'must be after sleep time')
    end
  end
end
