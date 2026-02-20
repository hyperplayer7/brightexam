class ExpensePolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    return false unless user

    owner? || user.reviewer?
  end

  def create?
    user&.employee?
  end

  def update?
    owner? && record.drafted?
  end

  def destroy?
    owner? && record.drafted?
  end

  def submit?
    owner? && record.drafted?
  end

  def approve?
    user&.reviewer? && record.submitted?
  end

  def reject?
    user&.reviewer? && record.submitted?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user

      if user.reviewer?
        scope.all
      else
        scope.where(user_id: user.id)
      end
    end
  end

  private

  def owner?
    user && record.user_id == user.id
  end
end
