# Expense Tracker (Rails API + Next.js)

Expense Tracker is a full-stack app with a Rails API backend and a Next.js App Router frontend.
It supports employee expense submission and reviewer approval/rejection workflows using cookie-based session authentication.

## Architecture Overview

- Backend: Rails API-only app (`app/controllers/api/*`) with PostgreSQL, Pundit, Pagy, and RSpec
- Frontend: Next.js App Router (`web/src/app/*`) with Tailwind CSS and client-side API calls
- Auth: Rails session cookie (`HttpOnly`) + frontend `fetch(..., { credentials: "include" })`
- Authorization: Pundit policies for expenses, categories, and users
- Audit trail: Expense actions are recorded in `expense_audit_logs`

## Implemented Feature Summary (Current Code)

- Session auth endpoints: login / logout / me
- Expense list/detail/create/edit/delete (role- and status-constrained)
- Expense workflow transitions: submit / approve / reject
- Expense audit log endpoint and UI display
- Expense summary analytics endpoint and summary cards in frontend
- Categories:
  - list endpoint for authenticated users
  - create endpoint for reviewers (`POST /api/categories`)
  - reviewer-facing categories page (list + add form)
- User role management:
  - reviewer-only users list endpoint
  - reviewer-only role update endpoint
  - reviewer-facing users page with per-row role save
- Frontend filtering:
  - server-side status/category filters
  - client-side text search (merchant/description, current page only)
- Theme system with 4 themes (`light`, `dark`, `stephens`, `up`)
- Optimistic locking on expense updates via `lock_version`

## Roles and Permissions (Summary)

- `employee`
  - can create expenses
  - can view only own expenses
  - can edit/delete/submit only own `drafted` expenses
  - cannot approve/reject expenses
  - cannot manage categories or user roles

- `reviewer`
  - can view all expenses
  - can approve/reject `submitted` expenses
  - cannot create/update/delete/submit employee expenses
  - can create categories (reviewer-only)
  - can list users and update user roles (except own role)

## Workflow State Diagram

```text
drafted -> submitted -> approved
                   -> rejected
```

Transition rules (backend-enforced):
- `submit`: owner employee + expense is `drafted`
- `approve`: reviewer + expense is `submitted`
- `reject`: reviewer + expense is `submitted` + rejection reason required

## Setup (Verified Against Current App)

### Backend (Rails API)

Prerequisites:
- Ruby + Bundler
- PostgreSQL

```bash
bundle install
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
bin/rails s
```

Backend URL (default): `http://localhost:3000`

### Frontend (Next.js)

```bash
cd web
npm install
npm run dev
```

Frontend URL (default): `http://localhost:3001`

## Seeded Sample Users (`db/seeds.rb`)

- `employee@test.com` / `password` (`employee`)
- `reviewer@test.com` / `password` (`reviewer`)
- `employee2@test.com` / `password` (`employee`)
- `employee3@test.com` / `password` (`employee`)
- `reviewer2@test.com` / `password` (`reviewer`)

Seeded categories:
- `Transport`
- `Meals`
- `Supplies`

## Test + Lint Commands

Backend:

```bash
bundle exec rspec
bundle exec rubocop
```

Frontend:

```bash
cd web
npm run build
npm run lint
```

## Theme System Notes (Frontend)

- Theme selection is available in the header nav.
- Themes are stored in `localStorage` (`theme` key).
- Supported themes: `light`, `dark`, `stephens`, `up`.
- Theme values are applied through CSS variables on `document.documentElement.dataset.theme`.

## Pagination Notes

- Expense list pagination is server-driven (`GET /api/expenses?page=...`)
- Current implementation returns **5 expenses per page** (controller passes `limit: 5`)
- Frontend renders Previous/Next controls using the API `pagination` object
- Frontend search is applied **after** pagination on the current page only

## Summary Analytics Notes

- Frontend calls `GET /api/expenses/summary` (best-effort; UI continues if summary fails)
- Summary is policy-scoped:
  - employees see only their own totals
  - reviewers see aggregate totals across users
- Response includes:
  - `all_time` count + totals by currency
  - `by_status` counts
  - `monthly` grouped totals/counts (last ~6 months window based on current month)

## Authentication + CORS Notes

- Rails API uses cookie-based session auth in API mode (cookies/session middleware re-enabled)
- Frontend API client always sends `credentials: "include"`
- Frontend pages that require auth (`/expenses`, `/categories`, `/users`) use consistent handling:
  - `401` -> redirect to `/login`
  - `403` -> render a shared forbidden state with a link back to `/expenses`
- CORS currently allows:
  - `http://localhost:3001`
  - `http://127.0.0.1:3001`

## Categories (API + UI Notes)

- `GET /api/categories` is available to any authenticated user.
- `POST /api/categories` is reviewer-only (enforced by `CategoryPolicy` + controller authorization).
- Category create request body uses nested payload shape:
  - `{ "category": { "name": "Internet" } }`
- Reviewer `/categories` UI uses the same payload shape via `createCategory()`.

## Frontend API Base URL Configuration

- The frontend API client reads `NEXT_PUBLIC_API_BASE_URL`.
- If not set, it falls back to `http://localhost:3000`.
- Example for local/dev shells:
  - `NEXT_PUBLIC_API_BASE_URL=http://localhost:3000`
