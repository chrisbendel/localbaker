class ContactsController < ApplicationController
  rate_limit to: 2, within: 1.minute, only: :create,
    with: -> { redirect_to new_contact_path, alert: "Too many requests. Please try again in a moment." }

  def new
  end

  def create
    name = params[:name].to_s.strip
    email = params[:email].to_s.strip
    message = params[:message].to_s.strip

    if message.blank?
      flash.now[:alert] = "Message can't be blank."
      return render :new, status: :unprocessable_entity
    end

    ContactMailer.feedback(name:, email:, message:).deliver_later
    redirect_to root_path, notice: "Thanks for reaching out! I'll get back to you soon."
  end
end
