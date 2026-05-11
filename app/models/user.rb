class User < ApplicationRecord
  belongs_to :business

  validates :email, presence: true, uniqueness: true
  validates :first_name, presence: true
  validates :last_name, presence: true
end
