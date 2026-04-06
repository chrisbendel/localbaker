class Event < ApplicationRecord
  belongs_to :store
  has_many :event_products, dependent: :destroy
  has_many :orders, dependent: :restrict_with_error

  validates :name, presence: true
  validates :orders_close_at, presence: true
  validates :pickup_at, presence: true

  before_validation { self.pickup_address = AddressParser.normalize(pickup_address) }

  validate :orders_close_before_pickup
  validate :must_have_products, if: :published?
  scope :published, -> { where.not(published_at: nil) }
  scope :draft, -> { where(published_at: nil) }
  scope :current, -> { published.where("pickup_at >= ?", 3.days.ago) }
  scope :active_published, -> { published.where("pickup_at >= ?", Time.current) }

  attribute :repeat_interval, :integer
  enum :repeat_interval, {no_repeat: 0, weekly: 1, biweekly: 2}, default: :no_repeat

  def address
    effective_pickup_address
  end

  def location_display
    AddressParser.city_state(address)
  end

  def effective_pickup_address
    pickup_address.presence || store.address.presence
  end

  def published?
    published_at.present?
  end

  def draft?
    !published?
  end

  def orders_open?
    published? && Time.current < orders_close_at
  end

  def orders_closed?
    published? && Time.current >= orders_close_at
  end

  def past?
    Time.current > pickup_at
  end

  def publish!
    transaction do
      update!(published_at: Time.current)
      spawn_next_event if !no_repeat?
    end
  end

  def spawn_next_event
    interval_weeks = ((repeat_interval == "biweekly") ? 2 : 1)

    new_event = dup
    new_event.name = "Copy of #{name}"
    new_event.published_at = nil
    new_event.pickup_at = pickup_at + interval_weeks.weeks if pickup_at
    new_event.orders_close_at = orders_close_at + interval_weeks.weeks if orders_close_at
    new_event.save!(validate: false)

    event_products.each do |ep|
      new_ep = ep.dup
      new_ep.event = new_event
      if ep.image.attached?
        new_ep.image.attach(ep.image.blob)
      end
      new_ep.save!
    end

    new_event
  end

  private

  def orders_close_before_pickup
    return unless orders_close_at && pickup_at

    if orders_close_at >= pickup_at
      errors.add(:orders_close_at, "must be before the pickup time")
    end
  end

  def must_have_products
    if event_products.empty?
      errors.add(:base, "You must add at least one product before publishing.")
    end
  end
end
