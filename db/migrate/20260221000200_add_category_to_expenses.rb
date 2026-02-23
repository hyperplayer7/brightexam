class AddCategoryToExpenses < ActiveRecord::Migration[8.0]
  def change
    add_reference :expenses, :category, null: true, foreign_key: true
  end
end
