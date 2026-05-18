FactoryBot.define do
  factory :access_event do
    association :lock
    event_type  { "pin_accepted" }
    occurred_at { Time.current }
  end
end
