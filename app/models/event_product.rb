class EventProduct < ApplicationRecord
  belongs_to :event
  has_many :order_items
  has_one_attached :image

  validates :name, presence: true, uniqueness: {scope: :event_id}
  validates :quantity, numericality: {greater_than_or_equal_to: 0}
  validates :price_cents, numericality: {greater_than_or_equal_to: 0}

  after_destroy :unpublish_event_if_no_products

  def price
    return if price_cents.blank?
    price_cents.to_f / 100
  end

  def price=(value)
    self.price_cents = if value.present?
      (value.to_f * 100).round
    end
  end

  def price_formatted
    "$%.2f" % price
  end

  def sold
    order_items.sum(:quantity)
  end

  def remaining
    [quantity - sold, 0].max
  end

  def available?
    remaining > 0
  end

  private

  def unpublish_event_if_no_products
    return unless event.published?

    if !event.event_products.exists?
      event.update(published_at: nil)
    end
  end
end
