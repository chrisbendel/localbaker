class Store < ApplicationRecord
  belongs_to :user
  geocoded_by :address
  has_many :events, dependent: :destroy
  has_many :notifications, class_name: "StoreNotification", dependent: :destroy
  has_many :orders, through: :events

  GALLERY_PHOTO_LIMIT = 6

  has_one_attached :photo
  has_many_attached :gallery_photos
  attr_accessor :remove_photo

  validates :name, presence: true
  validates :slug,
    presence: true,
    uniqueness: true,
    format: {with: /\A[a-z0-9-]+\z/i}
  validates :facebook_url, :website_url, :paypal_url,
    format: {with: /\Ahttps?:\/\/.+\z/i, message: "must be a valid URL"},
    allow_blank: true
  validates :instagram_handle,
    format: {with: /\A@?[\w.]+\z/, message: "should be a valid Instagram handle"},
    allow_blank: true
  validates :venmo_handle,
    format: {with: /\A@?[\w-]+\z/, message: "should be a valid Venmo handle"},
    allow_blank: true
  validates :bio, length: {maximum: 1000}, allow_blank: true

  normalizes :bio, :description, :instagram_handle, :facebook_url, :website_url, :venmo_handle, :paypal_url, with: -> { it.strip.presence }
  normalizes :address, with: -> { AddressParser.normalize(it).presence }
  validate :slug_cannot_change_with_active_orders
  before_save :purge_attachments_if_requested
  after_commit :geocode_location, if: :saved_change_to_address?

  scope :geocoded, -> { where.not(latitude: nil, longitude: nil) }
  scope :listed, -> { where(listed: true) }

  def monetization_allowed?
    user.pro?
  end

  # The storefront hero image. Explicitly picked via cover_photo_id, falling
  # back to the first gallery photo. A stale or foreign id falls through to
  # the fallback — no cleanup needed when photos are purged.
  def cover_photo
    gallery_photos.find_by(id: cover_photo_id) || gallery_photos.first
  end

  def active_orders?
    orders.joins(:event).where("events.pickup_starts_at >= ?", Time.current).exists?
  end

  def location_display
    AddressParser.city_state(address)
  end

  def instagram_url
    "https://instagram.com/#{instagram_handle.sub("@", "")}" if instagram_handle.present?
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

  def slug_cannot_change_with_active_orders
    if slug_changed? && persisted? && active_orders?
      errors.add(:slug, "cannot be changed while orders are pending")
    end
  end

  def purge_attachments_if_requested
    photo.purge if remove_photo == "1"
  end

  def geocode_location
    GeocodeStoreJob.perform_now(id)
  end
end
