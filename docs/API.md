# API Reference (Current Implementation)

Source of truth:
- `config/routes.rb`
- `app/controllers/application_controller.rb`
- `app/controllers/api/*.rb`
- `app/policies/*.rb`
- `app/services/expenses/*.rb`

Base URL (local): `http://localhost:3000`

Frontend API base URL config:
- `web/src/lib/api.js` reads `NEXT_PUBLIC_API_BASE_URL`
- Falls back to `http://localhost:3000` when unset

## Authentication Model

- Rails session cookie auth (`HttpOnly`)
- Frontend uses `fetch(..., { credentials: "include" })`
- Protected endpoints require authenticated session (`authenticate_user!`)

## Common Response Patterns

### Success envelope (most endpoints)
```json
{ "data": ... }
```

### Error envelope
```json
{ "errors": ["..."] }
```

## Common Status Codes Used

- `200 OK`
- `201 Created`
- `204 No Content`
- `400 Bad Request` (e.g., missing required parameter wrapper)
- `401 Unauthorized`
- `403 Forbidden`
- `404 Not Found`
- `409 Conflict` (optimistic locking / stale object)
- `422 Unprocessable Entity`

---

## Auth Endpoints

### POST `/api/login`

Auth required: No

Request body:
```json
{
  "email": "employee@test.com",
  "password": "password"
}
```

Success `200`:
```json
{
  "data": {
    "id": 1,
    "email": "employee@test.com",
    "role": "employee"
  }
}
```

Errors:
- `401` invalid credentials
```json
{ "errors": ["invalid_credentials"] }
```

### POST `/api/logout`

Auth required: Yes

Success `204`: no body

Errors:
- `401`
```json
{ "errors": ["unauthorized"] }
```

### GET `/api/me`

Auth required: Yes

Success `200`:
```json
{
  "data": {
    "id": 1,
    "email": "employee@test.com",
    "role": "employee"
  }
}
```

Errors:
- `401`
```json
{ "errors": ["unauthorized"] }
```

---

## Category Endpoints

### GET `/api/categories`

Auth required: Yes
Role rules: any authenticated user (`CategoryPolicy#index?`)

Success `200`:
```json
{
  "data": [
    { "id": 1, "name": "Meals" },
    { "id": 2, "name": "Supplies" },
    { "id": 3, "name": "Transport" }
  ]
}
```

Errors:
- `401`

### POST `/api/categories`

Auth required: Yes
Role rules: reviewer only (`CategoryPolicy#create?`)

Request body (nested `category` payload):
```json
{
  "category": {
    "name": "Internet"
  }
}
```

Success `201`:
```json
{
  "data": {
    "id": 4,
    "name": "Internet"
  }
}
```

Errors:
- `401` unauthenticated
- `403` non-reviewer
- `400` missing `category` param wrapper (ParameterMissing)
- `422` validation errors (e.g. duplicate name)

Examples:
```json
{ "errors": ["unauthorized"] }
{ "errors": ["forbidden"] }
{ "errors": ["param is missing or the value is empty or invalid: category"] }
{ "errors": ["Name has already been taken"] }
```

Authorization notes:
- `authenticate_user!` returns `401` for unauthenticated requests
- Pundit authorization returns `403` for authenticated non-reviewers

---

## User Management / Role Assignment Endpoints

### GET `/api/users`

Auth required: Yes
Role rules: reviewer only (Pundit `UserPolicy#index?`)

Success `200`:
```json
{
  "data": [
    {
      "id": 1,
      "email": "employee@test.com",
      "role": "employee",
      "created_at": "2026-02-20T10:00:00.000Z"
    }
  ]
}
```

Errors:
- `401`
- `403`

### PATCH `/api/users/:id/role`

Auth required: Yes
Role rules: reviewer only (Pundit `UserPolicy#update_role?`)

Request body:
```json
{
  "role": "reviewer"
}
```

Allowed roles:
- `employee`
- `reviewer`

Success `200`:
```json
{
  "data": {
    "id": 2,
    "email": "employee@test.com",
    "role": "reviewer"
  }
}
```

Errors:
- `401` unauthenticated
- `403` non-reviewer
- `404` user not found
- `422` invalid role
- `422` reviewer attempting to change own role

