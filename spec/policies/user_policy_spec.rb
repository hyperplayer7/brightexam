require "rails_helper"

RSpec.describe UserPolicy, type: :policy do
  let(:reviewer) do
    User.create!(
      email: "reviewer_user_policy@test.com",
      password: "password",
      password_confirmation: "password",
      role: :reviewer
    )
  end

  let(:employee) do
    User.create!(
      email: "employee_user_policy@test.com",
      password: "password",
      password_confirmation: "password",
      role: :employee
    )
  end

  let(:target_user) do
    User.create!(
      email: "target_user_policy@test.com",
      password: "password",
      password_confirmation: "password",
      role: :employee
    )
  end

  describe "permissions" do
    context "reviewer" do
      subject(:policy) { described_class.new(reviewer, target_user) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:update_role) }
    end

    context "employee" do
      subject(:policy) { described_class.new(employee, target_user) }

      it { is_expected.not_to permit_action(:index) }
      it { is_expected.not_to permit_action(:update_role) }
    end

    context "nil user" do
      subject(:policy) { described_class.new(nil, target_user) }

      it { is_expected.not_to permit_action(:index) }
      it { is_expected.not_to permit_action(:update_role) }
    end
  end

  describe "scope" do
    let!(:another_user) do
      User.create!(
        email: "another_user_policy@test.com",
        password: "password",
        password_confirmation: "password",
        role: :employee
      )
    end

    it "returns all users for reviewers" do
      scope = described_class::Scope.new(reviewer, User.all).resolve

      expect(scope).to include(reviewer, employee, target_user, another_user)
    end

    it "returns none for employees" do
      scope = described_class::Scope.new(employee, User.all).resolve

      expect(scope).to be_empty
    end

    it "returns none for nil user" do
      scope = described_class::Scope.new(nil, User.all).resolve

      expect(scope).to be_empty
    end
  end
end
