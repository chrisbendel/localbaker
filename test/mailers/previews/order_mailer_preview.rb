# Preview all emails at http://localhost:3000/rails/mailers/order_mailer
class OrderMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/order_mailer/confirmation_email
  def confirmation_email
    OrderMailer.with(order: sample_order).confirmation_email
  end

  # Preview this email at http://localhost:3000/rails/mailers/order_mailer/pickup_reminder
  def pickup_reminder
    OrderMailer.with(order: sample_order).pickup_reminder
  end

  private

  def sample_order
    Order.joins(:order_items).first
  end
end
