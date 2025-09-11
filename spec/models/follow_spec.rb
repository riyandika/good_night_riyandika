require 'rails_helper'

RSpec.describe Follow, type: :model do
  let(:follower) { User.create!(name: 'Alice') }
  let(:followee) { User.create!(name: 'Bob') }

  describe 'validations' do
    it 'is valid with valid attributes' do
      follow = Follow.new(follower: follower, followee: followee)
      expect(follow).to be_valid
    end

    it 'is not valid without a follower' do
      follow = Follow.new(followee: followee)
      expect(follow).not_to be_valid
    end

    it 'is not valid without a followee' do
      follow = Follow.new(follower: follower)
      expect(follow).not_to be_valid
    end

    it 'is not valid when follower and followee are the same user' do
      follow = Follow.new(follower: follower, followee: follower)
      expect(follow).not_to be_valid
      expect(follow.errors[:followee]).to include("can't follow yourself")
    end

    it 'is not valid with duplicate follower-followee combination' do
      Follow.create!(follower: follower, followee: followee)
      duplicate_follow = Follow.new(follower: follower, followee: followee)
      
      expect(duplicate_follow).not_to be_valid
      expect(duplicate_follow.errors[:follower_id]).to include('has already been taken')
    end

    it 'allows the same user to be followed by different users' do
      other_follower = User.create!(name: 'Charlie')
      
      Follow.create!(follower: follower, followee: followee)
      second_follow = Follow.new(follower: other_follower, followee: followee)
      
      expect(second_follow).to be_valid
    end

    it 'allows the same user to follow different users' do
      other_followee = User.create!(name: 'Diana')
      
      Follow.create!(follower: follower, followee: followee)
      second_follow = Follow.new(follower: follower, followee: other_followee)
      
      expect(second_follow).to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to follower (User)' do
      association = Follow.reflect_on_association(:follower)
      expect(association.macro).to eq(:belongs_to)
      expect(association.class_name).to eq('User')
    end

    it 'belongs to followee (User)' do
      association = Follow.reflect_on_association(:followee)
      expect(association.macro).to eq(:belongs_to)
      expect(association.class_name).to eq('User')
    end

    it 'correctly associates with follower user' do
      follow = Follow.create!(follower: follower, followee: followee)
      expect(follow.follower).to eq(follower)
    end

    it 'correctly associates with followee user' do
      follow = Follow.create!(follower: follower, followee: followee)
      expect(follow.followee).to eq(followee)
    end
  end

  describe 'scopes' do
    let(:user1) { User.create!(name: 'User 1') }
    let(:user2) { User.create!(name: 'User 2') }
    let(:user3) { User.create!(name: 'User 3') }
    
    let!(:old_follow) do
      Follow.create!(
        follower: user1,
        followee: user2,
        created_at: 2.days.ago
      )
    end
    
    let!(:new_follow) do
      Follow.create!(
        follower: user1,
        followee: user3,
        created_at: 1.day.ago
      )
    end
    
    let!(:other_follow) do
      Follow.create!(
        follower: user2,
        followee: user3,
        created_at: 1.hour.ago
      )
    end

    describe '.recent' do
      it 'orders follows by created_at desc' do
        recent_follows = Follow.recent
        expect(recent_follows.first).to eq(other_follow)
        expect(recent_follows.second).to eq(new_follow)
        expect(recent_follows.third).to eq(old_follow)
      end
    end

    describe '.for_follower' do
      it 'returns follows where the user is the follower' do
        user1_follows = Follow.for_follower(user1)
        expect(user1_follows).to include(old_follow, new_follow)
        expect(user1_follows).not_to include(other_follow)
        expect(user1_follows.count).to eq(2)
      end

      it 'returns empty when user has no follows' do
        new_user = User.create!(name: 'New User')
        follows = Follow.for_follower(new_user)
        expect(follows).to be_empty
      end
    end

    describe '.for_followee' do
      it 'returns follows where the user is being followed' do
        user3_followers = Follow.for_followee(user3)
        expect(user3_followers).to include(new_follow, other_follow)
        expect(user3_followers).not_to include(old_follow)
        expect(user3_followers.count).to eq(2)
      end

      it 'returns empty when user has no followers' do
        new_user = User.create!(name: 'New User')
        follows = Follow.for_followee(new_user)
        expect(follows).to be_empty
      end
    end
  end

  describe 'custom validation' do
    describe '#cannot_follow_self' do
      it 'prevents user from following themselves' do
        follow = Follow.new(follower: follower, followee: follower)
        follow.valid?
        expect(follow.errors[:followee]).to include("can't follow yourself")
      end

      it 'allows following different users' do
        follow = Follow.new(follower: follower, followee: followee)
        expect(follow).to be_valid
      end

      it 'validates correctly when follower_id and followee_id are set directly' do
        follow = Follow.new(follower_id: follower.id, followee_id: follower.id)
        follow.valid?
        expect(follow.errors[:followee]).to include("can't follow yourself")
      end
    end
  end

  describe 'database constraints' do
    it 'enforces uniqueness at database level' do
      Follow.create!(follower: follower, followee: followee)
      
      expect {
        # Skip validations to test database constraint
        follow = Follow.new(follower: follower, followee: followee)
        follow.save!(validate: false)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe 'edge cases' do
    it 'handles follow creation with string IDs' do
      follow = Follow.new(
        follower_id: follower.id.to_s,
        followee_id: followee.id.to_s
      )
      expect(follow).to be_valid
    end

    it 'maintains referential integrity' do
      follow = Follow.create!(follower: follower, followee: followee)
      
      # Follower deletion should cascade
      expect { follower.destroy }.to change { Follow.count }.by(-1)
    end

    it 'allows symmetric following relationships' do
      # A follows B
      follow1 = Follow.create!(follower: follower, followee: followee)
      
      # B follows A
      follow2 = Follow.create!(follower: followee, followee: follower)
      
      expect(follow1).to be_persisted
      expect(follow2).to be_persisted
      expect(Follow.count).to eq(2)
    end
  end
end
