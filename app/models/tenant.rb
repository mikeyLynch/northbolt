class Tenant < ApplicationRecord
  belongs_to :business
  has_many :access_grants, dependent: :destroy
  has_many :locks, through: :access_grants

  before_validation :normalise_blanks

  validates :first_name, presence: true
  validates :last_name,  presence: true
  validates :email,      uniqueness: { scope: :business_id, case_sensitive: false, allow_nil: true }
  validates :phone,      uniqueness: { scope: :business_id, allow_nil: true }

  def full_name
    "#{first_name} #{last_name}"
  end

  private

  def normalise_blanks
    self.email = nil if email.blank?
    self.phone = nil if phone.blank?
  end
end
