# Expense Tracker (Rails API + Next.js)

This repository contains a full-stack Expense Tracker implementation with role-based workflows for employees and reviewers. Employees create and submit expenses; reviewers approve or reject submitted items with a reason.

The stack is split into a Rails API backend and a Next.js App Router frontend that consumes JSON endpoints using cookie-based authentication.

## Documentation Bundle

- [Feature Specs](docs/FEATURE_SPECS.md)
- [API Reference](docs/API.md)
- [Database Schema](docs/DB_SCHEMA.md)
- [Trade-offs](docs/TRADE_OFFS.md)
- [AI Usage Disclosure](docs/AI_USAGE.md)

## Tech Stack

- Ruby on Rails (API-only)
- PostgreSQL
- Pundit
- Pagy
- RSpec
- RuboCop (`rubocop-rails-omakase`)
- Next.js (App Router, JavaScript)
- Tailwind CSS

## Repository Structure

```text
.
├── app/ / config/ / db/ ...    # Rails API backend (current checkout location)
├── web/                        # Next.js frontend
└── docs/                       # Submission documentation bundle
```

Note: If your target environment uses `api/` for backend, treat the Rails root files in this repo as that backend source.

## macOS Setup

### 1) Backend setup (Rails + PostgreSQL)

Prerequisites:
- Ruby (recommended via `rbenv` or `asdf`)
- Bundler
- PostgreSQL

```bash
brew install postgresql
brew services start postgresql
```

Install and prepare backend:

```bash
bundle install
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
bin/rails s
```

Backend URL: `http://localhost:3000`

### 2) Frontend setup (Next.js)

```bash
cd web
npm install
npm run dev
```

Frontend URL: `http://localhost:3001` (or next available port)

## Seed/Test Users (Current Project Configuration)

From `db/seeds.rb`:

- `employee@test.com` / `password` (employee)
- `reviewer@test.com` / `password` (reviewer)
- `employee2@test.com` / `password` (employee)
- `employee3@test.com` / `password` (employee)
- `reviewer2@test.com` / `password` (reviewer)

## Manual Test Plan

### Employee flow
1. Login as `employee@test.com`.
2. Create a new expense draft.
3. Edit the draft expense.
4. Submit the draft.
5. Confirm status changes to `submitted`.

### Reviewer flow
1. Logout and login as `reviewer@test.com`.
2. Open a submitted expense.
3. Approve it, or reject with a rejection reason.
4. Confirm final status (`approved`/`rejected`) and reviewer metadata.

## Run Tests and Lint

Backend (Rails):

```bash
bundle exec rspec
bundle exec rubocop
```

Frontend (Next.js):

```bash
cd web
npm run build
npm run lint
```

## API Summary

Auth:
- `POST /api/login`
- `POST /api/logout`
- `GET /api/me`

Expenses:
- `GET /api/expenses`
- `GET /api/expenses/summary`
- `GET /api/expenses/:id`
- `POST /api/expenses`
- `PATCH /api/expenses/:id`
- `DELETE /api/expenses/:id`
- `POST /api/expenses/:id/submit`
- `POST /api/expenses/:id/approve`
- `POST /api/expenses/:id/reject`

See full details in [docs/API.md](docs/API.md).
