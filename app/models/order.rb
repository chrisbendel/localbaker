require "csv"

class Order < ApplicationRecord
  # Order existing = committed. There is no cart/pending state.
  # Single-form checkout creates the Order + OrderItems atomically.
  # Cancellation = destroy.

  CSV_HEADERS = %w[order_date customer_email items item_count subtotal_cents fulfillment pickup_time notes].freeze

  belongs_to :user
  belongs_to :event
  has_many :order_items, dependent: :destroy
  has_many :event_products, through: :order_items

  validates :user_id, uniqueness: {scope: :event_id}
  validate :delivery_address_within_zone, if: :delivery_requested?

  before_validation { self.delivery_address = AddressParser.normalize(delivery_address) if delivery_address.present? }

  def delivery_address_within_zone?
    return true if delivery_address.blank?
    DeliveryZoneValidator.valid_for_delivery?(event.store, delivery_address)
  end

  def delivery_requested?
    event.delivery_enabled? && delivery_address.present?
  end

  def total_price_cents
    order_items.sum do |item|
      item.quantity * item.unit_price_cents
    end
  end

  def total_price
    total_price_cents / 100.0
  end

  def cancel!
    OrderMailer.with(order: self).cancellation_email.deliver_later
    destroy!
  end

  # Render a relation as CSV for baker exports.
  # Eager-load order_items.event_product, user, and event before calling
  # to keep this O(orders) instead of O(orders * items).
  def self.to_csv(orders)
    CSV.generate do |csv|
      csv << CSV_HEADERS
      orders.each do |o|
        items = o.order_items.map { |i| "#{i.quantity}x #{i.event_product.name}" }.join(" | ")
        csv << [
          o.created_at.iso8601,
          o.user.email,
          items,
          o.order_items.sum(&:quantity),
          o.total_price_cents,
          o.delivery_address.present? ? "delivery" : "pickup",
          o.event.pickup_starts_at.iso8601,
          o.notes.to_s
        ]
      end
    end
  end

  private

  def delivery_address_within_zone
    if delivery_address.present? && event.store.delivery_zone_type.present?
      unless delivery_address_within_zone?
        errors.add(:delivery_address, "is outside the delivery zone")
      end
    end
  end
end
