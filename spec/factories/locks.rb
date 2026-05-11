FactoryBot.define do
  factory :lock do
    association :location
    sequence(:name) { |n| "Unit #{n}" }
  end
end
