class StoreNotification < ApplicationRecord
  belongs_to :user
  belongs_to :store

  before_validation :ensure_unsubscribe_token, on: :create

  validates :unsubscribe_token, presence: true, uniqueness: true
  validates :user_id, uniqueness: {scope: :store_id}

  # Logged-out subscribes are double opt-in, but the pending state is never
  # stored: the emailed token carries {email, store_id}, and redeeming it
  # creates the subscription. A StoreNotification row therefore always means
  # a confirmed subscriber — no scope to remember when emailing.
  #
  # Tokens are signed (tamper-proof), expiring, and deliberately reusable
  # within their window: email scanners prefetch links, so redemption is
  # idempotent. Clicking the link proves inbox ownership — same trust as OTP.
  TOKEN_TTL = 7.days

  def self.generate_confirmation_token(email:, store:)
    verifier.generate({"email" => email, "store_id" => store.id}, expires_in: TOKEN_TTL)
  end

  # Returns the (created or existing) notification, or nil if the token is
  # invalid or expired.
  def self.redeem_confirmation_token(token)
    data = verifier.verified(token)
    return nil unless data

    user = User.find_or_create_by!(email: data["email"])
    user.store_notifications.find_or_create_by(store_id: data["store_id"])
  end

  def self.verifier
    Rails.application.message_verifier("store_subscription")
  end
  private_class_method :verifier

  private

  def ensure_unsubscribe_token
    self.unsubscribe_token ||= generate_token
  end

  def generate_token
    loop do
      token = SecureRandom.hex(20)
      break token unless self.class.exists?(unsubscribe_token: token)
    end
  end
end
