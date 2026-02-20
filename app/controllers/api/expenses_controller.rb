module Api
  class ExpensesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_expense, only: %i[show update destroy submit approve reject audit_logs]

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

      @pagy, expenses = pagy(expenses_scope, limit: 5)

      render json: {
        data: expenses.map { |expense| expense_payload(expense) },
        pagination: {
          page: @pagy.page,
          pages: @pagy.pages,
          count: @pagy.count,
          items: @pagy.vars[:limit] || @pagy.vars[:items]
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
        Expenses::AuditLogger.log!(
          expense: expense,
          actor: current_user,
          action: "expense.created",
          to_status: expense.status
        )
        render json: { data: expense_payload(expense) }, status: :created
      else
        render json: { errors: expense.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      authorize @expense

      from_status = @expense.status
      if @expense.update(expense_params)
        Expenses::AuditLogger.log!(
          expense: @expense,
          actor: current_user,
          action: "expense.updated",
          from_status: from_status,
          to_status: @expense.status,
          metadata: {
            previous_changes: @expense.previous_changes
          }
        )
        render json: { data: expense_payload(@expense) }, status: :ok
      else
        render json: { errors: @expense.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @expense
      Expenses::AuditLogger.log!(
        expense: @expense,
        actor: current_user,
        action: "expense.deleted",
        from_status: @expense.status,
        metadata: {
          snapshot: expense_delete_snapshot(@expense)
        }
      )
      @expense.destroy!
      head :no_content
    end

    def submit
      authorize @expense, :submit?
      from_status = @expense.status
      expense = Expenses::Submit.call(expense: @expense)
      Expenses::AuditLogger.log!(
        expense: expense,
        actor: current_user,
        action: "expense.submitted",
        from_status: from_status,
        to_status: expense.status
      )
      render json: { data: expense_payload(expense) }, status: :ok
    end

    def approve
      authorize @expense, :approve?
      from_status = @expense.status
      expense = Expenses::Approve.call(expense: @expense, actor: current_user)
      Expenses::AuditLogger.log!(
        expense: expense,
        actor: current_user,
        action: "expense.approved",
        from_status: from_status,
        to_status: expense.status
      )
      render json: { data: expense_payload(expense) }, status: :ok
    end

    def reject
      authorize @expense, :reject?
      from_status = @expense.status
      expense = Expenses::Reject.call(
        expense: @expense,
        actor: current_user,
        rejection_reason: params[:rejection_reason]
      )
      Expenses::AuditLogger.log!(
        expense: expense,
        actor: current_user,
        action: "expense.rejected",
        from_status: from_status,
        to_status: expense.status,
        metadata: {
          rejection_reason: expense.rejection_reason
        }
      )
      render json: { data: expense_payload(expense) }, status: :ok
    end

    def audit_logs
      authorize @expense, :show?

      logs = @expense.audit_logs.includes(:actor).order(created_at: :asc)
      render json: { data: logs.map { |log| audit_log_payload(log) } }, status: :ok
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
        user: user_payload(expense.user),
        reviewer: expense.reviewer ? user_payload(expense.reviewer) : nil,
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

    def user_payload(user)
      {
        id: user.id,
        email: user.email,
        role: user.role
      }
    end

    def audit_log_payload(log)
      {
        id: log.id,
        action: log.action,
        from_status: log.from_status,
        to_status: log.to_status,
        metadata: log.metadata,
        actor: {
          id: log.actor&.id,
          email: log.actor&.respond_to?(:email) ? log.actor.email : nil,
          role: log.actor&.respond_to?(:role) ? log.actor.role : nil
        },
        created_at: log.created_at
      }
    end

    def expense_delete_snapshot(expense)
      {
        amount_cents: expense.amount_cents,
        currency: expense.currency,
        merchant: expense.merchant,
        description: expense.description,
        incurred_on: expense.incurred_on,
        status: expense.status,
        submitted_at: expense.submitted_at,
        reviewed_at: expense.reviewed_at,
        reviewer_id: expense.reviewer_id,
        rejection_reason: expense.rejection_reason
      }
    end
  end
end
