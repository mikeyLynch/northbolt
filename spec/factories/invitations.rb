FactoryBot.define do
  factory :invitation do
    association :business
    association :invited_by, factory: :user
    sequence(:email) { |n| "invitee#{n}@example.com" }
    accepted_at { nil }

    trait :accepted do
      accepted_at { 1.hour.ago }
    end
  end
end
