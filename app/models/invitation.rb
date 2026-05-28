class Invitation < ApplicationRecord
  belongs_to :business
  belongs_to :invited_by, class_name: "User"

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token, presence: true, uniqueness: true

  scope :pending,  -> { where(accepted_at: nil) }
  scope :accepted, -> { where.not(accepted_at: nil) }
  scope :recent,   -> { order(created_at: :desc) }

  before_validation :generate_token, on: :create

  def pending?
    accepted_at.nil?
  end

  def regenerate_token!
    update!(token: SecureRandom.urlsafe_base64(32))
  end

  def accept!(first_name:, last_name:, password:)
    user = business.users.create!(
      email: email,
      first_name: first_name,
      last_name: last_name,
      password: password,
      role: "member"
    )
    touch(:accepted_at)
    user
  end

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32)
  end
end
