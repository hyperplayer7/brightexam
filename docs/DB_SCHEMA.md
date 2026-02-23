# Database Schema

Source of truth: `db/schema.rb`.

Schema version:
- `2026_02_21_000200`

## Extensions
- `pg_catalog.plpgsql`

## Tables

### `categories`
Columns:
- `id` (bigint, primary key)
- `name` (string, null: false)
- `created_at` (datetime, null: false)
- `updated_at` (datetime, null: false)

Indexes:
- `index_categories_on_name` (unique)

---

### `users`
Columns:
- `id` (bigint, primary key)
- `email` (string, null: false)
- `password_digest` (string, null: false)
- `role` (integer, null: false, default: `0`)  
  Used as enum field in application code.
- `created_at` (datetime, null: false)
- `updated_at` (datetime, null: false)

Indexes:
- `index_users_on_email` (unique)

---

### `expenses`
Columns:
- `id` (bigint, primary key)
- `user_id` (bigint, null: false)
- `reviewer_id` (bigint, null: true)
- `category_id` (bigint, null: true)
- `amount_cents` (integer, null: false)
- `currency` (string, null: false, default: `"USD"`)
- `description` (text, null: false)
- `merchant` (string, null: false)
- `incurred_on` (date, null: false)
- `status` (integer, null: false, default: `0`)  
  Used as enum field in application code.
- `submitted_at` (datetime, null: true)
- `reviewed_at` (datetime, null: true)
- `rejection_reason` (text, null: true)
- `lock_version` (integer, null: false, default: `0`)
- `created_at` (datetime, null: false)
- `updated_at` (datetime, null: false)

Indexes:
- `index_expenses_on_user_id`
- `index_expenses_on_reviewer_id`
- `index_expenses_on_category_id`
- `index_expenses_on_status`
- `index_expenses_on_incurred_on`

## Relationships

Foreign keys:
- `expenses.user_id -> users.id`
- `expenses.reviewer_id -> users.id`
- `expenses.category_id -> categories.id`

Association meaning:
- One user (employee/owner) has many owned expenses via `expenses.user_id`.
- One user (reviewer) can review many expenses via `expenses.reviewer_id`.
- One category can be assigned to many expenses via `expenses.category_id`.

## Enum Fields

From schema perspective:
- `users.role` is an integer-backed enum field.
- `expenses.status` is an integer-backed enum field.

Exact enum label mapping in schema: `TBD` (defined in application models, not in `db/schema.rb`).
