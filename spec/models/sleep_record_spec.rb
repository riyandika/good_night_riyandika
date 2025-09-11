require 'rails_helper'

RSpec.describe SleepRecord, type: :model do
  let(:user) { User.create!(name: 'Test User') }

  describe 'validations' do
    it 'is valid with valid attributes' do
      sleep_record = SleepRecord.new(
        user: user,
        sleep_at: 1.hour.ago,
        wake_up_at: Time.current,
        duration_in_seconds: 3600
      )
      expect(sleep_record).to be_valid
    end

    it 'is not valid without sleep_at' do
      sleep_record = SleepRecord.new(
        user: user,
        wake_up_at: Time.current,
        duration_in_seconds: 3600
      )
      expect(sleep_record).not_to be_valid
      expect(sleep_record.errors[:sleep_at]).to include("can't be blank")
    end

    it 'is not valid with duration_in_seconds equal to 0' do
      sleep_record = SleepRecord.new(
        user: user,
        sleep_at: 1.hour.ago,
        wake_up_at: Time.current,
        duration_in_seconds: 0
      )
      expect(sleep_record).not_to be_valid
      expect(sleep_record.errors[:duration_in_seconds]).to include('must be greater than 0')
    end

    it 'is not valid with negative duration_in_seconds' do
      sleep_record = SleepRecord.new(
        user: user,
        sleep_at: 1.hour.ago,
        wake_up_at: Time.current,
        duration_in_seconds: -100
      )
      expect(sleep_record).not_to be_valid
      expect(sleep_record.errors[:duration_in_seconds]).to include('must be greater than 0')
    end

    it 'is not valid when wake_up_at is before sleep_at' do
      sleep_at = Time.current
      wake_up_at = 1.hour.ago
      
      sleep_record = SleepRecord.new(
        user: user,
        sleep_at: sleep_at,
        wake_up_at: wake_up_at,
        duration_in_seconds: 3600
      )
      
      expect(sleep_record).not_to be_valid
      expect(sleep_record.errors[:wake_up_at]).to include('must be after sleep time')
    end

    it 'is not valid when wake_up_at equals sleep_at' do
      time = Time.current
      
      sleep_record = SleepRecord.new(
        user: user,
        sleep_at: time,
        wake_up_at: time,
        duration_in_seconds: 3600
      )
      
      expect(sleep_record).not_to be_valid
      expect(sleep_record.errors[:wake_up_at]).to include('must be after sleep time')
    end
  end

  describe 'associations' do
    it 'belongs to user' do
      association = SleepRecord.reflect_on_association(:user)
      expect(association.macro).to eq(:belongs_to)
    end

    it 'is not valid without a user' do
      sleep_record = SleepRecord.new(
        sleep_at: 1.hour.ago,
        wake_up_at: Time.current,
        duration_in_seconds: 3600
      )
      expect(sleep_record).not_to be_valid
    end
  end

  describe 'scopes' do
    let(:user1) { User.create!(name: 'User 1') }
    let(:user2) { User.create!(name: 'User 2') }
    let!(:old_record) do
      SleepRecord.create!(
        user: user1,
        sleep_at: 2.days.ago,
        wake_up_at: 2.days.ago + 8.hours,
        duration_in_seconds: 28800,
        created_at: 2.days.ago
      )
    end
    let!(:new_record) do
      SleepRecord.create!(
        user: user1,
        sleep_at: 1.day.ago,
        wake_up_at: 1.day.ago + 7.hours,
        duration_in_seconds: 25200,
        created_at: 1.day.ago
      )
    end
    let!(:user2_record) do
      SleepRecord.create!(
        user: user2,
        sleep_at: 1.hour.ago,
        wake_up_at: Time.current,
        duration_in_seconds: 3600
      )
    end

    describe '.recent' do
      it 'orders records by created_at desc' do
        recent_records = SleepRecord.recent
        expect(recent_records.first).to eq(user2_record)
        expect(recent_records.second).to eq(new_record)
        expect(recent_records.third).to eq(old_record)
      end
    end

    describe '.for_user' do
      it 'returns records for the specified user only' do
        user1_records = SleepRecord.for_user(user1)
        expect(user1_records).to include(old_record, new_record)
        expect(user1_records).not_to include(user2_record)
        expect(user1_records.count).to eq(2)
      end
    end

    describe '.between_dates' do
      it 'returns records within the specified date range' do
        start_date = 3.days.ago
        end_date = 1.day.ago
        
        records_in_range = SleepRecord.between_dates(start_date, end_date)
        expect(records_in_range).to include(old_record, new_record)
        expect(records_in_range).not_to include(user2_record)
      end
    end
  end

  describe 'custom validation' do
    describe '#wake_up_after_sleep' do
      it 'allows wake_up_at to be after sleep_at' do
        sleep_record = SleepRecord.new(
          user: user,
          sleep_at: 1.hour.ago,
          wake_up_at: Time.current,
          duration_in_seconds: 3600
        )
        expect(sleep_record).to be_valid
      end

      it 'skips validation when sleep_at is nil' do
        sleep_record = SleepRecord.new(
          user: user,
          sleep_at: nil,
          wake_up_at: Time.current,
          duration_in_seconds: 3600
        )
        sleep_record.valid?
        expect(sleep_record.errors[:wake_up_at]).not_to include('must be after sleep time')
      end

      it 'skips validation when wake_up_at is nil' do
        sleep_record = SleepRecord.new(
          user: user,
          sleep_at: 1.hour.ago,
          wake_up_at: nil,
          duration_in_seconds: 3600
        )
        sleep_record.valid?
        expect(sleep_record.errors[:wake_up_at]).not_to include('must be after sleep time')
      end
    end
  end

  describe 'edge cases' do
    it 'handles very short sleep durations' do
      sleep_record = SleepRecord.new(
        user: user,
        sleep_at: 5.minutes.ago,
        wake_up_at: Time.current,
        duration_in_seconds: 300
      )
      expect(sleep_record).to be_valid
    end

    it 'handles very long sleep durations' do
      sleep_record = SleepRecord.new(
        user: user,
        sleep_at: 15.hours.ago,
        wake_up_at: Time.current,
        duration_in_seconds: 54000
      )
      expect(sleep_record).to be_valid
    end

    it 'handles sleep that crosses midnight' do
      yesterday_night = Time.current.beginning_of_day - 2.hours
      this_morning = Time.current.beginning_of_day + 6.hours
      
      sleep_record = SleepRecord.new(
        user: user,
        sleep_at: yesterday_night,
        wake_up_at: this_morning,
        duration_in_seconds: 8.hours.to_i
      )
      expect(sleep_record).to be_valid
    end
  end

  describe 'duration calculation' do
    it 'automatically calculates duration_in_seconds when both sleep_at and wake_up_at are present' do
      sleep_time = Time.current
      wake_time = sleep_time + 8.hours
      
      sleep_record = SleepRecord.create!(
        user: user,
        sleep_at: sleep_time, 
        wake_up_at: wake_time
      )
      
      expect(sleep_record.duration_in_seconds).to eq(8.hours.to_i)
    end

    it 'does not calculate duration when wake_up_at is nil' do
      sleep_record = SleepRecord.create!(
        user: user,
        sleep_at: Time.current,
        wake_up_at: nil
      )
      expect(sleep_record.duration_in_seconds).to be_nil
    end

    it 'recalculates duration when wake_up_at is updated' do
      sleep_time = Time.current
      initial_wake_time = sleep_time + 6.hours
      new_wake_time = sleep_time + 9.hours
      
      sleep_record = SleepRecord.create!(
        user: user,
        sleep_at: sleep_time, 
        wake_up_at: initial_wake_time
      )
      
      expect(sleep_record.duration_in_seconds).to eq(6.hours.to_i)
      
      sleep_record.update!(wake_up_at: new_wake_time)
      expect(sleep_record.duration_in_seconds).to eq(9.hours.to_i)
    end

    it 'does not override manually set duration when wake_up_at is nil' do
      sleep_record = SleepRecord.create!(
        user: user,
        sleep_at: Time.current,
        wake_up_at: nil,
        duration_in_seconds: 1234
      )
      expect(sleep_record.duration_in_seconds).to eq(1234)
    end
  end
end
