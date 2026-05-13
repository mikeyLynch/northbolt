class Lock < ApplicationRecord
  belongs_to :location

  validates :unit_identifier, presence: true
  validates :device_uuid, presence: true, uniqueness: true, format: { with: /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i }
end
