module Api
  class CategoriesController < ApplicationController
    before_action :authenticate_user!

    def index
      authorize Category
      categories = policy_scope(Category).order(:name)
      render json: {
        data: categories.map { |category| category_payload(category) }
      }, status: :ok
    end

    def create
      category = Category.new(category_params)
      authorize category

      if category.save
        render json: { data: category_payload(category) }, status: :created
      else
        render json: { errors: category.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def category_params
      params.require(:category).permit(:name)
    end

    def category_payload(category)
      {
        id: category.id,
        name: category.name
      }
    end
  end
end
