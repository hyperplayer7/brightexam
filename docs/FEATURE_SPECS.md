# Feature Specs

## Scope
Expense Tracker supports two roles:
- `employee`
- `reviewer`

Primary entities:
- `User`
- `Expense`

## User Stories and Acceptance Criteria

### Employee stories
1. As an employee, I can log in and view only my expenses.
- Given I am authenticated as an employee
- When I open the expenses list
- Then I only see expenses where `expense.user_id == current_user.id`

2. As an employee, I can create a draft expense.
- Given I am authenticated as an employee
- When I submit valid expense input
- Then an expense is created with status `drafted`

3. As an employee, I can edit or delete only my drafted expense.
- Given I own an expense and its status is `drafted`
- When I update or delete it
- Then the action succeeds
- And if status is not `drafted`, the action is forbidden

4. As an employee, I can submit only my drafted expense.
- Given I own an expense and it is `drafted`
- When I call submit
- Then status changes to `submitted`
- And `submitted_at` is set

### Reviewer stories
1. As a reviewer, I can log in and view all expenses.
- Given I am authenticated as a reviewer
- When I open the expenses list
- Then I can see all expenses

2. As a reviewer, I can approve submitted expenses.
- Given an expense is `submitted`
- And I am a reviewer
- When I approve it
- Then status changes to `approved`
- And `reviewed_at` and `reviewer_id` are set

3. As a reviewer, I can reject submitted expenses with a reason.
- Given an expense is `submitted`
- And I am a reviewer
- When I reject with `rejection_reason`
- Then status changes to `rejected`
- And `reviewed_at`, `reviewer_id`, and `rejection_reason` are set

4. As a reviewer, I cannot create expenses.
- Given I am authenticated as a reviewer
- When I attempt to create an expense
- Then access is forbidden by policy

## Expense State Machine

```text
drafted -> submitted -> approved
                   -> rejected
```

Transition constraints:
- `drafted -> submitted`: owner only
- `submitted -> approved`: reviewer only
- `submitted -> rejected`: reviewer only, rejection reason required
- No transition service exists for moving `approved` or `rejected` to other states

## Business Rules

Authentication:
- Session cookie required for protected endpoints.

Authorization:
- `employee`
  - can create expenses
  - can view own expenses
  - can show own expense
  - can update/destroy/submit own expense only when `drafted`
- `reviewer`
  - can view all expenses
  - can show any expense
  - can approve/reject only when expense is `submitted`
  - cannot create/update/destroy/submit employee expenses

Validation and transition rules:
- `amount_cents` must be present and > 0
- `incurred_on` must be present
- submit requires `drafted`
- approve requires `submitted` + reviewer actor
- reject requires `submitted` + reviewer actor + `rejection_reason`
