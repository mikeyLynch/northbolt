class AccessEvent < ApplicationRecord
  TYPES = %w[pin_accepted pin_rejected bolt_locked bolt_opened].freeze

  belongs_to :lock

  validates :event_type, inclusion: { in: TYPES }
  validates :occurred_at, presence: true

  scope :recent, -> { order(occurred_at: :desc) }
end
