module Api
  class SessionsController < ApplicationController
    before_action :authenticate_user!, only: %i[destroy me]

    def create
      user = User.find_by(email: params[:email].to_s.downcase)

      if user&.authenticate(params[:password])
        login!(user)
        render json: { data: user_payload(user) }, status: :ok
      else
        render_errors([ "invalid_credentials" ], :unauthorized)
      end
    end

    def destroy
      logout!
      head :no_content
    end

    def me
      render json: { data: user_payload(current_user) }, status: :ok
    end

    private

    def user_payload(user)
      {
        id: user.id,
        email: user.email,
        role: user.role
      }
    end
  end
end
