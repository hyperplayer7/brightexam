# AGENTS.md

## Project Overview

This is a monorepo containing:

- `api/` → Ruby on Rails API-only backend
- `web/` → Next.js (App Router, JavaScript) frontend

The system is an Expense Tracker with:
- Employee role (create/edit/submit)
- Reviewer role (approve/reject)
- State flow: drafted → submitted → approved | rejected

Authentication:
- Cookie-based session auth
- Frontend must use `credentials: "include"` for all requests

Authorization:
- Pundit policies enforce permissions
- Service objects enforce workflow transitions

---

## Folder Structure
api/ # Rails backend
web/ # Next.js frontend


### Backend (`api/`)

Important paths:

- Controllers: `api/app/controllers/api/`
- Policies: `api/app/policies/`
- Services: `api/app/services/expenses/`
- Models: `api/app/models/`
- Specs: `api/spec/`

Routes are namespaced under `/api`.

Example endpoints:
- POST /api/login
- GET /api/me
- GET /api/expenses
- POST /api/expenses/:id/submit
- POST /api/expenses/:id/approve
- POST /api/expenses/:id/reject

---

### Frontend (`web/`)

App Router structure:
web/src/app/
login/
expenses/
new/
[id]/
[id]/edit/


API client is located at:
web/src/lib/api.js


All fetch requests MUST:
- Use `credentials: "include"`
- Send JSON when body exists
- Handle non-2xx responses gracefully

---

## Development Commands

### Backend

From `api/`:
bundle install
bin/rails db:prepare
bin/rails s


Run tests:

bundle exec rspec


---

### Frontend

From `web/`:
npm install
npm run dev


Build:

npm run build


---

## Coding Guidelines

### Backend

- Keep controllers thin
- Business logic must live in service objects
- Authorization rules belong in Pundit policies
- Use enums for status and role
- Always validate transitions
- Return proper HTTP status codes:
  - 401 → unauthenticated
  - 403 → forbidden
  - 422 → invalid request

Do NOT move business logic into controllers.

---

### Frontend

- Do not duplicate backend rules in frontend
- UI should conditionally render buttons based on role + status
- Handle 401 globally → redirect to /login
- Do not hardcode API URLs outside api.js

---

## Workflow Rules (Critical)

Expense transitions:

- Only owner can edit/delete while drafted
- Only owner can submit while drafted
- Only reviewer can approve/reject while submitted
- Submitted/approved/rejected cannot be edited

These rules must not be broken.

---

## When Making Changes

- Do not change API response shape unless necessary.
- Keep pagination format consistent:
  {
    data: [],
    pagination: { page, pages, count, items }
  }

- If adding new features, update:
  - README
  - Specs
  - API documentation

---

## AI Tool Usage Policy

When generating code:
- Do not refactor unrelated files.
- Follow existing folder structure.
- Prefer explicit Ruby over metaprogramming.
- Prefer clarity over cleverness.