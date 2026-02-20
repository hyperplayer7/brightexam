module Api
  class ExpensesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_expense, only: %i[show update destroy submit approve reject]

    def index
      expenses_scope = policy_scope(Expense)
        .includes(:user, :reviewer)
        .order(created_at: :desc)

      if params[:status].present?
        allowed = Expense.statuses.keys
        if allowed.include?(params[:status])
          expenses_scope = expenses_scope.where(status: params[:status])
        end
      end

      @pagy, expenses = pagy(expenses_scope)

      render json: {
        data: expenses.map { |expense| expense_payload(expense) },
        pagination: {
          page: @pagy.page,
          pages: @pagy.pages,
          count: @pagy.count,
          items: @pagy.vars[:items]
        }
      }
    end

    def show
      authorize @expense
      render json: { data: expense_payload(@expense) }
    end

    def create
      expense = current_user.expenses.new(expense_params)
      authorize expense

      if expense.save
        render json: { data: expense_payload(expense) }, status: :created
      else
        render json: { errors: expense.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      authorize @expense

      if @expense.update(expense_params)
        render json: { data: expense_payload(@expense) }, status: :ok
      else
        render json: { errors: @expense.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @expense
      @expense.destroy!
      head :no_content
    end

    def submit
      authorize @expense, :submit?
      expense = Expenses::Submit.call(expense: @expense)
      render json: { data: expense_payload(expense) }, status: :ok
    end

    def approve
      authorize @expense, :approve?
      expense = Expenses::Approve.call(expense: @expense, actor: current_user)
      render json: { data: expense_payload(expense) }, status: :ok
    end

    def reject
      authorize @expense, :reject?
      expense = Expenses::Reject.call(
        expense: @expense,
        actor: current_user,
        rejection_reason: params[:rejection_reason]
      )
      render json: { data: expense_payload(expense) }, status: :ok
    end

    private

    def set_expense
      @expense = Expense.find(params[:id])
    end

    def expense_params
      params.require(:expense).permit(
        :amount_cents,
        :currency,
        :description,
        :merchant,
        :incurred_on,
        :lock_version
      )
    end

    def expense_payload(expense)
      {
        id: expense.id,
        user_id: expense.user_id,
        reviewer_id: expense.reviewer_id,
        amount_cents: expense.amount_cents,
        currency: expense.currency,
        description: expense.description,
        merchant: expense.merchant,
        incurred_on: expense.incurred_on,
        status: expense.status,
        submitted_at: expense.submitted_at,
        reviewed_at: expense.reviewed_at,
        rejection_reason: expense.rejection_reason,
        lock_version: expense.lock_version,
        created_at: expense.created_at,
        updated_at: expense.updated_at
      }
    end
  end
end
