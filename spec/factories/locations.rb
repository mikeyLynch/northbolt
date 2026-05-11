FactoryBot.define do
  factory :location do
    association :business
    sequence(:name) { |n| "Location #{n}" }
  end
end
