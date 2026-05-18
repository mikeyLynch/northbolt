class Business < ApplicationRecord
  has_many :locations, dependent: :destroy
  has_many :locks, through: :locations
  has_many :tenants, dependent: :destroy
  has_many :users, dependent: :destroy
  has_many :notifications, dependent: :destroy

  validates :name, presence: true

  def self.generate_api_key(business_id)
    secret = SecureRandom.hex(24)
    token  = "nb_#{business_id}_#{secret}"
    digest = Digest::SHA256.hexdigest(secret)
    [ token, digest ]
  end

  def self.find_by_api_key(token)
    parts = token.to_s.split("_")
    return nil unless parts.length == 3 && parts[0] == "nb"

    business = find_by(id: parts[1])
    return nil unless business&.api_key_digest.present?

    ActiveSupport::SecurityUtils.secure_compare(
      Digest::SHA256.hexdigest(parts[2]),
      business.api_key_digest
    ) ? business : nil
  end
end
