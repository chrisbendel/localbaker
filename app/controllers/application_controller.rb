class ApplicationController < ActionController::Base
  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user, :authenticated?

  before_action :set_honeybadger_context

  private

  def set_honeybadger_context
    Honeybadger.context(user_id: current_user.id, email: current_user.email) if current_user
  end

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
    @current_user = user
  end

  def sign_out
    reset_session
    @current_user = nil
  end

  def require_authentication!
    unless authenticated?
      session[:return_to] = request.fullpath
      redirect_to new_session_path, alert: "Sign in to continue."
    end
  end

  def after_sign_in_path
    path = session.delete(:return_to)
    return path if path&.start_with?("/") && path != new_session_path

    if current_user.store&.persisted?
      dashboard_path
    else
      explore_path
    end
  end

  def set_store
    @store = current_user.store
  end

  def require_store!
    @store = set_store
    redirect_to new_dashboard_store_path, alert: "You must create a store first." unless @store&.persisted?
  end
end
