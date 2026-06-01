class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable
  belongs_to :business

  enum :role, { owner: "owner", high: "high", medium: "medium", low: "low" }, default: "owner"

  validates :email, presence: true, uniqueness: true
  validates :first_name, presence: true
  validates :last_name, presence: true
end
