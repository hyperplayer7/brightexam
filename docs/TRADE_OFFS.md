# Trade-offs and Architectural Decisions (Current Implementation)

This document describes decisions reflected in the current codebase, not future design goals.

## 1) Rails API + Next.js Frontend Separation

Decision:
- Backend and frontend communicate over HTTP/JSON (`/api/*`).

Why:
- Keeps domain rules and authorization in Rails.
- Allows frontend iteration in Next.js without server-side Rails views.

Trade-off:
- API payload changes can break frontend pages if contracts drift.
- CORS + session-cookie behavior must be configured carefully.

Current evidence:
- Rails API controllers under `app/controllers/api/*`
- Next.js frontend under `web/src/*`

## 2) Simplified Authentication (Cookie Session in API Mode)

Decision:
- Use Rails session cookies (HttpOnly) instead of token/JWT auth.

Why:
- Simpler implementation for a single web frontend and API.
- Rails handles session lifecycle (`reset_session` on login/logout).

Trade-off:
- Cross-origin cookie + CORS setup requires coordination.
- CSRF strategy is simpler in localhost dev with `same_site: :lax`, but becomes more important if deployment topology changes.

Current implementation details:
- API mode with cookies/session middleware re-enabled
- Session cookie: `HttpOnly`, `same_site: :lax`
- CORS credentials enabled for local frontend origins

## 3) Authorization Split: Pundit + One Manual Check

Decision:
- Use Pundit for expense and user-role authorization.
- Category creation currently uses a direct reviewer check in controller.

Why:
- Pundit centralizes most role and ownership rules.
- Category create check is a smaller direct implementation.

Trade-off:
- Inconsistent authorization style across resources.
- Category auth rules are less discoverable/testable than policy-based rules.

## 4) Server-Driven Pagination (Expenses)

Decision:
- Expense list pagination is implemented in Rails using Pagy.

Why:
- Keeps response sizes bounded.
- Applies authorization and filters before pagination.
- Frontend can render pagination controls from API metadata.

Trade-off:
- Frontend search (see below) only searches the current page results, not all matching records.
- Additional page requests are required to browse records.

Current implementation detail:
- Controller sets `limit: 5` per page (overrides Pagy default)

## 5) Client-Side Text Search (Current Page Only)

Decision:
- Text search for merchant/description is done in the frontend after API results are fetched.

Why:
- Fast to implement for a small UI.
- No backend query/parser changes needed.

Trade-off:
- Search only applies to the current paginated page.
- Search results are not global across all records.
- Filtering behavior differs from status/category filters (which are server-side).

Current implementation detail:
- UI explicitly labels search as “current page only”

## 6) Themes via CSS Variables + `data-theme`

Decision:
- Use CSS custom properties and a `data-theme` attribute on `<html>` for theming.

Why:
- Low-complexity theming with Tailwind-compatible design tokens.
- Supports multiple named themes without runtime CSS generation.
- Works well with a lightweight client-side theme selector.

Trade-off:
- Theme tokens are centralized in CSS; adding new themed component tokens requires manual updates.
- Theme state is client-only (no server-rendered persisted theme cookie).

Current implementation detail:
- Themes: `light`, `dark`, `stephens`, `up`
- Stored in `localStorage`

## 7) Audit Logs Persist After Expense Deletion

Decision:
- Keep audit logs even after an expense is deleted.

Why:
- Preserves action history for review/debugging/accountability.

Trade-off:
- Audit rows may reference deleted expenses with `expense_id = NULL`.
- Consumers must tolerate null expense linkage when analyzing historical logs.

Current implementation detail:
- FK `expense_audit_logs.expense_id` uses `on_delete: :nullify`
- Delete action logs a snapshot in `metadata`

## 8) Expense Workflow via Service Objects

Decision:
- Submit/approve/reject logic is implemented in service objects.

Why:
- Keeps state transition checks transactional and centralized.
- Reduces controller complexity.

Trade-off:
- Slightly more indirection for a small codebase.
- Authorization checks are split between policy and service validation.

## 9) Reviewer Assignment on Expenses (No Manual Assignment Step)

Decision:
- Reviewer is assigned implicitly when a reviewer approves or rejects an expense.

Why:
- Matches the current workflow: any reviewer can act on a submitted expense.
- Avoids adding an explicit assignment workflow/state.

Trade-off:
- No pre-assignment/queue ownership mechanism.
- Concurrent reviewer actions rely on current status/locking behavior (TBD for heavier concurrency requirements).

Current implementation detail:
- `approve`/`reject` services set `reviewer_id = actor.id`

## 10) User Role Assignment Feature (Reviewer-Managed)

Decision:
- Reviewer can list users and change roles via API + frontend page.

Why:
- Keeps role management inside the app without DB console/admin tasks.

Trade-off:
- Self-role changes are blocked to avoid accidental lockout (`422`)
- No audit log currently exists for user role changes (expense audit only)

## 11) API Contract Drift Risk (Current Known Issue)

Current state:
- Backend category create endpoint expects nested payload (`{ category: { name } }`)
- Frontend category create helper currently sends flat payload (`{ name }`)

Trade-off:
- Faster local changes on one side can break integration if docs/tests are not updated in lockstep.

Status:
- Known mismatch in current codebase (not a design goal)
