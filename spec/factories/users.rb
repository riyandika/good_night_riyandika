FactoryBot.define do
  factory :user do
    name { Faker::Name.name }

    trait :with_followers do
      after(:create) do |user|
        create_list(:user, 3).each do |follower|
          follower.follow(user)
        end
      end
    end

    trait :with_followings do
      after(:create) do |user|
        create_list(:user, 3).each do |followee|
          user.follow(followee)
        end
      end
    end
  end
end
