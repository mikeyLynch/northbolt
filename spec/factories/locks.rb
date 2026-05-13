FactoryBot.define do
  factory :lock do
    association :location
    sequence(:unit_identifier) { |n| n.to_s }
    device_uuid { SecureRandom.uuid }
  end
end
