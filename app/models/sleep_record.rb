class SleepRecord < ApplicationRecord
  belongs_to :user
  
  validates :sleep_at, presence: true
  validates :duration_in_seconds, numericality: { greater_than: 0 }, allow_nil: true
  
  validate :wake_up_after_sleep
  
  before_save :calculate_duration
  
  scope :recent, -> { order(created_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }
  scope :between_dates, ->(start_date, end_date) { where(sleep_at: start_date..end_date) }
  scope :completed, -> { where.not(wake_up_at: nil) }
  scope :in_progress, -> { where(wake_up_at: nil) }
  
  def completed?
    wake_up_at.present?
  end
  
  def in_progress?
    wake_up_at.nil?
  end
  
  def complete_sleep!(wake_time = Time.current)
    self.wake_up_at = wake_time
    self.duration_in_seconds = (wake_up_at - sleep_at).to_i
    save!
  end
  
  private
  
  def wake_up_after_sleep
    return unless sleep_at && wake_up_at
    
    if wake_up_at <= sleep_at
      errors.add(:wake_up_at, 'must be after sleep time')
    end
  end
  
  def calculate_duration
    return unless sleep_at && wake_up_at
    
    self.duration_in_seconds = (wake_up_at - sleep_at).to_i
  end
end
