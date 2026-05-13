class Tenant < ApplicationRecord
  belongs_to :business
  has_many :access_grants, dependent: :destroy
  has_many :locks, through: :access_grants

  validates :first_name, presence: true
  validates :last_name,  presence: true
  validates :phone,      presence: true
  validates :email,      presence: true,
                         uniqueness: { scope: :business_id, case_sensitive: false }

  def full_name
    "#{first_name} #{last_name}"
  end
end
