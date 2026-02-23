# Feature Specs (Current Implementation)

Source of truth: Rails routes/controllers/policies/models/services, frontend pages/components, and `db/schema.rb`.

## Roles

- `employee`
- `reviewer`

## Implemented Backend Features

### Authentication / Session
- `POST /api/login`
- `POST /api/logout`
- `GET /api/me`
- Cookie-based session auth with `HttpOnly` session cookie

### Expenses (CRUD + Workflow)
- List expenses (`GET /api/expenses`) with:
  - policy-scoped visibility
  - optional `status` filter
  - optional `category_id` filter
  - server pagination
- Expense detail (`GET /api/expenses/:id`)
- Create draft expense (`POST /api/expenses`) for employees only
- Update expense (`PATCH /api/expenses/:id`) for owner on drafted expenses only
- Delete expense (`DELETE /api/expenses/:id`) for owner on drafted expenses only
- Submit expense (`POST /api/expenses/:id/submit`)
- Approve expense (`POST /api/expenses/:id/approve`)
- Reject expense (`POST /api/expenses/:id/reject`) with `rejection_reason`

### Summary Analytics
- `GET /api/expenses/summary`
- Policy-scoped by role (employee own data / reviewer all data)
- Returns:
  - all-time count and totals by currency
  - counts by status
  - monthly aggregates (month/currency/count/amount_cents)

### Audit Logs
- Expense actions are persisted in `expense_audit_logs`
- `GET /api/expenses/:id/audit_logs` returns logs for an authorized expense
- Audit logs remain after expense deletion (`expense_id` nullable with FK `on_delete: :nullify`)

### Categories
- `GET /api/categories` for any authenticated user
- `POST /api/categories` reviewer-only
- Categories RBAC enforced via Pundit (`CategoryPolicy#index?`, `CategoryPolicy#create?`)
- Category names are normalized (trimmed) and unique (case-insensitive app validation)

### User Role Management
- `GET /api/users` reviewer-only
- `PATCH /api/users/:id/role` reviewer-only
- Allowed roles validated against `User.roles.keys`
- Reviewer cannot change their own role (returns `422`)

## Implemented Frontend Features

### Shared UI / Navigation
- Header navigation with:
  - account email/role display
  - theme selector
  - logout button
- Reviewer-only nav links for:
  - Categories
  - Users

### Theme System
- Themes: `light`, `dark`, `stephens`, `up`
- Implemented using CSS variables + `data-theme` attribute
- Stored in `localStorage`
- Defaults to stored theme, else prefers dark mode, else light

### Expenses List UI (`/expenses`)
- Fetches current user, expenses, categories, and summary
- Filters:
  - status (server-side)
  - category (server-side)
  - search by merchant/description (client-side, current page only)
- Pagination controls using API pagination response
- Summary cards for all-time and current-month totals

### Expense Detail UI (`/expenses/:id`)
- Displays expense details, status, reviewer, category
- Displays audit logs
- Role/status-based actions:
  - owner employee draft: edit/delete/submit
  - reviewer submitted: approve/reject

### Expense Create/Edit UI
- Create draft page (`/expenses/new`) for employees
- Edit page (`/expenses/:id/edit`) for owner drafted expense only
- Category selection in forms (optional)
- Uses `lock_version` on update (optimistic locking)

### Categories UI (`/categories`)
- Reviewer-only management page (frontend access gating + backend auth still applies)
- Category list display
- Add category form
- Create request uses backend payload contract: `{ category: { name } }`
- Validation error display for create attempts
- Created column is shown only if timestamp data is present in API payload

### Users UI (`/users`)
- Reviewer-only page (frontend access gating + backend auth still applies)
- Users table with email/current role/created timestamp
- Per-row role dropdown + save button
- Success/error message per row

### Frontend Auth/Error Handling (Protected Pages)
- Protected pages (`/expenses`, `/categories`, `/users`) use shared auth helpers
- `401` API errors redirect to `/login`
- `403` API errors render a shared forbidden state UI with a link back to `/expenses`
- Shared forbidden UI component: `ForbiddenState`

## Behavior Constraints (Implemented)

- Reviewer cannot create expenses (policy + frontend UI guard)
- Employee cannot approve/reject expenses
- Employee cannot edit/delete/submit after submission
- Reject requires nonblank `rejection_reason`
- Expense ownership is backend-controlled (`current_user.expenses.new`)
- Expense updates use optimistic locking (`lock_version`)

## Optional Enhancements (Not Implemented; marked explicitly)

- Backend validation for allowed currency values (frontend currently limits options only)
- API versioning (e.g. `/api/v1`)
- Automated frontend tests (component/e2e)
- Shared API serializers / typed contracts between backend and frontend
