FactoryBot.define do
  factory :refund do
    association :invoice
    amount_pence { 5_000 }
    reason       { "Customer requested refund" }
    issued_at    { Time.current }
  end
end
