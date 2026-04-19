class User < ApplicationRecord
  pay_customer default_payment_processor: :stripe

  FREE_EVENT_LIMIT = 3

  has_one :store, dependent: :destroy
  has_many :store_notifications, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :order_items, through: :orders

  geocoded_by :address

  normalizes :address, with: -> { AddressParser.normalize(it).presence }

  before_validation :normalize_email
  after_commit :geocode_location, if: :saved_change_to_address?

  scope :geocoded, -> { where.not(latitude: nil, longitude: nil) }

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

  def geocode_location
    GeocodeUserJob.perform_now(id)
  end
end
