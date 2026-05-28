class Business < ApplicationRecord
  has_many :locations,  dependent: :destroy
  has_many :locks,      through: :locations
  has_many :tenants,    dependent: :destroy
  has_many :users,      dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :api_keys,   dependent: :destroy

  validates :name, presence: true

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
