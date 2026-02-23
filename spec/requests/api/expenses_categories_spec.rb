require "rails_helper"

RSpec.describe "Expense categories", type: :request do
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
      email: "employee_category@test.com",
      password: "password",
      password_confirmation: "password",
      role: :employee
    )
  end

  let!(:reviewer) do
    User.create!(
      email: "reviewer_category@test.com",
      password: "password",
      password_confirmation: "password",
      role: :reviewer
    )
  end

  describe "category assignment" do
    it "allows employee to set category on their drafted expense" do
      login_as(email: employee.email, password: "password")
      category = Category.create!(name: "Transport")

      expense = Expense.create!(
        user: employee,
        amount_cents: 1000,
        currency: "USD",
        merchant: "Taxi",
        description: "Airport",
        incurred_on: Date.current,
        status: :drafted
      )

      patch "/api/expenses/#{expense.id}",
        params: {
          expense: {
            category_id: category.id,
            lock_version: expense.lock_version
          }
        }.to_json,
        headers: { "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:ok)
      expect(expense.reload.category_id).to eq(category.id)
      expect(json.dig("data", "category", "id")).to eq(category.id)
      expect(json.dig("data", "category", "name")).to eq("Transport")
    end

    it "does not allow changing category after submit" do
      login_as(email: employee.email, password: "password")
      category = Category.create!(name: "Meals")

      expense = Expense.create!(
        user: employee,
        amount_cents: 2200,
        currency: "USD",
        merchant: "Cafe",
        description: "Lunch",
        incurred_on: Date.current,
        status: :submitted,
        submitted_at: Time.current
      )

      patch "/api/expenses/#{expense.id}",
        params: {
          expense: {
            category_id: category.id,
            lock_version: expense.lock_version
          }
        }.to_json,
        headers: { "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:forbidden)
      expect(expense.reload.category_id).to be_nil
    end
  end

  describe "GET /api/categories" do
    it "returns seeded categories" do
      Rails.application.load_seed
      login_as(email: employee.email, password: "password")

      get "/api/categories"

      expect(response).to have_http_status(:ok)
      names = json.fetch("data").map { |row| row.fetch("name") }
      expect(names).to include("Transport", "Meals", "Supplies")
    end
  end
end
