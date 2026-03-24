class Event < ApplicationRecord
  belongs_to :store
  has_many :event_products, dependent: :destroy
  has_many :orders, dependent: :restrict_with_error

  validates :name, presence: true
  validates :orders_close_at, presence: true
  validates :pickup_at, presence: true

  validate :orders_close_before_pickup
  validate :must_have_products, if: :published?
  scope :published, -> { where.not(published_at: nil) }
  scope :draft, -> { where(published_at: nil) }

  def published?
    published_at.present?
  end

  def draft?
    !published?
  end

  def publish!
    update!(published_at: Time.current)
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
