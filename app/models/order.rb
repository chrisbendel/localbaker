class Order < ApplicationRecord
  belongs_to :user
  belongs_to :event
  has_many :order_items, dependent: :destroy
  has_many :event_products, through: :order_items

  validates :user_id, uniqueness: {scope: :event_id}
  validate :delivery_address_within_zone, if: :delivery_address_changed?

  before_validation { self.delivery_address = AddressParser.normalize(delivery_address) if delivery_address.present? }

  def delivery_address_within_zone?
    return true if delivery_address.blank?
    DeliveryZoneValidator.valid_for_delivery?(event.store, delivery_address)
  end

  def total_price_cents
    order_items.sum do |item|
      item.quantity * item.unit_price_cents
    end
  end

  def total_price
    total_price_cents / 100.0
  end

  def confirmed?
    confirmed_at.present?
  end

  def confirm!
    update!(confirmed_at: Time.current)
  end

  def unconfirm!
    update!(confirmed_at: nil)
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
