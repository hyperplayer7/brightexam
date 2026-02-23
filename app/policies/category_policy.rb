class CategoryPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def create?
    user&.reviewer?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user

      scope.all
    end
  end
end
