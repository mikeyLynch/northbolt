FactoryBot.define do
  factory :user do
    association :business
    sequence(:email) { |n| "user#{n}@example.com" }
    first_name { "Jane" }
    last_name { "Doe" }
    password { "password123" }
  end
end
