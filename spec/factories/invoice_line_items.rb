FactoryBot.define do
  factory :invoice_line_item do
    association :invoice
    description      { "Northbolt Smart Lock × 10" }
    quantity         { 10 }
    unit_price_pence { 29_900 }
    total_pence      { 299_000 }
  end
end
