class Lock < ApplicationRecord
  belongs_to :location

  validates :name, presence: true
end
