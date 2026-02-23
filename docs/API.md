# API Reference

Source of truth: `config/routes.rb`, `app/controllers/application_controller.rb`, `app/controllers/api/*.rb`.

Base URL (local): `http://localhost:3000`

Auth model:
- Session cookie (`HttpOnly`) set by login.
- Protected endpoints require authenticated session.

Error envelope:
- Common errors use: `{ "errors": ["..."] }`
- Validation errors may return model full messages in the same `errors` array.

## Auth Endpoints

### POST `/api/login`
- Auth required: No
- Role rules: Any user with valid credentials

Request body:
```json
{
  "email": "employee@test.com",
  "password": "password"
}
```

Success response `200`:
```json
{
  "data": {
    "id": 1,
    "email": "employee@test.com",
    "role": "employee"
  }
}
```

Error cases:
- `401` invalid credentials
```json
{ "errors": ["invalid_credentials"] }
```

---

### POST `/api/logout`
- Auth required: Yes
- Role rules: Any authenticated role

Request body: none

Success response `204`:
- No body

Error cases:
- `401` not logged in
```json
{ "errors": ["unauthorized"] }
```

---

### GET `/api/me`
- Auth required: Yes
- Role rules: Any authenticated role

Request body: none

Success response `200`:
```json
{
  "data": {
    "id": 1,
    "email": "employee@test.com",
    "role": "employee"
  }
}
```

Error cases:
- `401` not logged in
```json
{ "errors": ["unauthorized"] }
```

## Category Endpoints

### GET `/api/categories`
- Auth required: Yes
- Role rules: any authenticated user

Request body: none

Success response `200`:
```json
{
  "data": [
    { "id": 1, "name": "Meals" },
    { "id": 2, "name": "Supplies" },
    { "id": 3, "name": "Transport" }
  ]
}
```

Error cases:
- `401` unauthenticated
```json
{ "errors": ["unauthorized"] }
```

---

### POST `/api/categories`
- Auth required: Yes
- Role rules: reviewer only

Request body:
```json
{
  "category": {
    "name": "Internet"
  }
}
```

Success response `201`:
```json
{
  "data": { "id": 4, "name": "Internet" }
}
```

Error cases:
- `401` unauthenticated
- `403` forbidden
- `422` validation failure
```json
{ "errors": ["unauthorized"] }
{ "errors": ["forbidden"] }
{ "errors": ["Name has already been taken"] }
```

## Expense Endpoints

