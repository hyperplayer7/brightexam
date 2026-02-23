require "rails_helper"

RSpec.describe "Expenses strong params", type: :request do
  let!(:employee) do
    User.create!(
      email: "employee_strong_params@test.com",
      password: "password",
      password_confirmation: "password",
      role: :employee
    )
  end

  let!(:reviewer) do
    User.create!(
      email: "reviewer_strong_params@test.com",
      password: "password",
      password_confirmation: "password",
      role: :reviewer
    )
  end

  describe "POST /api/expenses" do
    it "does not apply forbidden fields" do
      cookie = login_and_capture_cookie(email: employee.email, password: "password")

      authenticated_request(
        :post,
        "/api/expenses",
        cookie: cookie,
        params: {
          expense: {
            user_id: reviewer.id,
            reviewer_id: reviewer.id,
            status: "approved",
            submitted_at: 1.day.ago.iso8601,
            reviewed_at: Time.current.iso8601,
            rejection_reason: "Injected",
            amount_cents: 1234,
            currency: "usd",
            merchant: "Cafe",
            description: "Breakfast",
            incurred_on: Date.current.to_s
          }
        }.to_json
      )

      expect(response).to have_http_status(:created)

      expense_id = json_response.dig("data", "id")
      expense = Expense.find(expense_id)
      expect(expense.user_id).to eq(employee.id)
      expect(expense.reviewer_id).to be_nil
      expect(expense.status).to eq("drafted")
      expect(expense.submitted_at).to be_nil
      expect(expense.reviewed_at).to be_nil
      expect(expense.rejection_reason).to be_nil
    end
  end

  describe "PATCH /api/expenses/:id" do
    it "does not apply forbidden fields on update" do
      expense = Expense.create!(
        user: employee,
        amount_cents: 1000,
        currency: "USD",
        merchant: "Taxi",
        description: "Before",
        incurred_on: Date.current,
        status: :drafted
      )

      cookie = login_and_capture_cookie(email: employee.email, password: "password")

      authenticated_request(
        :patch,
        "/api/expenses/#{expense.id}",
        cookie: cookie,
        params: {
          expense: {
            user_id: reviewer.id,
            reviewer_id: reviewer.id,
            status: "approved",
            submitted_at: 1.day.ago.iso8601,
            reviewed_at: Time.current.iso8601,
            rejection_reason: "Injected",
            description: "After",
            lock_version: expense.lock_version
          }
        }.to_json
      )

      expect(response).to have_http_status(:ok)

      expense.reload
      expect(expense.description).to eq("After")
      expect(expense.user_id).to eq(employee.id)
      expect(expense.reviewer_id).to be_nil
      expect(expense.status).to eq("drafted")
      expect(expense.submitted_at).to be_nil
      expect(expense.reviewed_at).to be_nil
      expect(expense.rejection_reason).to be_nil
    end
  end
end
