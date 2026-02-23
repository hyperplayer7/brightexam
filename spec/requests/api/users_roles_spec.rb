require "rails_helper"

RSpec.describe "User role management", type: :request do
  let!(:reviewer) do
    User.create!(
      email: "reviewer_roles@test.com",
      password: "password",
      password_confirmation: "password",
      role: :reviewer
    )
  end

  let!(:employee) do
    User.create!(
      email: "employee_roles@test.com",
      password: "password",
      password_confirmation: "password",
      role: :employee
    )
  end

  let!(:another_employee) do
    User.create!(
      email: "employee_two_roles@test.com",
      password: "password",
      password_confirmation: "password",
      role: :employee
    )
  end

  describe "GET /api/users" do
    it "returns 401 when unauthenticated" do
      get "/api/users"

      expect(response).to have_http_status(:unauthorized)
      expect(json_response.fetch("errors")).to include("unauthorized")
    end

    it "reviewer can list users" do
      cookie = login_and_capture_cookie(email: reviewer.email, password: "password")

      authenticated_request(:get, "/api/users", cookie: cookie)

      expect(response).to have_http_status(:ok)
      rows = json_response.fetch("data")
      expect(rows).to be_an(Array)
      expect(rows.map { |row| row.fetch("email") }).to include(reviewer.email, employee.email, another_employee.email)
      expect(rows.first).to include("id", "email", "role", "created_at")
    end

    it "employee cannot list users" do
      cookie = login_and_capture_cookie(email: employee.email, password: "password")

      authenticated_request(:get, "/api/users", cookie: cookie)

      expect(response).to have_http_status(:forbidden)
      expect(json_response.fetch("errors")).to include("forbidden")
    end
  end

  describe "PATCH /api/users/:id/role" do
    it "employee is forbidden from updating roles" do
      cookie = login_and_capture_cookie(email: employee.email, password: "password")

      authenticated_request(
        :patch,
        "/api/users/#{another_employee.id}/role",
        cookie: cookie,
        params: { role: "reviewer" }.to_json
      )

      expect(response).to have_http_status(:forbidden)
      expect(json_response.fetch("errors")).to include("forbidden")
      expect(another_employee.reload.role).to eq("employee")
    end

    it "reviewer can update role" do
      cookie = login_and_capture_cookie(email: reviewer.email, password: "password")

      authenticated_request(
        :patch,
        "/api/users/#{employee.id}/role",
        cookie: cookie,
        params: { role: "reviewer" }.to_json
      )

      expect(response).to have_http_status(:ok)
      expect(employee.reload.role).to eq("reviewer")
      expect(json_response.fetch("data")).to include(
        "id" => employee.id,
        "email" => employee.email,
        "role" => "reviewer"
      )
    end

    it "invalid role returns 422" do
      cookie = login_and_capture_cookie(email: reviewer.email, password: "password")

      authenticated_request(
        :patch,
        "/api/users/#{employee.id}/role",
        cookie: cookie,
        params: { role: "admin" }.to_json
      )

      expect(response).to have_http_status(:unprocessable_entity)
      expect(employee.reload.role).to eq("employee")
      expect(json_response.fetch("errors").join(" ")).to include("role must be one of")
    end

    it "returns 404 for nonexistent user" do
      cookie = login_and_capture_cookie(email: reviewer.email, password: "password")

      authenticated_request(
        :patch,
        "/api/users/999999/role",
        cookie: cookie,
        params: { role: "employee" }.to_json
      )

      expect(response).to have_http_status(:not_found)
      expect(json_response.fetch("errors")).to include("not_found")
    end

    it "reviewer cannot change their own role" do
      cookie = login_and_capture_cookie(email: reviewer.email, password: "password")

      authenticated_request(
        :patch,
        "/api/users/#{reviewer.id}/role",
        cookie: cookie,
        params: { role: "employee" }.to_json
      )

      expect(response.status).to be_between(400, 499)
      expect(reviewer.reload.role).to eq("reviewer")
      expect(json_response.fetch("errors")).to include("cannot_change_own_role")
    end
  end
end
