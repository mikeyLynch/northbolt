class Lock < ApplicationRecord
  belongs_to :location

  CONNECTIVITY_THRESHOLD = 10.minutes

  validates :unit_identifier, presence: true
  validates :device_uuid, presence: true, uniqueness: true, format: { with: /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i }

  def bolt_position
    :unknown
  end

  def probably_online?
    last_seen_at.present? && last_seen_at >= CONNECTIVITY_THRESHOLD.ago
  end

  def probably_offline?
    !probably_online?
  end
end
