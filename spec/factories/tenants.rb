FactoryBot.define do
  factory :tenant do
    association :business
    first_name { "Jane" }
    last_name  { "Smith" }
    sequence(:email) { |n| "tenant#{n}@example.com" }
    sequence(:phone) { |n| "0770090#{n.to_s.rjust(4, '0')}" }
  end
end
