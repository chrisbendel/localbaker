class SessionsController < ApplicationController
  def new
    redirect_to dashboard_path if authenticated?
    session[:return_to] = params[:return_to] if params[:return_to].present?
  end

  # POST /session (send code)
  def create
    email = params.require(:email).downcase.strip
    user = User.find_or_initialize_by(email: email)

    if user.new_record?
      user.save!
    end

    begin
      login_code = LoginCode.generate_for(user)
    rescue
      # rate-limit hit, etc.
      flash.now[:alert] = "Too many requests. Please wait a bit and try again."
      return render :new, status: :too_many_requests
    end

    # Send the code asynchronously in production:
    SessionMailer.with(user: user).login_code(user, login_code.plain_code).deliver_now

    # You could store something like last_sent_email in session to prefill the verification form
    session[:login_email] = user.email

    redirect_to verify_session_path, notice: "We've sent a code to #{user.email}. It expires in 10 minutes."
  end

  # GET /session/verify (show code entry)
  def verify
    @prefill_email = session[:login_email]
  end

  # POST /session/confirm (submit code)
  def confirm
    email = params.require(:email).downcase.strip
    code = params.require(:code).to_s.strip

    user = User.find_by(email: email)

    if user.nil?
      flash.now[:alert] = "Invalid code or email."
      return render :verify, status: :unauthorized
    end

    login_code = LoginCode.active_for_user(user).order(created_at: :desc).first
    if login_code&.verify(code)
      sign_in(user)
      session.delete(:login_email)
      redirect_to after_sign_in_path, notice: "Signed in!"
    else
      flash.now[:alert] = "Invalid code or expired. Request a new code if needed."
      @prefill_email = email
      render :verify, status: :unauthorized
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to root_path, notice: "Signed out"
  end
end
