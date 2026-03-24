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

  # eventually check `user.subscription_active?` when integrating payments
  def monetization_allowed?
    true
  end

  def active_orders?
    orders.joins(:event).where("events.pickup_at >= ?", Time.current).exists?
  end
end
