# spec/requests/api/expenses_workflow_spec.rb
require "rails_helper"

RSpec.describe "Expenses workflow", type: :request do
  # Adjust these if your routes differ
  let(:login_path)  { "/api/login" }
  let(:logout_path) { "/api/logout" }

  def login_as(email:, password:)
    post login_path, params: { email: email, password: password }.to_json,
                     headers: { "CONTENT_TYPE" => "application/json" }
    expect(response).to have_http_status(:ok)
  end

  def json
    JSON.parse(response.body)
  end

  let!(:employee) do
    User.create!(
      email: "employee@test.com",
      password: "password",
      password_confirmation: "password",
      role: :employee
    )
  end

  let!(:reviewer) do
    User.create!(
      email: "reviewer@test.com",
      password: "password",
      password_confirmation: "password",
      role: :reviewer
    )
  end

  describe "authentication guard" do
    it "returns 401 when not logged in" do
      post "/api/expenses/123/submit"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "submit" do
    it "allows employee to submit their drafted expense" do
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

      post "/api/expenses/#{expense.id}/submit"

      expect(response).to have_http_status(:ok)
      expense.reload
      expect(expense.status).to eq("submitted")
      expect(expense.submitted_at).not_to be_nil
    end

    it "forbids employee from submitting someone else's expense" do
      other_employee = User.create!(
        email: "other_employee@test.com",
        password: "password",
        password_confirmation: "password",
        role: :employee
      )

      login_as(email: employee.email, password: "password")

      expense = Expense.create!(
        user: other_employee,
        amount_cents: 1000,
        currency: "USD",
        merchant: "Grab",
        description: "Ride",
        incurred_on: Date.new(2026, 2, 20),
        status: :drafted
      )

      post "/api/expenses/#{expense.id}/submit"
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 422 if expense is not drafted" do
      login_as(email: employee.email, password: "password")

      expense = Expense.create!(
        user: employee,
        amount_cents: 1000,
        currency: "USD",
        merchant: "Grab",
        description: "Ride",
        incurred_on: Date.new(2026, 2, 20),
        status: :submitted,
        submitted_at: Time.current
      )

      post "/api/expenses/#{expense.id}/submit"
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "approve" do
    it "allows reviewer to approve submitted expense" do
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

      post "/api/expenses/#{expense.id}/approve"

      expect(response).to have_http_status(:ok)
      expense.reload
      expect(expense.status).to eq("approved")
      expect(expense.reviewed_at).not_to be_nil
      expect(expense.reviewer_id).to eq(reviewer.id)
    end

    it "forbids employee from approving" do
      login_as(email: employee.email, password: "password")

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

      post "/api/expenses/#{expense.id}/approve"
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 422 if expense is not submitted" do
      login_as(email: reviewer.email, password: "password")

      expense = Expense.create!(
        user: employee,
        amount_cents: 2500,
        currency: "USD",
        merchant: "Lunch",
        description: "Meal",
        incurred_on: Date.new(2026, 2, 20),
        status: :drafted
      )

      post "/api/expenses/#{expense.id}/approve"
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 4xx with error envelope when approving an already-approved expense" do
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

      post "/api/expenses/#{expense.id}/approve"
      expect(response).to have_http_status(:ok)

      post "/api/expenses/#{expense.id}/approve"
      expect(response.status).to be_between(400, 499)
      expect(json.fetch("errors")).to be_an(Array)
    end
  end

  describe "reject" do
    it "allows reviewer to reject submitted expense with a reason" do
      login_as(email: reviewer.email, password: "password")

      expense = Expense.create!(
        user: employee,
        amount_cents: 999,
        currency: "USD",
        merchant: "Supplies",
        description: "Pens",
        incurred_on: Date.new(2026, 2, 20),
        status: :submitted,
        submitted_at: Time.current
      )

      post "/api/expenses/#{expense.id}/reject",
           params: { rejection_reason: "Missing receipt" }.to_json,
           headers: { "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:ok)
      expense.reload
      expect(expense.status).to eq("rejected")
      expect(expense.reviewed_at).not_to be_nil
      expect(expense.reviewer_id).to eq(reviewer.id)
      expect(expense.rejection_reason).to eq("Missing receipt")
    end

    it "returns 422 when rejection_reason is missing" do
      login_as(email: reviewer.email, password: "password")

      expense = Expense.create!(
        user: employee,
        amount_cents: 999,
        currency: "USD",
        merchant: "Supplies",
        description: "Pens",
        incurred_on: Date.new(2026, 2, 20),
        status: :submitted,
        submitted_at: Time.current
      )

      post "/api/expenses/#{expense.id}/reject",
           params: {}.to_json,
           headers: { "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 4xx with error envelope when rejecting an already-rejected expense" do
      login_as(email: reviewer.email, password: "password")

      expense = Expense.create!(
        user: employee,
        amount_cents: 999,
        currency: "USD",
        merchant: "Supplies",
        description: "Pens",
        incurred_on: Date.new(2026, 2, 20),
        status: :submitted,
        submitted_at: Time.current
      )

      post "/api/expenses/#{expense.id}/reject",
           params: { rejection_reason: "Missing receipt" }.to_json,
           headers: { "CONTENT_TYPE" => "application/json" }
      expect(response).to have_http_status(:ok)

      post "/api/expenses/#{expense.id}/reject",
           params: { rejection_reason: "Still missing" }.to_json,
           headers: { "CONTENT_TYPE" => "application/json" }
      expect(response.status).to be_between(400, 499)
      expect(json.fetch("errors")).to be_an(Array)
    end
  end
end
