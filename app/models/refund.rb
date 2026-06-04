class Refund < ApplicationRecord
  belongs_to :invoice

  validates :amount_pence, presence: true, numericality: { greater_than: 0 }
  validates :reason,       presence: true
  validates :issued_at,    presence: true

  def formatted_amount
    format("£%.2f", amount_pence / 100.0)
  end
end
