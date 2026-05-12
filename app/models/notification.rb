class Notification < ApplicationRecord
  belongs_to :business
  belongs_to :notifiable, polymorphic: true, optional: true

  enum :notification_type, {
    access_granted: "access_granted",
    lock_closed:    "lock_closed",
    pin_failed:     "pin_failed",
    battery_low:    "battery_low",
    generic:        "generic"
  }, validate: true

  validates :title, presence: true
  validates :notification_type, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc).limit(20) }

  def read?
    read_at.present?
  end

  def mark_read!
    update!(read_at: Time.current) unless read?
  end
end
