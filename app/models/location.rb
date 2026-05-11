class Location < ApplicationRecord
  belongs_to :business
  has_many :locks, dependent: :destroy

  validates :name, presence: true
end
