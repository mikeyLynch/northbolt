class InvoiceLineItem < ApplicationRecord
  belongs_to :invoice

  validates :description,      presence: true
  validates :quantity,         presence: true, numericality: { greater_than: 0 }
  validates :unit_price_pence, presence: true
  validates :total_pence,      presence: true

  def formatted_unit_price
    format("£%.2f", unit_price_pence / 100.0)
  end

  def formatted_total
    format("£%.2f", total_pence / 100.0)
  end
end
