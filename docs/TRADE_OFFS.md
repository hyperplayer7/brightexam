# Trade-offs and Architectural Decisions

## 1) Rails API-only + Next.js separation
Decision:
- Backend and frontend are separated by HTTP API boundaries.

Why:
- Clear separation of concerns.
- Independent frontend iteration and deployment potential.

Trade-off:
- Extra integration surface (CORS/cookies/session behavior).
- More coordination between API payload changes and frontend consumers.

## 2) Cookie-based session authentication
Decision:
- Use Rails session cookie auth (`HttpOnly`) instead of JWT.

Why:
- Minimal implementation overhead for a two-party app (web + API).
- Strong default protections when configured properly.

Trade-off:
- Less convenient for non-browser clients and third-party integrations.
- Requires careful same-site/cross-site and CSRF handling strategy as app evolves.

## 3) Pundit policies for authorization
Decision:
- Authorization logic is centralized in policy classes.

Why:
- Keeps controllers focused on transport concerns.
- Rules are explicit and testable in isolation.

Trade-off:
- Policy drift risk if business rules change without policy/test updates.

## 4) Service objects for transitions
Decision:
- Expense workflow transitions (`submit`, `approve`, `reject`) run via service objects.

Why:
- Keeps transition logic cohesive and transactional.
- Easier to enforce state checks and actor checks consistently.

Trade-off:
- More files/indirection for a small feature set.

## 5) API versioning
Current state:
- API is not versioned (routes use `/api/...` without `/v1`).

Why this may be acceptable now:
- Single-client MVP with limited public surface.

Trade-off:
- Future breaking changes become harder to roll out safely.
- Versioning strategy is `TBD` for broader client support.

## 6) Reviewer cannot create expenses
Enforcement:
- Backend policy (`ExpensePolicy#create?`) allows only `employee`.
- Frontend hides/blocks create flow for reviewer.

Why:
- Matches domain role boundaries.

Trade-off:
- Dual enforcement means frontend and backend must stay aligned.

## 7) Currency limited to PHP/USD
Current state:
- Frontend create/edit forms constrain currency to `PHP` and `USD`.
- Backend currently stores a string and does not enforce an allowed set.

Why:
- Simplifies MVP UX and reduces selection ambiguity.

Trade-off:
- Constraint is not fully authoritative until backend validation enforces it.

## Improvements With More Time

- Add backend validation to enforce allowed currencies.
- Add API versioning (`/api/v1`) and deprecation strategy.
- Add OpenAPI/Swagger documentation generated from request specs.
- Expand automated test coverage for edge cases and authorization matrix.
- Add robust CSRF strategy documentation for cookie-authenticated requests.
- Add audit trail/events for state transitions and reviewer actions.
- Introduce typed API contracts between frontend and backend.
