class Lock < ApplicationRecord
  belongs_to :location
  has_many :access_grants, dependent: :destroy
  has_many :access_events, dependent: :destroy
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

  def self.compute_tenancy_statuses(locks)
    now = Time.current
    lock_ids = locks.map(&:id)
    statuses = lock_ids.index_with { "available" }

    AccessGrant
      .where(lock_id: lock_ids, revoked_at: nil)
      .where("ends_at > ?", now)
      .where("starts_at <= ?", 1.week.from_now)
      .select(:lock_id, :starts_at, :ends_at)
      .each do |grant|
        current = statuses[grant.lock_id]
        if grant.starts_at <= now
          if grant.ends_at <= 3.days.from_now
            statuses[grant.lock_id] = "available_soon"
          elsif current != "available_soon"
            statuses[grant.lock_id] = "unavailable"
          end
        elsif current == "available"
          statuses[grant.lock_id] = "unavailable_soon"
        end
      end

    statuses
  end
end
