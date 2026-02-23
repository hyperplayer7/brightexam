module Api
  class CategoriesController < ApplicationController
    before_action :authenticate_user!

    def index
      categories = Category.order(:name)
      render json: {
        data: categories.map { |category| category_payload(category) }
      }, status: :ok
    end

    def create
      return render_errors([ "forbidden" ], :forbidden) unless current_user&.reviewer?

      category = Category.new(category_params)
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
