require "rails_helper"

RSpec.describe "Expense audit logs", type: :request do
  let(:login_path) { "/api/login" }

  def login_as(email:, password:)
    post login_path,
         params: { email: email, password: password }.to_json,
         headers: { "CONTENT_TYPE" => "application/json" }
    expect(response).to have_http_status(:ok)
  end

  let!(:employee) do
    User.create!(
      email: "employee_audit@test.com",
      password: "password",
      password_confirmation: "password",
      role: :employee
    )
  end

  let!(:reviewer) do
    User.create!(
      email: "reviewer_audit@test.com",
      password: "password",
      password_confirmation: "password",
      role: :reviewer
    )
  end

  it "creates an audit log when submitting an expense" do
    login_as(email: employee.email, password: "password")

    expense = Expense.create!(
      user: employee,
      amount_cents: 1000,
      currency: "USD",
      merchant: "Grab",
      description: "Ride",
      incurred_on: Date.new(2026, 2, 20),
      status: :drafted
    )

    expect {
      post "/api/expenses/#{expense.id}/submit"
    }.to change { ExpenseAuditLog.where(action: "expense.submitted", expense_id: expense.id).count }.by(1)

    expect(response).to have_http_status(:ok)
  end

  it "creates an audit log when approving an expense" do
    login_as(email: reviewer.email, password: "password")

    expense = Expense.create!(
      user: employee,
      amount_cents: 2500,
      currency: "USD",
      merchant: "Lunch",
      description: "Meal",
      incurred_on: Date.new(2026, 2, 20),
      status: :submitted,
      submitted_at: Time.current
    )

    expect {
      post "/api/expenses/#{expense.id}/approve"
    }.to change { ExpenseAuditLog.where(action: "expense.approved", expense_id: expense.id).count }.by(1)

    expect(response).to have_http_status(:ok)
  end

  it "creates an audit log when rejecting an expense" do
    login_as(email: reviewer.email, password: "password")

    expense = Expense.create!(
      user: employee,
      amount_cents: 2500,
      currency: "USD",
      merchant: "Supplies",
      description: "Pens",
      incurred_on: Date.new(2026, 2, 20),
      status: :submitted,
      submitted_at: Time.current
    )

    expect {
      post "/api/expenses/#{expense.id}/reject",
           params: { rejection_reason: "Missing receipt" }.to_json,
           headers: { "CONTENT_TYPE" => "application/json" }
    }.to change { ExpenseAuditLog.where(action: "expense.rejected", expense_id: expense.id).count }.by(1)

    expect(response).to have_http_status(:ok)
  end

  it "keeps audit logs after deleting an expense" do
    login_as(email: employee.email, password: "password")

    expense = Expense.create!(
      user: employee,
      amount_cents: 3000,
      currency: "USD",
      merchant: "Taxi",
      description: "Airport",
      incurred_on: Date.new(2026, 2, 20),
      status: :drafted
    )

    expect {
      delete "/api/expenses/#{expense.id}"
    }.to change(ExpenseAuditLog, :count).by(1)

    expect(response).to have_http_status(:no_content)
    expect(Expense.where(id: expense.id)).to be_empty

    log = ExpenseAuditLog.order(:created_at).last
    expect(log.action).to eq("expense.deleted")
    expect(ExpenseAuditLog.where(id: log.id)).to exist
  end
end
