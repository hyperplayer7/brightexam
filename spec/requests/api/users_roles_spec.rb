require "rails_helper"

RSpec.describe "User role management", type: :request do
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
    it "reviewer can list users" do
      login_as(email: reviewer.email, password: "password")

      get "/api/users"

      expect(response).to have_http_status(:ok)
      rows = json.fetch("data")
      expect(rows).to be_an(Array)
      expect(rows.map { |row| row.fetch("email") }).to include(reviewer.email, employee.email, another_employee.email)
      expect(rows.first).to include("id", "email", "role", "created_at")
    end

    it "employee cannot list users" do
      login_as(email: employee.email, password: "password")

      get "/api/users"

      expect(response).to have_http_status(:forbidden)
      expect(json.fetch("errors")).to include("forbidden")
    end
  end

  describe "PATCH /api/users/:id/role" do
    it "reviewer can update role" do
      login_as(email: reviewer.email, password: "password")

      patch "/api/users/#{employee.id}/role",
        params: { role: "reviewer" }.to_json,
        headers: { "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:ok)
      expect(employee.reload.role).to eq("reviewer")
      expect(json.fetch("data")).to include(
        "id" => employee.id,
        "email" => employee.email,
        "role" => "reviewer"
      )
    end

    it "invalid role returns 422" do
      login_as(email: reviewer.email, password: "password")

      patch "/api/users/#{employee.id}/role",
        params: { role: "admin" }.to_json,
        headers: { "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(employee.reload.role).to eq("employee")
      expect(json.fetch("errors").join(" ")).to include("role must be one of")
    end

    it "reviewer cannot change their own role" do
      login_as(email: reviewer.email, password: "password")

      patch "/api/users/#{reviewer.id}/role",
        params: { role: "employee" }.to_json,
        headers: { "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(reviewer.reload.role).to eq("reviewer")
      expect(json.fetch("errors")).to include("cannot_change_own_role")
    end
  end
end
