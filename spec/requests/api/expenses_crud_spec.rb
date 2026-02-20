# spec/requests/api/expenses_crud_spec.rb
require "rails_helper"

RSpec.describe "Expenses CRUD", type: :request do
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
      email: "employee_crud@test.com",
      password: "password",
      password_confirmation: "password",
      role: :employee
    )
  end

  let!(:reviewer) do
    User.create!(
      email: "reviewer_crud@test.com",
      password: "password",
      password_confirmation: "password",
      role: :reviewer
    )
  end

  describe "POST /api/expenses" do
    it "allows employee to create a drafted expense" do
      login_as(email: employee.email, password: "password")

      post "/api/expenses",
           params: {
             expense: {
               amount_cents: 12345,
               currency: "USD",
               merchant: "Grab",
               description: "Airport ride",
               incurred_on: "2026-02-20"
             }
           }.to_json,
           headers: { "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:created).or have_http_status(:ok)

      id = json.dig("data", "id") || json["id"]
      expect(id).to be_present

      expense = Expense.find(id)
      expect(expense.user_id).to eq(employee.id)
      expect(expense.status).to eq("drafted")
    end

    it "forbids reviewer from creating an expense (if your rules disallow it)" do
      login_as(email: reviewer.email, password: "password")

      post "/api/expenses",
           params: { expense: { amount_cents: 1000, incurred_on: "2026-02-20" } }.to_json,
           headers: { "CONTENT_TYPE" => "application/json" }

      # If your app allows reviewers to create expenses, change this to success.
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/expenses/:id" do
    it "allows employee to update their drafted expense" do
      login_as(email: employee.email, password: "password")

      expense = Expense.create!(
        user: employee,
        amount_cents: 1000,
        currency: "USD",
        merchant: "Test",
        description: "Old",
        incurred_on: Date.new(2026, 2, 20),
        status: :drafted
      )

      patch "/api/expenses/#{expense.id}",
            params: { expense: { description: "New" } }.to_json,
            headers: { "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:ok)
      expect(expense.reload.description).to eq("New")
    end

    it "forbids employee from updating after submission" do
      login_as(email: employee.email, password: "password")

      expense = Expense.create!(
        user: employee,
        amount_cents: 1000,
        currency: "USD",
        merchant: "Test",
        description: "Old",
        incurred_on: Date.new(2026, 2, 20),
        status: :submitted,
        submitted_at: Time.current
      )

      patch "/api/expenses/#{expense.id}",
            params: { expense: { description: "New" } }.to_json,
            headers: { "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/expenses/:id" do
    it "allows employee to delete their drafted expense" do
      login_as(email: employee.email, password: "password")

      expense = Expense.create!(
        user: employee,
        amount_cents: 1000,
        currency: "USD",
        merchant: "Test",
        description: "Delete me",
        incurred_on: Date.new(2026, 2, 20),
        status: :drafted
      )

      delete "/api/expenses/#{expense.id}"

      expect(response).to have_http_status(:no_content).or have_http_status(:ok)
      expect(Expense.where(id: expense.id)).to be_empty
    end

    it "forbids employee from deleting after submission" do
      login_as(email: employee.email, password: "password")

      expense = Expense.create!(
        user: employee,
        amount_cents: 1000,
        currency: "USD",
        merchant: "Test",
        description: "Can't delete",
        incurred_on: Date.new(2026, 2, 20),
        status: :submitted,
        submitted_at: Time.current
      )

      delete "/api/expenses/#{expense.id}"

      expect(response).to have_http_status(:forbidden)
      expect(Expense.where(id: expense.id)).to exist
    end
  end
end
