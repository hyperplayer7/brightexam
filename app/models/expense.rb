class Expense < ApplicationRecord
  belongs_to :user
  belongs_to :reviewer, class_name: "User", optional: true

  enum :status, {
    drafted: 0,
    submitted: 1,
    approved: 2,
    rejected: 3
  }

  validates :amount_cents, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :incurred_on, presence: true

  before_validation :normalize_currency

  private

  def normalize_currency
    self.currency = currency.to_s.upcase
  end
end
