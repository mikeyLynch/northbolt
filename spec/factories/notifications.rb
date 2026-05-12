FactoryBot.define do
  factory :notification do
    association :business
    notification_type { "generic" }
    sequence(:title) { |n| "Notification #{n}" }
    body { "A notification body." }
    read_at { nil }
  end
end
