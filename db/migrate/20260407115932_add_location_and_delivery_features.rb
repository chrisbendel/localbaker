class AddLocationAndDeliveryFeatures < ActiveRecord::Migration[8.1]
  def change
    # NOTE: All columns added in this migration (latitude, longitude, delivery_zone_*,
    # delivery_enabled, delivery_address) were previously added to schema.rb without
    # creating a migration. This empty migration serves as a placeholder to acknowledge
    # the schema state at version 2026_04_07_115932. New columns should be added here.
    #
    # See AGENTS.md: Database Migrations section for guidance on keeping schema.rb and
    # migration files in sync.
  end
end
