class AccessGrant < ApplicationRecord
  belongs_to :lock
  belongs_to :tenant

  validates :pin_digest,  presence: true
  validates :starts_at,   presence: true
  validates :ends_at,     presence: true
  validate  :only_one_active_grant_per_lock, on: :create

  scope :active,  -> { where(revoked_at: nil) }
  scope :revoked, -> { where.not(revoked_at: nil) }
  scope :expired, -> { active.where("ends_at < ?", Time.current) }

  def active?
    revoked_at.nil?
  end

  def revoked?
    revoked_at.present?
  end

  def revoke!
    touch(:revoked_at)
  end

  private

  def only_one_active_grant_per_lock
    return unless lock_id.present?
    if lock.access_grants.active.exists?
      errors.add(:lock, "already has an active access grant")
    end
  end
end
