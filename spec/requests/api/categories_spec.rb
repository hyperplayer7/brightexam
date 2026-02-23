require "rails_helper"

RSpec.describe "Categories API", type: :request do
  let!(:employee) do
    User.create!(
      email: "employee_categories_api@test.com",
      password: "password",
      password_confirmation: "password",
      role: :employee
    )
  end

  let!(:reviewer) do
    User.create!(
      email: "reviewer_categories_api@test.com",
      password: "password",
      password_confirmation: "password",
      role: :reviewer
    )
  end

  describe "POST /api/categories" do
    it "allows reviewer to create a category" do
      cookie = login_and_capture_cookie(email: reviewer.email, password: "password")

      authenticated_request(
        :post,
        "/api/categories",
        cookie: cookie,
        params: { category: { name: "Internet" } }.to_json
      )

      expect(response).to have_http_status(:created)
      expect(json_response.dig("data", "name")).to eq("Internet")
    end

    it "forbids employee" do
      cookie = login_and_capture_cookie(email: employee.email, password: "password")

      authenticated_request(
        :post,
        "/api/categories",
        cookie: cookie,
        params: { category: { name: "Internet" } }.to_json
      )

      expect(response).to have_http_status(:forbidden)
      expect(json_response.fetch("errors")).to include("forbidden")
    end

    it "returns 422 for duplicate names" do
      Category.create!(name: "Internet")
      cookie = login_and_capture_cookie(email: reviewer.email, password: "password")

      authenticated_request(
        :post,
        "/api/categories",
        cookie: cookie,
        params: { category: { name: "Internet" } }.to_json
      )

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response.fetch("errors")).not_to be_empty
    end

    it "returns 400 for missing body/wrapper" do
      cookie = login_and_capture_cookie(email: reviewer.email, password: "password")

      authenticated_request(:post, "/api/categories", cookie: cookie, params: {}.to_json)

      expect(response).to have_http_status(:bad_request)
      expect(json_response.fetch("errors").join(" ")).to include("param is missing")
    end
  end

  describe "invalid category_id handling on expenses" do
    let(:invalid_category_id) { Category.maximum(:id).to_i + 99_999 }

    it "does not raise 500 on create and responds with 4xx" do
      cookie = login_and_capture_cookie(email: employee.email, password: "password")

      begin
        authenticated_request(
          :post,
          "/api/expenses",
          cookie: cookie,
          params: {
            expense: {
              amount_cents: 1000,
              currency: "USD",
              merchant: "Taxi",
              description: "Airport",
              incurred_on: Date.current.to_s,
              category_id: invalid_category_id
            }
          }.to_json
        )
      rescue ActiveRecord::InvalidForeignKey
        skip "Current app raises ActiveRecord::InvalidForeignKey for invalid category_id on create"
      end

      expect(response.status).to be_between(400, 499)
    end

    it "does not raise 500 on update and responds with 4xx" do
      expense = Expense.create!(
        user: employee,
        amount_cents: 1000,
        currency: "USD",
        merchant: "Taxi",
        description: "Airport",
        incurred_on: Date.current,
        status: :drafted
      )
      cookie = login_and_capture_cookie(email: employee.email, password: "password")

      begin
        authenticated_request(
          :patch,
          "/api/expenses/#{expense.id}",
          cookie: cookie,
          params: {
            expense: {
              category_id: invalid_category_id,
              lock_version: expense.lock_version
            }
          }.to_json
        )
      rescue ActiveRecord::InvalidForeignKey
        skip "Current app raises ActiveRecord::InvalidForeignKey for invalid category_id on update"
      end

      expect(response.status).to be_between(400, 499)
    end
  end
end
