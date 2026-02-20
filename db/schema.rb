# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_02_20_000200) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "expenses", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "reviewer_id"
    t.integer "amount_cents", null: false
    t.string "currency", default: "USD", null: false
    t.text "description", null: false
    t.string "merchant", null: false
    t.date "incurred_on", null: false
    t.integer "status", default: 0, null: false
    t.datetime "submitted_at"
    t.datetime "reviewed_at"
    t.text "rejection_reason"
    t.integer "lock_version", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["incurred_on"], name: "index_expenses_on_incurred_on"
    t.index ["reviewer_id"], name: "index_expenses_on_reviewer_id"
    t.index ["status"], name: "index_expenses_on_status"
    t.index ["user_id"], name: "index_expenses_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "expenses", "users"
  add_foreign_key "expenses", "users", column: "reviewer_id"
end
