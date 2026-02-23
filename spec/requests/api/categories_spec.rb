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

  describe "GET /api/categories" do
    it "returns 401 when unauthenticated" do
      get "/api/categories"

      expect(response).to have_http_status(:unauthorized)
      expect(json_response.fetch("errors")).to include("unauthorized")
    end
  end
end
