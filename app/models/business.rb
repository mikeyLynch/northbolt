class Business < ApplicationRecord
  PERMISSIONS = %w[manage_team manage_settings manage_api_keys manage_tenants grant_access revoke_access view_activity].freeze

  DEFAULT_PERMISSION_MATRIX = {
    "high"   => %w[manage_team manage_settings manage_api_keys manage_tenants grant_access revoke_access view_activity],
    "medium" => %w[manage_tenants grant_access revoke_access view_activity],
    "low"    => %w[grant_access view_activity]
  }.freeze

  ROLE_LABELS = { "high" => "High", "medium" => "Medium", "low" => "Low" }.freeze
  has_many :locations,  dependent: :destroy
  has_many :locks,      through: :locations
  has_many :tenants,    dependent: :destroy
  has_many :users,      dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :api_keys,      dependent: :destroy
  has_many :invitations,   dependent: :destroy

  validates :name, presence: true

  def role_can?(role, permission)
    permission_matrix.fetch(role.to_s, []).include?(permission.to_s)
  end

  def generate_stora_webhook_token!
    update!(stora_webhook_token: SecureRandom.hex(16))
  end

  def stora_configured?
    stora_webhook_token.present? && stora_webhook_secret.present?
  end

  def verify_stora_signature(payload, signature_header, tolerance: 300)
    return false unless stora_webhook_secret.present?
    return false unless signature_header.present?

    parts     = signature_header.split(",").map { |p| p.split("=", 2) }.to_h
    timestamp = parts["t"]&.to_i
    v1        = parts["v1"]
    return false unless timestamp && v1

    return false if (Time.current.to_i - timestamp).abs > tolerance

    expected = OpenSSL::HMAC.hexdigest("SHA256", stora_webhook_secret, "#{timestamp}.#{payload}")
    ActiveSupport::SecurityUtils.secure_compare(expected, v1)
  end
end
