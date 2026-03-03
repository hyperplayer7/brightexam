class ExpenseSerializer
  def self.collection(expenses)
    Array(expenses).map { |expense| new(expense).serializable_hash }
  end

  def initialize(expense)
    @expense = expense
  end

  def serializable_hash
    {
      id: expense.id,
      user_id: expense.user_id,
      reviewer_id: expense.reviewer_id,
      user: user_payload(expense.user),
      reviewer: expense.reviewer ? user_payload(expense.reviewer) : nil,
      category: expense.category ? category_payload(expense.category) : nil,
      amount_cents: expense.amount_cents,
      currency: expense.currency,
      description: expense.description,
      merchant: expense.merchant,
      incurred_on: expense.incurred_on,
      status: expense.status,
      submitted_at: expense.submitted_at,
      reviewed_at: expense.reviewed_at,
      rejection_reason: expense.rejection_reason,
      lock_version: expense.lock_version,
      created_at: expense.created_at,
      updated_at: expense.updated_at
    }
  end

  private

  attr_reader :expense

  def user_payload(user)
    return nil unless user

    {
      id: user.id,
      email: user.email,
      role: user.role
    }
  end

  def category_payload(category)
    {
      id: category.id,
      name: category.name
    }
  end
end
