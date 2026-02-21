require "rails_helper"

RSpec.describe "Expenses summary", type: :request do
  let(:login_path) { "/api/login" }

  def login_as(email:, password:)
    post login_path,
      params: { email: email, password: password }.to_json,
      headers: { "CONTENT_TYPE" => "application/json" }
    expect(response).to have_http_status(:ok)
  end

  def json
    JSON.parse(response.body)
  end

  let!(:employee) do
    User.create!(
      email: "employee_summary@test.com",
      password: "password",
      password_confirmation: "password",
      role: :employee
    )
  end

  let!(:other_employee) do
    User.create!(
      email: "other_employee_summary@test.com",
      password: "password",
      password_confirmation: "password",
      role: :employee
    )
  end

  let!(:reviewer) do
    User.create!(
      email: "reviewer_summary@test.com",
      password: "password",
      password_confirmation: "password",
      role: :reviewer
    )
  end

  let!(:employee_expense) do
    Expense.create!(
      user: employee,
      amount_cents: 1_500,
      currency: "USD",
      merchant: "Airport Taxi",
      description: "Ride",
      incurred_on: Date.current,
      status: :submitted,
      submitted_at: Time.current
    )
  end

  let!(:other_employee_expense) do
    Expense.create!(
      user: other_employee,
      amount_cents: 2_000,
      currency: "USD",
      merchant: "Lunch",
      description: "Meal",
      incurred_on: Date.current,
      status: :approved,
      submitted_at: Time.current,
      reviewed_at: Time.current,
      reviewer: reviewer
    )
  end

  describe "GET /api/expenses/summary" do
    it "returns only employee totals for employee users" do
      login_as(email: employee.email, password: "password")

      get "/api/expenses/summary"

      expect(response).to have_http_status(:ok)
      expect(json.dig("data", "all_time", "count")).to eq(1)
      expect(json.dig("data", "all_time", "totals")).to eq(
        [
          { "currency" => "USD", "amount_cents" => 1_500 }
        ]
      )
    end

    it "returns totals across users for reviewers" do
      login_as(email: reviewer.email, password: "password")

      get "/api/expenses/summary"

      expect(response).to have_http_status(:ok)
      expect(json.dig("data", "all_time", "count")).to eq(2)
      expect(json.dig("data", "all_time", "totals")).to eq(
        [
          { "currency" => "USD", "amount_cents" => 3_500 }
        ]
      )
    end

    it "returns the expected response keys" do
      login_as(email: reviewer.email, password: "password")

      get "/api/expenses/summary"

      expect(response).to have_http_status(:ok)
      expect(json).to include("data")
      expect(json["data"]).to include("all_time", "by_status", "monthly")
      expect(json["data"]["all_time"]).to include("count", "totals")
      expect(json["data"]["by_status"]).to be_an(Array)
      expect(json["data"]["monthly"]).to be_an(Array)
    end
  end
end
