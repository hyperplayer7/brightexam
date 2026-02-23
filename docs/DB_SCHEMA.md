# Database Schema (Current `db/schema.rb`)

Source of truth: `db/schema.rb`

Schema version:
- `2026_02_21_000200`

Extensions:
- `pg_catalog.plpgsql`

## Tables

### `categories`

Columns:
- `id` : `bigint` (primary key)
- `name` : `string`, `null: false`
- `created_at` : `datetime`, `null: false`
- `updated_at` : `datetime`, `null: false`

Indexes:
- `index_categories_on_name` (unique)

### `users`

Columns:
- `id` : `bigint` (primary key)
- `email` : `string`, `null: false`
- `password_digest` : `string`, `null: false`
- `role` : `integer`, `null: false`, default `0`
- `created_at` : `datetime`, `null: false`
- `updated_at` : `datetime`, `null: false`

Indexes:
- `index_users_on_email` (unique)

Notes:
- `role` is an integer-backed enum in application code (`employee`, `reviewer`)

### `expenses`

Columns:
- `id` : `bigint` (primary key)
- `user_id` : `bigint`, `null: false`
- `reviewer_id` : `bigint`, `null: true`
- `amount_cents` : `integer`, `null: false`
- `currency` : `string`, `null: false`, default `"USD"`
- `description` : `text`, `null: false`
- `merchant` : `string`, `null: false`
- `incurred_on` : `date`, `null: false`
- `status` : `integer`, `null: false`, default `0`
- `submitted_at` : `datetime`, `null: true`
- `reviewed_at` : `datetime`, `null: true`
- `rejection_reason` : `text`, `null: true`
- `lock_version` : `integer`, `null: false`, default `0`
- `created_at` : `datetime`, `null: false`
- `updated_at` : `datetime`, `null: false`
- `category_id` : `bigint`, `null: true`

Indexes:
- `index_expenses_on_category_id`
- `index_expenses_on_incurred_on`
- `index_expenses_on_reviewer_id`
- `index_expenses_on_status`
- `index_expenses_on_user_id`

Notes:
- `status` is an integer-backed enum in application code (`drafted`, `submitted`, `approved`, `rejected`)
- `lock_version` enables Rails optimistic locking for updates

### `expense_audit_logs`

Columns:
- `id` : `bigint` (primary key)
- `expense_id` : `bigint`, `null: true`
- `actor_type` : `string`, `null: false`
- `actor_id` : `bigint`, `null: false`
- `action` : `string`, `null: false`
- `from_status` : `string`, `null: true`
- `to_status` : `string`, `null: true`
- `metadata` : `jsonb`, `null: false`, default `{}`
- `created_at` : `datetime`, `null: false`
- `updated_at` : `datetime`, `null: false`

Indexes:
- `index_expense_audit_logs_on_action`
- `index_expense_audit_logs_on_actor` (`actor_type`, `actor_id`)
- `index_expense_audit_logs_on_created_at`
- `index_expense_audit_logs_on_expense_id`

Notes:
- `actor` is a polymorphic association (`actor_type` + `actor_id`)
- `metadata` stores structured event-specific details (JSONB)

## Foreign Keys

- `expenses.user_id -> users.id`
- `expenses.reviewer_id -> users.id` (column: `reviewer_id`)
- `expenses.category_id -> categories.id`
- `expense_audit_logs.expense_id -> expenses.id` with `on_delete: :nullify`

## Associations (Code + Schema Alignment)

- `User`
  - has many owned expenses via `expenses.user_id`
  - has many review assignments via `expenses.reviewer_id` (nullable on delete)
- `Expense`
  - belongs to owner `user`
  - belongs to `reviewer` (optional)
  - belongs to `category` (optional)
  - has many `audit_logs`
- `Category`
  - has many `expenses`
- `ExpenseAuditLog`
  - belongs to `expense` (optional)
  - belongs to `actor`, polymorphic

## Audit Log Persistence Behavior

Audit logs persist even if an expense is deleted:
- The foreign key on `expense_audit_logs.expense_id` uses `on_delete: :nullify`
- Result: deleting an expense sets `expense_id` on related audit log rows to `NULL`
- This preserves historical audit records while removing the expense row

## `lock_version` Usage (Optimistic Locking)

- `expenses.lock_version` is an integer incremented by Rails on successful updates
- Clients can send `lock_version` in expense updates
- If the submitted version is stale, Rails raises `ActiveRecord::StaleObjectError`
- `ApplicationController` rescues this and returns `409` with `{"errors":["stale_object"]}`
