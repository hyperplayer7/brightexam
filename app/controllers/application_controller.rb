class ApplicationController < ActionController::API
  include ActionController::Cookies
  include Pagy::Backend
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :handle_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid
  rescue_from ActiveRecord::StaleObjectError, with: :handle_stale_object
  rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def authenticate_user!
    return if current_user

    render_errors([ "unauthorized" ], :unauthorized)
  end

  def login!(user)
    reset_session
    session[:user_id] = user.id
  end

  def logout!
    reset_session
  end

  def handle_not_authorized
    render_errors([ "forbidden" ], :forbidden)
  end

  def handle_not_found
    render_errors([ "not_found" ], :not_found)
  end

  def handle_record_invalid(exception)
    render_errors(exception.record.errors.full_messages, :unprocessable_entity)
  end

  def handle_stale_object
    render_errors([ "stale_object" ], :conflict)
  end

  def handle_parameter_missing(exception)
    render_errors([ exception.message ], :bad_request)
  end

  def render_errors(messages, status)
    render json: { errors: Array(messages) }, status: status
  end
end