Examples:
```json
{ "errors": ["forbidden"] }
{ "errors": ["not_found"] }
{ "errors": ["role must be one of: employee, reviewer"] }
{ "errors": ["cannot_change_own_role"] }
```

---

## Expense Endpoints

## Expense Payload Shape (Controller Output)

Returned by expense list/detail and workflow endpoints:

```json
{
  "id": 1,
  "user_id": 1,
  "reviewer_id": null,
  "user": {
    "id": 1,
    "email": "employee@test.com",
    "role": "employee"
  },
  "reviewer": null,
  "category": {
    "id": 3,
    "name": "Transport"
  },
  "amount_cents": 150000,
  "currency": "PHP",
  "description": "Flight to client site",
  "merchant": "Airline",
  "incurred_on": "2026-02-20",
  "status": "drafted",
  "submitted_at": null,
  "reviewed_at": null,
  "rejection_reason": null,
  "lock_version": 0,
  "created_at": "2026-02-20T10:00:00.000Z",
  "updated_at": "2026-02-20T10:00:00.000Z"
}
```

Notes:
- `reviewer` and `category` may be `null`
- `user`, `reviewer`, and `category` are nested objects (when present)

### GET `/api/expenses`

Auth required: Yes
Role rules:
- employee: own expenses only (`policy_scope`)
- reviewer: all expenses (`policy_scope`)

Query params (optional):
- `page`
- `status` (applied only if valid enum value)
- `category_id`

Current server page size:
- `5` per page (controller-level `limit: 5`)

Success `200`:
```json
{
  "data": [
    {
      "id": 1,
      "user_id": 1,
      "reviewer_id": null,
      "user": { "id": 1, "email": "employee@test.com", "role": "employee" },
      "reviewer": null,
      "category": null,
      "amount_cents": 1000,
      "currency": "USD",
      "description": "Ride",
      "merchant": "Grab",
      "incurred_on": "2026-02-20",
      "status": "drafted",
      "submitted_at": null,
      "reviewed_at": null,
      "rejection_reason": null,
      "lock_version": 0,
      "created_at": "2026-02-20T10:00:00.000Z",
      "updated_at": "2026-02-20T10:00:00.000Z"
    }
  ],
  "pagination": {
    "page": 1,
    "pages": 1,
    "count": 1,
    "items": 5
  }
}
```

Errors:
- `401`

### GET `/api/expenses/summary`

Auth required: Yes
Role rules:
- employee: own expenses only (`policy_scope`)
- reviewer: all expenses (`policy_scope`)

Success `200`:
```json
{
  "data": {
    "all_time": {
      "count": 3,
      "totals": [
        { "currency": "PHP", "amount_cents": 175000 },
        { "currency": "USD", "amount_cents": 25000 }
      ]
    },
    "by_status": [
      { "status": "drafted", "count": 1 },
      { "status": "submitted", "count": 1 },
      { "status": "approved", "count": 1 },
      { "status": "rejected", "count": 0 }
    ],
    "monthly": [
      { "month": "2026-01", "currency": "PHP", "count": 1, "amount_cents": 75000 },
      { "month": "2026-02", "currency": "PHP", "count": 1, "amount_cents": 100000 },
      { "month": "2026-02", "currency": "USD", "count": 1, "amount_cents": 25000 }
    ]
  }
}
```

Errors:
- `401`

### GET `/api/expenses/:id`

Auth required: Yes
Role rules:
- employee: own expense only
- reviewer: any expense

Success `200`:
```json
{ "data": { "...": "expense payload shape above" } }
```

Errors:
- `401`
- `403`
- `404`

### POST `/api/expenses`

Auth required: Yes
Role rules: employee only (`ExpensePolicy#create?`)

Request body:
```json
{
  "expense": {
    "amount_cents": 150000,
    "currency": "PHP",
    "description": "Flight to client site",
    "merchant": "Airline",
    "incurred_on": "2026-02-20",
    "category_id": 1
  }
}
```

Notes:
- Backend ignores client ownership fields because payload is built from `current_user.expenses.new(...)`
- Strong params do not permit `user_id`, `reviewer_id`, `status`, `submitted_at`, `reviewed_at`

Success `201`:
```json
{ "data": { "...": "expense payload shape above" } }
```

