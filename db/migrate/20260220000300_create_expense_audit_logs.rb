class CreateExpenseAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :expense_audit_logs do |t|
      t.references :expense, null: true, foreign_key: { on_delete: :nullify }
      t.references :actor, null: false, polymorphic: true
      t.string :action, null: false
      t.string :from_status
      t.string :to_status
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :expense_audit_logs, :action
    add_index :expense_audit_logs, :created_at
  end
end
