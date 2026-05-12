class Business < ApplicationRecord
  has_many :locations, dependent: :destroy
  has_many :users, dependent: :destroy
  has_many :notifications, dependent: :destroy

  validates :name, presence: true
end
