module Api
  class UsersController < ApplicationController
    before_action :authenticate_user!
    before_action :set_user, only: %i[update_role]

    def index
      authorize User

      users = policy_scope(User).order(:email)
      render json: { data: users.map { |user| user_payload(user, include_created_at: true) } }, status: :ok
    end

    def update_role
      authorize @user, :update_role?

      if @user.id == current_user.id
        return render_errors([ "cannot_change_own_role" ], :unprocessable_entity)
      end

      role = params[:role].to_s
      unless User.roles.key?(role)
        return render_errors([ "role must be one of: #{User.roles.keys.join(', ')}" ], :unprocessable_entity)
      end

      @user.update!(role: role)

      render json: { data: user_payload(@user) }, status: :ok
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_payload(user, include_created_at: false)
      payload = {
        id: user.id,
        email: user.email,
        role: user.role
      }
      payload[:created_at] = user.created_at if include_created_at
      payload
    end
  end
end
