require "rails_helper"

RSpec.describe "Expenses access control", type: :request do
  let!(:employee) do
    User.create!(
      email: "employee_access@test.com",
      password: "password",
      password_confirmation: "password",
      role: :employee
    )
  end

  let!(:other_employee) do
    User.create!(
      email: "other_employee_access@test.com",
      password: "password",
      password_confirmation: "password",
      role: :employee
    )
  end

  let!(:reviewer) do
    User.create!(
      email: "reviewer_access@test.com",
      password: "password",
      password_confirmation: "password",
      role: :reviewer
    )
  end

  let!(:employee_expense) do
    Expense.create!(
      user: employee,
      amount_cents: 1000,
      currency: "USD",
      merchant: "Taxi",
      description: "Airport",
      incurred_on: Date.current,
      status: :drafted
    )
  end

  let!(:other_expense) do
    Expense.create!(
      user: other_employee,
      amount_cents: 2000,
      currency: "USD",
      merchant: "Lunch",
      description: "Meal",
      incurred_on: Date.current,
      status: :submitted,
      submitted_at: Time.current
    )
  end

  describe "GET /api/expenses" do
    it "shows only owned expenses to an employee" do
      cookie = login_and_capture_cookie(email: employee.email, password: "password")

      authenticated_request(:get, "/api/expenses", cookie: cookie)

      expect(response).to have_http_status(:ok)
      ids = json_response.fetch("data").map { |row| row.fetch("id") }
      expect(ids).to contain_exactly(employee_expense.id)
    end

    it "shows all expenses to a reviewer" do
      cookie = login_and_capture_cookie(email: reviewer.email, password: "password")

      authenticated_request(:get, "/api/expenses", cookie: cookie)

      expect(response).to have_http_status(:ok)
      ids = json_response.fetch("data").map { |row| row.fetch("id") }
      expect(ids).to include(employee_expense.id, other_expense.id)
    end
  end

  describe "GET /api/expenses/:id" do
    it "allows the owner" do
      cookie = login_and_capture_cookie(email: employee.email, password: "password")

      authenticated_request(:get, "/api/expenses/#{employee_expense.id}", cookie: cookie)

      expect(response).to have_http_status(:ok)
      expect(json_response.dig("data", "id")).to eq(employee_expense.id)
    end

    it "forbids another employee" do
      cookie = login_and_capture_cookie(email: other_employee.email, password: "password")

      authenticated_request(:get, "/api/expenses/#{employee_expense.id}", cookie: cookie)

      expect(response).to have_http_status(:forbidden)
      expect(json_response.fetch("errors")).to include("forbidden")
    end

    it "allows a reviewer" do
      cookie = login_and_capture_cookie(email: reviewer.email, password: "password")

      authenticated_request(:get, "/api/expenses/#{employee_expense.id}", cookie: cookie)

      expect(response).to have_http_status(:ok)
      expect(json_response.dig("data", "id")).to eq(employee_expense.id)
    end

    it "returns 404 for a missing expense" do
      cookie = login_and_capture_cookie(email: reviewer.email, password: "password")

      authenticated_request(:get, "/api/expenses/999999", cookie: cookie)

      expect(response).to have_http_status(:not_found)
      expect(json_response.fetch("errors")).to include("not_found")
    end
  end

  describe "GET /api/expenses/:id/audit_logs" do
    before do
      ExpenseAuditLog.create!(
        expense: employee_expense,
        actor: employee,
        action: "expense.created",
        to_status: employee_expense.status,
        metadata: {}
      )
    end

    it "allows the owner" do
      cookie = login_and_capture_cookie(email: employee.email, password: "password")

      authenticated_request(:get, "/api/expenses/#{employee_expense.id}/audit_logs", cookie: cookie)

      expect(response).to have_http_status(:ok)
      expect(json_response.fetch("data")).to be_an(Array)
    end

    it "allows a reviewer" do
      cookie = login_and_capture_cookie(email: reviewer.email, password: "password")

      authenticated_request(:get, "/api/expenses/#{employee_expense.id}/audit_logs", cookie: cookie)

      expect(response).to have_http_status(:ok)
      expect(json_response.fetch("data")).to be_an(Array)
    end

    it "forbids another employee" do
      cookie = login_and_capture_cookie(email: other_employee.email, password: "password")

      authenticated_request(:get, "/api/expenses/#{employee_expense.id}/audit_logs", cookie: cookie)

      expect(response).to have_http_status(:forbidden)
      expect(json_response.fetch("errors")).to include("forbidden")
    end
  end
end
