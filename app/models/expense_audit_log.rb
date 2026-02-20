class ExpenseAuditLog < ApplicationRecord
  belongs_to :expense, optional: true
  belongs_to :actor, polymorphic: true

  validates :action, presence: true
end
