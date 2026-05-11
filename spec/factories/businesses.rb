FactoryBot.define do
  factory :business do
    sequence(:name) { |n| "Business #{n}" }
  end
end
