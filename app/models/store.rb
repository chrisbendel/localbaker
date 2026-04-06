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
  validates :facebook_url, :website_url, :paypal_url,
    format: {with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL"},
    allow_blank: true
  validates :instagram_handle,
    format: {with: /\A@?[\w.]+\z/, message: "should be a valid Instagram handle"},
    allow_blank: true
  validates :venmo_handle,
    format: {with: /\A@?[\w-]+\z/, message: "should be a valid Venmo handle"},
    allow_blank: true
  validates :bio, length: {maximum: 1000}, allow_blank: true

  before_validation { self.address = AddressParser.normalize(address) }
  before_validation :nilify_blank_profile_fields
  validate :slug_cannot_change_with_active_orders
  before_save :purge_banner_image_if_requested

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

  private

  def nilify_blank_profile_fields
    self.bio = nil if bio.blank?
    self.instagram_handle = nil if instagram_handle.blank?
    self.facebook_url = nil if facebook_url.blank?
    self.website_url = nil if website_url.blank?
    self.venmo_handle = nil if venmo_handle.blank?
    self.paypal_url = nil if paypal_url.blank?
  end

  def slug_cannot_change_with_active_orders
    if slug_changed? && persisted? && active_orders?
      errors.add(:slug, "cannot be changed while orders are pending")
    end
  end

  def purge_banner_image_if_requested
    banner_image.purge if remove_banner_image == "1"
  end
end
