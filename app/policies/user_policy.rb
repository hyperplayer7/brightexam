class UserPolicy < ApplicationPolicy
  def index?
    user&.reviewer?
  end

  def update_role?
    user&.reviewer?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user&.reviewer?

      scope.all
    end
  end
end
