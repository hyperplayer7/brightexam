class Expense < ApplicationRecord
  belongs_to :user
  belongs_to :reviewer, class_name: "User", optional: true
  belongs_to :category, optional: true
  has_many :audit_logs, class_name: "ExpenseAuditLog", dependent: :nullify

  enum :status, {
    drafted: 0,
    submitted: 1,
    approved: 2,
    rejected: 3
  }

  validates :amount_cents, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :incurred_on, presence: true

  before_validation :normalize_currency
  validate :incurred_on_not_in_future

  private

  def normalize_currency
    self.currency = currency.to_s.upcase
  end

  def incurred_on_not_in_future
    return if incurred_on.blank?
    return if incurred_on <= Date.current

    errors.add(:incurred_on, "must be today or earlier")
  end
end
