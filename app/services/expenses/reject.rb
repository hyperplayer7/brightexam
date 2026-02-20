module Expenses
  class Reject
    def self.call(expense:, actor:, rejection_reason:)
      Expense.transaction do
        unless expense.submitted?
          expense.errors.add(:status, "must be submitted to reject")
          raise ActiveRecord::RecordInvalid.new(expense)
        end

        unless actor&.reviewer?
          expense.errors.add(:base, "only reviewers can reject expenses")
          raise ActiveRecord::RecordInvalid.new(expense)
        end

        if rejection_reason.blank?
          expense.errors.add(:rejection_reason, "can't be blank")
          raise ActiveRecord::RecordInvalid.new(expense)
        end

        expense.status = :rejected
        expense.reviewed_at = Time.current
        expense.reviewer_id = actor.id
        expense.rejection_reason = rejection_reason
        expense.save!
      end

      expense
    end
  end
end