Errors:
- `401`
- `403`
- `400` missing `expense` wrapper
- `422` validation errors

### PATCH `/api/expenses/:id`

Auth required: Yes
Role rules:
- owner employee + drafted expense only (`ExpensePolicy#update?`)

Request body:
```json
{
  "expense": {
    "description": "Updated description",
    "lock_version": 0
  }
}
```

Permitted attributes:
- `amount_cents`
- `currency`
- `description`
- `merchant`
- `incurred_on`
- `category_id`
- `lock_version`

Success `200`:
```json
{ "data": { "...": "expense payload shape above" } }
```

Errors:
- `401`
- `403`
- `404`
- `400` missing `expense` wrapper
- `409` stale optimistic lock (`stale_object`)
- `422` validation errors

Example `409`:
```json
{ "errors": ["stale_object"] }
```

### DELETE `/api/expenses/:id`

Auth required: Yes
Role rules:
- owner employee + drafted expense only (`ExpensePolicy#destroy?`)

Success `204`: no body

Errors:
- `401`
- `403`
- `404`

### POST `/api/expenses/:id/submit`

Auth required: Yes
Role rules:
- owner employee + drafted expense only (`ExpensePolicy#submit?`)

Request body: none

Success `200`:
```json
{ "data": { "...": "expense payload shape above" } }
```

Errors:
- `401`
- `403`
- `404`
- `422` if transition service validation fails (TBD in request path due policy usually blocking first)

### POST `/api/expenses/:id/approve`

Auth required: Yes
Role rules:
- reviewer + submitted expense only (`ExpensePolicy#approve?`)

Request body: none

Success `200`:
```json
{ "data": { "...": "expense payload shape above" } }
```

Behavior:
- sets `status = approved`
- sets `reviewed_at`
- sets `reviewer_id` to current reviewer
- clears `rejection_reason`

Errors:
- `401`
- `403`
- `404`
- `422` if transition service validation fails (TBD in request path due policy usually blocking first)

### POST `/api/expenses/:id/reject`

Auth required: Yes
Role rules:
- reviewer + submitted expense only (`ExpensePolicy#reject?`)

Request body:
```json
{
  "rejection_reason": "Missing receipt"
}
```

Success `200`:
```json
{ "data": { "...": "expense payload shape above" } }
```

Behavior:
- sets `status = rejected`
- sets `reviewed_at`
- sets `reviewer_id` to current reviewer
- stores `rejection_reason`

Errors:
- `401`
- `403`
- `404`
- `422` validation error (e.g. missing rejection reason)

### GET `/api/expenses/:id/audit_logs`

Auth required: Yes
Role rules:
- same as expense `show?` (owner employee or reviewer)

Success `200`:
```json
{
  "data": [
    {
      "id": 10,
      "action": "expense.submitted",
      "from_status": "drafted",
      "to_status": "submitted",
      "metadata": {},
      "actor": {
        "id": 1,
        "email": "employee@test.com",
        "role": "employee"
      },
      "created_at": "2026-02-20T10:05:00.000Z"
    }
  ]
}
```

Notes:
- `metadata` may contain:
  - `previous_changes` (expense update)
  - `snapshot` (expense delete)
  - `rejection_reason` (reject action)
- Audit logs are ordered ascending by `created_at`

Errors:
- `401`
- `403`
- `404`

---

## Audit Logging (Behavior Summary)

Audit logs are created for:
- expense create (`expense.created`)
- expense update (`expense.updated`)
- expense delete (`expense.deleted`)
- submit (`expense.submitted`)
- approve (`expense.approved`)
- reject (`expense.rejected`)

Expense deletion does not remove audit records; `expense_id` is nulled by FK behavior (`on_delete: :nullify`).

---

## CORS / Session Notes (Current Config)

- Allowed CORS origins:
  - `http://localhost:3001`
  - `http://127.0.0.1:3001`
- Credentials enabled (`credentials: true`)
- Session cookie uses `HttpOnly` and `same_site: :lax`

If deployment origin differs from local defaults, update CORS and frontend API base URL accordingly.

---

## Health Endpoint

### GET `/up`

Auth required: No

Response:
- Rails health check response (framework-defined)
- Exact response body shape: `TBD` (not implemented in local app controllers)
