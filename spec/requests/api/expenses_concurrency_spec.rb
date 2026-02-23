require "rails_helper"

RSpec.describe "Expenses optimistic locking", type: :request do
  let!(:employee) do
    User.create!(
      email: "employee_locking@test.com",
      password: "password",
      password_confirmation: "password",
      role: :employee
    )
  end

  it "returns 409 and stale_object for stale lock_version" do
    expense = Expense.create!(
      user: employee,
      amount_cents: 1000,
      currency: "USD",
      merchant: "Taxi",
      description: "Original",
      incurred_on: Date.current,
      status: :drafted
    )

    stale_version = expense.lock_version
    expense.update!(description: "Concurrent update")

    cookie = login_and_capture_cookie(email: employee.email, password: "password")

    authenticated_request(
      :patch,
      "/api/expenses/#{expense.id}",
      cookie: cookie,
      params: {
        expense: {
          description: "My update",
          lock_version: stale_version
        }
      }.to_json
    )

    expect(response).to have_http_status(:conflict)
    expect(json_response.fetch("errors")).to include("stale_object")
    expect(expense.reload.description).to eq("Concurrent update")
  end
end
