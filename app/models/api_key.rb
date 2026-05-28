class ApiKey < ApplicationRecord
  belongs_to :business

  validates :name,   presence: true
  validates :digest, presence: true

  scope :active,   -> { where(revoked_at: nil) }
  scope :revoked,  -> { where.not(revoked_at: nil) }
  scope :recent,   -> { order(created_at: :desc) }

  def self.generate(business:, name:)
    secret = SecureRandom.hex(24)
    key    = create!(
      business: business,
      name:     name,
      digest:   Digest::SHA256.hexdigest(secret)
    )
    token = "nb_#{key.id}_#{secret}"
    [ key, token ]
  end

  def self.authenticate(token)
    parts = token.to_s.split("_")
    return nil unless parts.length == 3 && parts[0] == "nb"

    key = find_by(id: parts[1])
    return nil unless key && key.revoked_at.nil?
    return nil unless ActiveSupport::SecurityUtils.secure_compare(
      Digest::SHA256.hexdigest(parts[2]),
      key.digest
    )

    key.touch(:last_used_at)
    key.business
  end

  def revoke!
    touch(:revoked_at)
  end

  def active?
    revoked_at.nil?
  end
end