Expense payload shape used by controllers:
```json
{
  "id": 1,
  "user_id": 1,
  "reviewer_id": null,
  "category": { "id": 1, "name": "Transport" },
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

### GET `/api/expenses`
- Auth required: Yes
- Role rules:
  - employee: own expenses only
  - reviewer: all expenses
- Query params:
  - `status` (optional; only applied if valid enum key)
  - `category_id` (optional; filter by category)
  - `page` (optional; Pagy)

Request body: none

Success response `200`:
```json
{
  "data": [
    {
      "id": 1,
      "user_id": 1,
      "reviewer_id": null,
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
  ],
  "pagination": {
    "page": 1,
    "pages": 1,
    "count": 1,
    "items": 20
  }
}
```

Error cases:
- `401` unauthenticated
```json
{ "errors": ["unauthorized"] }
```

---

### GET `/api/expenses/summary`
- Auth required: Yes
- Role rules:
  - employee: own expenses only (via policy scope)
  - reviewer: all expenses (via policy scope)

Request body: none

Success response `200`:
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

Error cases:
- `401` unauthenticated
```json
{ "errors": ["unauthorized"] }
```

---

### GET `/api/expenses/:id`
- Auth required: Yes
- Role rules:
  - employee: own expense only
  - reviewer: any expense

Request body: none

Success response `200`:
```json
{
  "data": {
    "id": 1,
    "user_id": 1,
    "reviewer_id": null,
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
}
```

Error cases:
- `401` unauthenticated
- `403` forbidden by policy
- `404` expense not found
```json
{ "errors": ["unauthorized"] }
{ "errors": ["forbidden"] }
{ "errors": ["not_found"] }
```

---

### POST `/api/expenses`
- Auth required: Yes
- Role rules: employee only

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

Success response `201`:
```json
{
  "data": {
    "id": 1,
    "user_id": 1,
    "reviewer_id": null,
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
}
```

Error cases:
- `401` unauthenticated
- `403` reviewer attempting create
- `422` validation failure
```json
{ "errors": ["unauthorized"] }
{ "errors": ["forbidden"] }
{ "errors": ["Amount cents must be greater than 0"] }
```

---

### PATCH `/api/expenses/:id`
- Auth required: Yes
- Role rules: owner employee and status must be `drafted`

Request body:
```json
{
  "expense": {
    "amount_cents": 175000,
    "currency": "PHP",
    "description": "Updated description",
    "merchant": "Airline",
    "incurred_on": "2026-02-20",
    "category_id": 2,
    "lock_version": 0
  }
}
```

Success response `200`:
```json
{
  "data": {
    "id": 1,
    "user_id": 1,
    "reviewer_id": null,
    "amount_cents": 175000,
    "currency": "PHP",
    "description": "Updated description",
    "merchant": "Airline",
    "incurred_on": "2026-02-20",
    "status": "drafted",
    "submitted_at": null,
    "reviewed_at": null,
    "rejection_reason": null,
    "lock_version": 1,
    "created_at": "2026-02-20T10:00:00.000Z",
    "updated_at": "2026-02-20T10:05:00.000Z"
  }
}
```

Error cases:
- `401` unauthenticated
- `403` forbidden by policy
- `404` not found
- `422` validation failure
```json
{ "errors": ["unauthorized"] }
{ "errors": ["forbidden"] }
{ "errors": ["not_found"] }
{ "errors": ["Amount cents must be greater than 0"] }
```

---

### DELETE `/api/expenses/:id`
- Auth required: Yes
- Role rules: owner employee and status must be `drafted`

Request body: none

Success response `204`:
- No body

Error cases:
- `401` unauthenticated
- `403` forbidden
- `404` not found
```json
{ "errors": ["unauthorized"] }
{ "errors": ["forbidden"] }
{ "errors": ["not_found"] }
```

---

### POST `/api/expenses/:id/submit`
- Auth required: Yes
- Role rules: owner employee and status must be `drafted`

Request body: none

Success response `200`:
```json
{
  "data": {
    "id": 1,
    "user_id": 1,
    "reviewer_id": null,
    "amount_cents": 150000,
    "currency": "PHP",
    "description": "Flight to client site",
    "merchant": "Airline",
    "incurred_on": "2026-02-20",
    "status": "submitted",
    "submitted_at": "2026-02-20T11:00:00.000Z",
    "reviewed_at": null,
    "rejection_reason": null,
    "lock_version": 1,
    "created_at": "2026-02-20T10:00:00.000Z",
    "updated_at": "2026-02-20T11:00:00.000Z"
  }
}
```

Error cases:
- `401` unauthenticated
- `403` forbidden
- `404` not found
- `422` invalid transition
```json
{ "errors": ["unauthorized"] }
{ "errors": ["forbidden"] }
{ "errors": ["not_found"] }
{ "errors": ["Status must be drafted to submit"] }
```

---

### POST `/api/expenses/:id/approve`
- Auth required: Yes
- Role rules: reviewer only, expense must be `submitted`

Request body: none

Success response `200`:
```json
{
  "data": {
    "id": 1,
    "user_id": 1,
    "reviewer_id": 2,
    "amount_cents": 150000,
    "currency": "PHP",
    "description": "Flight to client site",
    "merchant": "Airline",
    "incurred_on": "2026-02-20",
    "status": "approved",
    "submitted_at": "2026-02-20T11:00:00.000Z",
    "reviewed_at": "2026-02-20T12:00:00.000Z",
    "rejection_reason": null,
    "lock_version": 2,
    "created_at": "2026-02-20T10:00:00.000Z",
    "updated_at": "2026-02-20T12:00:00.000Z"
  }
}
```

Error cases:
- `401` unauthenticated
- `403` forbidden
- `404` not found
- `422` invalid transition
```json
{ "errors": ["unauthorized"] }
{ "errors": ["forbidden"] }
{ "errors": ["not_found"] }
{ "errors": ["Status must be submitted to approve"] }
```

---

### POST `/api/expenses/:id/reject`
- Auth required: Yes
- Role rules: reviewer only, expense must be `submitted`

Request body:
```json
{
  "rejection_reason": "Missing receipt"
}
```

Success response `200`:
```json
{
  "data": {
    "id": 1,
    "user_id": 1,
    "reviewer_id": 2,
    "amount_cents": 150000,
    "currency": "PHP",
    "description": "Flight to client site",
    "merchant": "Airline",
    "incurred_on": "2026-02-20",
    "status": "rejected",
    "submitted_at": "2026-02-20T11:00:00.000Z",
    "reviewed_at": "2026-02-20T12:00:00.000Z",
    "rejection_reason": "Missing receipt",
    "lock_version": 2,
    "created_at": "2026-02-20T10:00:00.000Z",
    "updated_at": "2026-02-20T12:00:00.000Z"
  }
}
```

Error cases:
- `401` unauthenticated
- `403` forbidden
- `404` not found
- `422` invalid transition or missing rejection reason
```json
{ "errors": ["unauthorized"] }
{ "errors": ["forbidden"] }
{ "errors": ["not_found"] }
{ "errors": ["Rejection reason can't be blank"] }
```

## Non-business health endpoint

### GET `/up`
- Auth required: No
- Role rules: N/A
- Response: Rails health check payload (framework-defined)
- Notes: response shape `TBD` (not defined in local app controllers)
