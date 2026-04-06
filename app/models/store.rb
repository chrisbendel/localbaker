class Store < ApplicationRecord
  belongs_to :user
  has_many :events, dependent: :destroy
  has_many :notifications, class_name: "StoreNotification", dependent: :destroy
  has_many :orders, through: :events

  has_one_attached :banner_image
  attr_accessor :remove_banner_image

  validates :name, presence: true
  validates :slug,
    presence: true,
    uniqueness: true,
    format: {with: /\A[a-z0-9-]+\z/i}

  before_validation { self.address = AddressParser.normalize(address) }

  def monetization_allowed?
    user.pro?
  end

  def active_orders?
    orders.joins(:event).where("events.pickup_at >= ?", Time.current).exists?
  end

  def location_display
    AddressParser.city_state(address)
  end

  def instagram_url
    "https://instagram.com/#{instagram_handle}" if instagram_handle.present?
  end

  def venmo_url
    "https://venmo.com/#{venmo_handle.sub("@", "")}" if venmo_handle.present?
  end

  def onboarding_complete?
    onboarding_steps.values.all?
  end

  def onboarding_steps
    {
      store_setup: address.present? && description.present?,
      event_created: events.any?,
      products_added: events.joins(:event_products).exists?,
      event_published: events.published.exists?
    }
  end
end
