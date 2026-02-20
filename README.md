# Expense Tracker (Monorepo)

This project is a full-stack Expense Tracker built as a take-home style application. It supports two roles (`employee` and `reviewer`) and a workflow for drafting, submitting, approving, and rejecting expenses.

The repository is organized as a monorepo with a Rails API backend and a Next.js frontend. Authentication is cookie-based, authorization is policy-driven, and the frontend consumes the backend API directly.

## Tech Stack

- Backend: Ruby on Rails (API-only)
- Database: PostgreSQL
- Authorization: Pundit
- Pagination: Pagy
- Testing: RSpec
- Linting: RuboCop (`rubocop-rails-omakase`)
- Frontend: Next.js (App Router, JavaScript)
- Styling: Tailwind CSS

## Folder Structure

```text
.
├── api/   # Rails API-only backend
└── web/   # Next.js App Router frontend
```

## Backend Setup (macOS-friendly)

1. Install prerequisites:
   - Ruby (recommended via `rbenv` or `asdf`)
   - Bundler
   - PostgreSQL (Homebrew)

```bash
brew install postgresql
brew services start postgresql
```

2. Configure the backend:

```bash
cd api
bundle install
```

3. Set database credentials in `api/config/database.yml` (or environment variables), then run:

```bash
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
```

4. Start the backend API:

```bash
bin/rails s
```

The backend runs at `http://localhost:3000`.

## Frontend Setup

```bash
cd web
npm install
npm run dev
```

The frontend runs at `http://localhost:3001` (or next available port) and expects the backend at `http://localhost:3000`.

## Seed Users

- Employee:
  - Email: `employee@test.com`
  - Password: `password`
- Reviewer:
  - Email: `reviewer@test.com`
  - Password: `password`

## Manual Test Workflow

### Employee Flow

1. Login as `employee@test.com`.
2. Create a new expense (draft).
3. Open the draft detail page.
4. Edit the draft.
5. Submit the expense.
6. Confirm status changes to `submitted`.

### Reviewer Flow

1. Logout and login as `reviewer@test.com`.
2. Open a submitted expense.
3. Approve it, or reject it with a rejection reason.
4. Confirm status transitions and review metadata are updated.

## API Endpoint Summary

### Auth

- `POST /api/login`
- `POST /api/logout`
- `GET /api/me`

### Expenses

- `GET /api/expenses`
- `GET /api/expenses/:id`
- `POST /api/expenses`
- `PATCH /api/expenses/:id`
- `DELETE /api/expenses/:id`
- `POST /api/expenses/:id/submit`
- `POST /api/expenses/:id/approve`
- `POST /api/expenses/:id/reject`

## Architecture Notes

- Expense state transitions are handled by service objects (submit/approve/reject) to keep controllers thin and business rules centralized.
- Authorization decisions are isolated in Pundit policies.
- This separation makes state logic easier to test and reason about, while keeping HTTP/controller concerns focused on request/response handling.

## Trade-offs

- Session cookie auth is simple and secure for this scope, but less flexible than token-based auth for third-party/mobile clients.
- The API returns direct JSON structures without an abstraction layer (serializer classes), which reduces complexity but can become harder to evolve as payloads grow.
- Workflow logic is explicit and readable, but adding many more states may benefit from a formal state machine library.

## AI Tool Usage Disclosure

Parts of this project were developed with AI coding assistance.  
All generated code, architecture choices, and behaviors were reviewed and adjusted to match the assignment requirements.
