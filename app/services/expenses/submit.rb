module Expenses
  class Submit
    def self.call(expense:)
      Expense.transaction do
        unless expense.drafted?
          expense.errors.add(:status, "must be drafted to submit")
          raise ActiveRecord::RecordInvalid.new(expense)
        end

        expense.status = :submitted
        expense.submitted_at = Time.current
        expense.save!
      end

      expense
    end
  end
end
