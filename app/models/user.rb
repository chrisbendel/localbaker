class User < ApplicationRecord
  FREE_EVENT_LIMIT = 1

  has_one :store, dependent: :destroy
  has_many :store_notifications, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :order_items, through: :orders

  before_validation :normalize_email

  validates :email,
    presence: true,
    format: {with: URI::MailTo::EMAIL_REGEXP},
    uniqueness: {case_sensitive: false}

  enum :plan, {free: "free", pro: "pro"}, default: "free"

  def at_event_limit?
    return false if pro?
    store&.events&.active_published&.count.to_i >= FREE_EVENT_LIMIT
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
