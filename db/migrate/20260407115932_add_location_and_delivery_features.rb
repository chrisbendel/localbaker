class AddLocationAndDeliveryFeatures < ActiveRecord::Migration[8.1]
  def change
    # Location/Geocoding columns for stores
    add_column :stores, :latitude, :decimal, precision: 10, scale: 6
    add_column :stores, :longitude, :decimal, precision: 10, scale: 6
    add_index :stores, [:latitude, :longitude]

    # Delivery zone configuration for stores
    add_column :stores, :delivery_zone_type, :string, default: nil
    add_column :stores, :delivery_zone_radius_miles, :integer, default: 25
    add_column :stores, :delivery_zone_postal_codes, :text, default: nil

    # Delivery mode for events
    add_column :events, :delivery_enabled, :boolean, default: false

    # Delivery address for orders
    add_column :orders, :delivery_address, :text
  end
end
