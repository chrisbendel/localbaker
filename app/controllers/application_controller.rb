class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user, :authenticated?

  private

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = if session[:user_id]
      User.find_by(id: session[:user_id])
    end
  end

  def authenticated?
    current_user.present?
  end

  def sign_in(user)
    return_to = session[:return_to]
    reset_session
    session[:user_id] = user.id
    session[:return_to] = return_to if return_to.present?
  end

  def sign_out
    reset_session
  end

  def require_authentication!
    unless authenticated?
      session[:return_to] = request.fullpath
      redirect_to new_session_path, alert: "Sign in to continue."
    end
  end

  def after_sign_in_path
    path = session.delete(:return_to)
    # Only redirect to internal paths to prevent open redirect attacks
    (path&.start_with?("/") && path != new_session_path) ? path : root_path
  end
end
