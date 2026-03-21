class Order < ApplicationRecord
  belongs_to :user
  belongs_to :event
  has_many :order_items, dependent: :destroy
  has_many :event_products, through: :order_items

  validates :user_id, uniqueness: {scope: :event_id}

  def total_price_cents
    order_items.sum do |item|
      item.quantity * item.unit_price_cents
    end
  end

  def total_price
    total_price_cents / 100.0
  end
end
