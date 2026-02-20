class User < ApplicationRecord
  has_secure_password

  has_many :expenses, dependent: :destroy
  has_many :review_assignments, class_name: "Expense", foreign_key: :reviewer_id, inverse_of: :reviewer, dependent: :nullify

  enum :role, { employee: 0, reviewer: 1 }

  before_validation :normalize_email

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 8 }, if: -> { password.present? }
  validates :role, presence: true

  private

  def normalize_email
    self.email = email.to_s.downcase.strip
  end
end
