class CreateExpenses < ActiveRecord::Migration[8.0]
  def change
    create_table :expenses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :reviewer, null: true, foreign_key: { to_table: :users }
      t.integer :amount_cents, null: false
      t.string :currency, null: false, default: "USD"
      t.text :description, null: false
      t.string :merchant, null: false
      t.date :incurred_on, null: false
      t.integer :status, null: false, default: 0
      t.datetime :submitted_at
      t.datetime :reviewed_at
      t.text :rejection_reason
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end

    add_index :expenses, :status
    add_index :expenses, :incurred_on
  end
end
