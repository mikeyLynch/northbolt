class Business < ApplicationRecord
  has_many :locations, dependent: :destroy
  has_many :locks, through: :locations
  has_many :tenants, dependent: :destroy
  has_many :users, dependent: :destroy
  has_many :notifications, dependent: :destroy

  validates :name, presence: true

  def self.find_by_api_key(token)
    all.find { |b| b.api_key_digest.present? && BCrypt::Password.new(b.api_key_digest) == token }
  end
end
