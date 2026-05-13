FactoryBot.define do
  factory :tenant do
    association :business
    first_name { "Jane" }
    last_name  { "Smith" }
    sequence(:email) { |n| "tenant#{n}@example.com" }
    phone { "07700900000" }
  end
end
