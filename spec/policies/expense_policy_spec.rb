# spec/policies/expense_policy_spec.rb
require "rails_helper"

RSpec.describe ExpensePolicy, type: :policy do
  subject(:policy) { described_class.new(user, expense) }

  let(:owner) do
    User.create!(
      email: "owner@test.com",
      password: "password",
      password_confirmation: "password",
      role: :employee
    )
  end

  let(:other_employee) do
    User.create!(
      email: "other@test.com",
      password: "password",
      password_confirmation: "password",
      role: :employee
    )
  end

  let(:reviewer) do
    User.create!(
      email: "reviewer@test.com",
      password: "password",
      password_confirmation: "password",
      role: :reviewer
    )
  end

  # Helper to build expenses with specific status/owner
  def build_expense(owner:, status:)
    Expense.create!(
      user: owner,
      amount_cents: 1000,
      currency: "USD",
      merchant: "Test",
      description: "Test",
      incurred_on: Date.new(2026, 2, 20),
      status: status
    )
  end

  describe "permissions (employee)" do
    context "when employee owns the expense" do
      let(:user) { owner }

      context "drafted" do
        let(:expense) { build_expense(owner: owner, status: :drafted) }

        it { is_expected.to permit_action(:show) }
        it { is_expected.to permit_action(:update) }
        it { is_expected.to permit_action(:destroy) }
        it { is_expected.to permit_action(:submit) }

        it { is_expected.not_to permit_action(:approve) }
        it { is_expected.not_to permit_action(:reject) }
      end

      context "submitted" do
        let(:expense) { build_expense(owner: owner, status: :submitted) }

        it { is_expected.to permit_action(:show) }

        it { is_expected.not_to permit_action(:update) }
        it { is_expected.not_to permit_action(:destroy) }
        it { is_expected.not_to permit_action(:submit) }
        it { is_expected.not_to permit_action(:approve) }
        it { is_expected.not_to permit_action(:reject) }
      end

      context "approved" do
        let(:expense) { build_expense(owner: owner, status: :approved) }

        it { is_expected.to permit_action(:show) }
        it { is_expected.not_to permit_action(:update) }
        it { is_expected.not_to permit_action(:destroy) }
        it { is_expected.not_to permit_action(:submit) }
      end

      context "rejected" do
        let(:expense) { build_expense(owner: owner, status: :rejected) }

        it { is_expected.to permit_action(:show) }
        it { is_expected.not_to permit_action(:update) }
        it { is_expected.not_to permit_action(:destroy) }
        it { is_expected.not_to permit_action(:submit) }
      end
    end

    context "when employee does NOT own the expense" do
      let(:user) { other_employee }

      context "drafted" do
        let(:expense) { build_expense(owner: owner, status: :drafted) }

        it { is_expected.not_to permit_action(:show) }     # assumes employees can't see others
        it { is_expected.not_to permit_action(:update) }
        it { is_expected.not_to permit_action(:destroy) }
        it { is_expected.not_to permit_action(:submit) }
      end

      context "submitted" do
        let(:expense) { build_expense(owner: owner, status: :submitted) }

        it { is_expected.not_to permit_action(:show) }     # assumes employees can't see others
        it { is_expected.not_to permit_action(:update) }
        it { is_expected.not_to permit_action(:destroy) }
        it { is_expected.not_to permit_action(:submit) }
      end
    end
  end

  describe "permissions (reviewer)" do
    let(:user) { reviewer }

    context "drafted" do
      let(:expense) { build_expense(owner: owner, status: :drafted) }

      it { is_expected.to permit_action(:show) } # reviewers can see all
      it { is_expected.not_to permit_action(:approve) }
      it { is_expected.not_to permit_action(:reject) }
      it { is_expected.not_to permit_action(:update) }
      it { is_expected.not_to permit_action(:destroy) }
      it { is_expected.not_to permit_action(:submit) }
    end

    context "submitted" do
      let(:expense) { build_expense(owner: owner, status: :submitted) }

      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_action(:approve) }
      it { is_expected.to permit_action(:reject) }

      it { is_expected.not_to permit_action(:update) }
      it { is_expected.not_to permit_action(:destroy) }
      it { is_expected.not_to permit_action(:submit) }
    end

    context "approved" do
      let(:expense) { build_expense(owner: owner, status: :approved) }

      it { is_expected.to permit_action(:show) }
      it { is_expected.not_to permit_action(:approve) }
      it { is_expected.not_to permit_action(:reject) }
    end

    context "rejected" do
      let(:expense) { build_expense(owner: owner, status: :rejected) }

      it { is_expected.to permit_action(:show) }
      it { is_expected.not_to permit_action(:approve) }
      it { is_expected.not_to permit_action(:reject) }
    end
  end

  describe "Scope" do
    let!(:owned_draft)   { build_expense(owner: owner, status: :drafted) }
    let!(:owned_submit)  { build_expense(owner: owner, status: :submitted) }
    let!(:other_submit)  { build_expense(owner: other_employee, status: :submitted) }

    it "returns only owned expenses for employees" do
      scope = described_class::Scope.new(owner, Expense.all).resolve
      expect(scope).to contain_exactly(owned_draft, owned_submit)
    end

    it "returns all expenses for reviewers" do
      scope = described_class::Scope.new(reviewer, Expense.all).resolve
      expect(scope).to contain_exactly(owned_draft, owned_submit, other_submit)
    end
  end
end
