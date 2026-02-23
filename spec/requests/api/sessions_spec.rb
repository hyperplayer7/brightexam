require "rails_helper"

RSpec.describe "Sessions API", type: :request do
  let!(:employee) do
    User.create!(
      email: "session_employee@test.com",
      password: "password",
      password_confirmation: "password",
      role: :employee
    )
  end

  describe "POST /api/login" do
    it "returns 200 and sets a session cookie for valid credentials" do
      post "/api/login",
        params: { email: employee.email, password: "password" }.to_json,
        headers: { "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Set-Cookie"]).to include("_brightexam_session")
      expect(json_response.dig("data", "email")).to eq(employee.email)
      expect(json_response.dig("data", "role")).to eq("employee")
    end

    it "returns 401 for invalid credentials" do
      post "/api/login",
        params: { email: employee.email, password: "wrong-password" }.to_json,
        headers: { "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:unauthorized)
      expect(json_response.fetch("errors")).to include("invalid_credentials")
    end
  end

  describe "GET /api/me" do
    it "returns 200 when authenticated" do
      cookie = login_and_capture_cookie(email: employee.email, password: "password")

      authenticated_request(:get, "/api/me", cookie: cookie)

      expect(response).to have_http_status(:ok)
      expect(json_response.dig("data", "id")).to eq(employee.id)
      expect(json_response.dig("data", "email")).to eq(employee.email)
    end

    it "returns 401 when unauthenticated" do
      get "/api/me"

      expect(response).to have_http_status(:unauthorized)
      expect(json_response.fetch("errors")).to include("unauthorized")
    end
  end

  describe "POST /api/logout" do
    it "returns 204 and invalidates the session" do
      cookie = login_and_capture_cookie(email: employee.email, password: "password")

      authenticated_request(:post, "/api/logout", cookie: cookie)
      expect(response).to have_http_status(:no_content)
      logout_cookie = response.headers["Set-Cookie"]

      authenticated_request(:get, "/api/me", cookie: logout_cookie || cookie)
      expect(response).to have_http_status(:unauthorized)
      expect(json_response.fetch("errors")).to include("unauthorized")
    end

    it "returns 401 when unauthenticated" do
      post "/api/logout"

      expect(response).to have_http_status(:unauthorized)
      expect(json_response.fetch("errors")).to include("unauthorized")
    end
  end

  describe "session persistence" do
    it "persists the session across requests after login" do
      Expense.create!(
        user: employee,
        amount_cents: 1000,
        currency: "USD",
        merchant: "Taxi",
        description: "Ride",
        incurred_on: Date.current,
        status: :drafted
      )

      cookie = login_and_capture_cookie(email: employee.email, password: "password")

      authenticated_request(:get, "/api/expenses", cookie: cookie)

      expect(response).to have_http_status(:ok)
      expect(json_response.fetch("data").size).to eq(1)
    end
  end
end
