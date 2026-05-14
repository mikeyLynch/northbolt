class Tenant < ApplicationRecord
  belongs_to :business
  has_many :access_grants, dependent: :destroy
  has_many :locks, through: :access_grants

  validates :first_name, presence: true
  validates :last_name,  presence: true
  validates :email,      uniqueness: { scope: :business_id, case_sensitive: false, allow_blank: true }
  validates :phone,      uniqueness: { scope: :business_id, allow_blank: true }

  def full_name
    "#{first_name} #{last_name}"
  end
end
