FactoryBot.define do
  factory :api_key do
    association :business
    sequence(:name) { |n| "API Key #{n}" }
    digest { Digest::SHA256.hexdigest("testkey") }
    revoked_at { nil }
  end
end
