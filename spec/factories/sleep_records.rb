FactoryBot.define do
  factory :sleep_record do
    association :user
    sleep_at { 8.hours.ago }
    wake_up_at { nil } # Default to in-progress record
    duration_in_seconds { nil }

    trait :completed do
      wake_up_at { 8.hours.ago + 8.hours }
      duration_in_seconds { 28800 } # 8 hours in seconds
    end

    trait :in_progress do
      wake_up_at { nil }
      duration_in_seconds { nil }
    end

    trait :short_sleep do
      wake_up_at { sleep_at + 4.hours }
      duration_in_seconds { 14400 } # 4 hours
    end

    trait :long_sleep do
      wake_up_at { sleep_at + 10.hours }
      duration_in_seconds { 36000 } # 10 hours
    end

    # Custom trait for creating completed records with specific durations
    trait :with_duration do
      transient do
        hours { 8 }
      end

      wake_up_at { sleep_at + hours.hours }
      duration_in_seconds { hours * 3600 }
    end
  end
end
