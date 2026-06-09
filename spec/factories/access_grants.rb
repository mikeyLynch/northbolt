FactoryBot.define do
  factory :access_grant do
    association :lock
    association :tenant
    pin_ciphertext { SecureRandom.hex(16) }
    starts_at   { Time.current }
    ends_at     { 1.month.from_now }
    revoked_at  { nil }

    trait :revoked do
      revoked_at { 1.day.ago }
    end

    trait :expired do
      starts_at { 2.days.ago }
      ends_at   { 1.day.ago }
    end
  end
end
