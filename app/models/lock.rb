class Lock < ApplicationRecord
  belongs_to :location
  has_many :access_grants, dependent: :destroy
  has_many :tenants, through: :access_grants
  has_one :current_grant, -> { active }, class_name: "AccessGrant"
  has_one :current_tenant, through: :current_grant, source: :tenant

  CONNECTIVITY_THRESHOLD = 10.minutes

  validates :unit_identifier, presence: true
  validates :device_uuid, presence: true, uniqueness: true, format: { with: /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i }

  def bolt_position
    [ "Unknown", "Open", "Closed" ].sample
  end

  def tenancy_status
    now = Time.current
    grants = access_grants.where(revoked_at: nil)
                          .where("ends_at > ?", now)
                          .where("starts_at <= ?", 1.week.from_now)
                          .to_a
    active = grants.find { |g| g.starts_at <= now }
    if active
      active.ends_at <= 3.days.from_now ? "available_soon" : "unavailable"
    elsif grants.any?
      "unavailable_soon"
    else
      "available"
    end
  end

  def probably_online?
    last_seen_at.present? && last_seen_at >= CONNECTIVITY_THRESHOLD.ago
  end

  def probably_offline?
    !probably_online?
  end
end
