module Expenses
  class Approve
    def self.call(expense:, actor:)
      Expense.transaction do
        unless expense.submitted?
          expense.errors.add(:status, "must be submitted to approve")
          raise ActiveRecord::RecordInvalid.new(expense)
        end

        unless actor&.reviewer?
          expense.errors.add(:base, "only reviewers can approve expenses")
          raise ActiveRecord::RecordInvalid.new(expense)
        end

        expense.status = :approved
        expense.reviewed_at = Time.current
        expense.reviewer_id = actor.id
        expense.rejection_reason = nil
        expense.save!
      end

      expense
    end
  end
end
