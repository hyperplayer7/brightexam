module Expenses
  class AuditLogger
    def self.log!(expense:, actor:, action:, from_status: nil, to_status: nil, metadata: {})
      ExpenseAuditLog.create!(
        expense: expense,
        actor: actor,
        action: action,
        from_status: from_status,
        to_status: to_status,
        metadata: metadata || {}
      )
    end
  end
end
