require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      user = User.new(name: 'John Doe')
      expect(user).to be_valid
    end

    it 'is not valid without a name' do
      user = User.new(name: nil)
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("can't be blank")
    end

    it 'is not valid with a name shorter than 2 characters' do
      user = User.new(name: 'A')
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include('is too short (minimum is 2 characters)')
    end

    it 'is not valid with a name longer than 100 characters' do
      user = User.new(name: 'A' * 101)
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include('is too long (maximum is 100 characters)')
    end

    it 'is valid with a name of exactly 2 characters' do
      user = User.new(name: 'AB')
      expect(user).to be_valid
    end

    it 'is valid with a name of exactly 100 characters' do
      user = User.new(name: 'A' * 100)
      expect(user).to be_valid
    end
  end

  describe 'associations' do
    it 'has many sleep_records' do
      association = User.reflect_on_association(:sleep_records)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end

    it 'has many follower_relationships' do
      association = User.reflect_on_association(:follower_relationships)
      expect(association.macro).to eq(:has_many)
      expect(association.class_name).to eq('Follow')
      expect(association.foreign_key).to eq('follower_id')
      expect(association.options[:dependent]).to eq(:destroy)
    end

    it 'has many followee_relationships' do
      association = User.reflect_on_association(:followee_relationships)
      expect(association.macro).to eq(:has_many)
      expect(association.class_name).to eq('Follow')
      expect(association.foreign_key).to eq('followee_id')
      expect(association.options[:dependent]).to eq(:destroy)
    end

    it 'has many following through follower_relationships' do
      association = User.reflect_on_association(:following)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:through]).to eq(:follower_relationships)
      expect(association.options[:source]).to eq(:followee)
    end

    it 'has many followers through followee_relationships' do
      association = User.reflect_on_association(:followers)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:through]).to eq(:followee_relationships)
      expect(association.options[:source]).to eq(:follower)
    end
  end

  describe 'follow functionality' do
    let(:user1) { User.create!(name: 'Alice') }
    let(:user2) { User.create!(name: 'Bob') }
    let(:user3) { User.create!(name: 'Charlie') }

    describe '#follow' do
      it 'allows a user to follow another user' do
        expect { user1.follow(user2) }.to change { user1.following.count }.by(1)
        expect(user1.following).to include(user2)
      end

      it 'does not allow a user to follow themselves' do
        expect { user1.follow(user1) }.not_to change { user1.following.count }
        expect(user1.following).not_to include(user1)
      end

      it 'does not create duplicate follows' do
        user1.follow(user2)
        expect { user1.follow(user2) }.not_to change { user1.following.count }
      end
    end

    describe '#unfollow' do
      before { user1.follow(user2) }

      it 'allows a user to unfollow another user' do
        expect { user1.unfollow(user2) }.to change { user1.following.count }.by(-1)
        expect(user1.following).not_to include(user2)
      end

      it 'does nothing if user is not following the target' do
        expect { user1.unfollow(user3) }.not_to change { user1.following.count }
      end
    end

    describe '#following?' do
      it 'returns true if user is following the target' do
        user1.follow(user2)
        expect(user1.following?(user2)).to be true
      end

      it 'returns false if user is not following the target' do
        expect(user1.following?(user2)).to be false
      end
    end

    describe '#follower_count' do
      it 'returns the correct number of followers' do
        user1.follow(user2)
        user3.follow(user2)
        expect(user2.follower_count).to eq(2)
      end

      it 'returns 0 when user has no followers' do
        expect(user1.follower_count).to eq(0)
      end
    end

    describe '#following_count' do
      it 'returns the correct number of users being followed' do
        user1.follow(user2)
        user1.follow(user3)
        expect(user1.following_count).to eq(2)
      end

      it 'returns 0 when user is not following anyone' do
        expect(user1.following_count).to eq(0)
      end
    end
  end

  describe 'dependent destroy' do
    let(:user) { User.create!(name: 'Test User') }
    let(:other_user) { User.create!(name: 'Other User') }

    it 'destroys associated sleep_records when user is destroyed' do
      sleep_record = SleepRecord.create!(
        user: user,
        sleep_at: 1.hour.ago,
        wake_up_at: Time.current,
        duration_in_seconds: 3600
      )
      
      expect { user.destroy }.to change { SleepRecord.count }.by(-1)
    end

    it 'destroys follow relationships when user is destroyed' do
      user.follow(other_user)
      other_user.follow(user)
      
      expect { user.destroy }.to change { Follow.count }.by(-2)
    end
  end
end
