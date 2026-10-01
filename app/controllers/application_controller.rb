class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  helper_method :pending_follow_request_count

  private

  def pending_follow_request_count
    return 0 if current_user.nil?

    @pending_follow_request_count ||=
      current_user.follow_requests_received.pending.count
  end

  # Devise only permits :email and :password by default; allow the profile
  # fields to be set at sign up.
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up,
      keys: [ :username, :email, :password, :password_confirmation ])

    devise_parameter_sanitizer.permit(:account_update,
      keys: [ :username, :email, :password, :password_confirmation,
        :current_password ])
  end

  def after_sign_in_path_for(resource)
    posts_path
  end
end
