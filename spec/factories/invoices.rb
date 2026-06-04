FactoryBot.define do
  factory :invoice do
    association :business
    sequence(:number) { |n| "NB-2026-#{n.to_s.rjust(3, '0')}" }
    category       { "hardware" }
    installment    { "deposit" }
    status         { "draft" }
    subtotal_pence { 149_500 }
    vat_rate       { 0.20 }
    vat_pence      { 29_900 }
    total_pence    { 179_400 }
    issued_at      { Date.current }
    due_at         { Date.current + 30.days }

    trait :outstanding do
      status { "outstanding" }
    end

    trait :paid do
      status  { "paid" }
      paid_at { Time.current }
    end

    trait :service do
      category             { "service" }
      installment          { "full" }
      subtotal_pence       { 48_000 }
      vat_pence            { 9_600 }
      total_pence          { 57_600 }
      service_period_start { Date.current }
      service_period_end   { Date.current + 1.year - 1.day }
    end

    trait :with_line_items do
      after(:create) do |invoice|
        create(:invoice_line_item, invoice: invoice,
               description: "Northbolt Smart Lock × 10",
               quantity: 10,
               unit_price_pence: 14_950,
               total_pence: 149_500)
      end
    end
  end
end
