class RenamePickupAtToPickupWindowOnEvents < ActiveRecord::Migration[8.1]
  def up
    rename_column :events, :pickup_at, :pickup_starts_at
    add_column :events, :pickup_ends_at, :datetime

    # Backfill existing records: default window end to 4 hours after start
    Event.reset_column_information
    Event.find_each do |event|
      next unless event.pickup_starts_at
      event.update_column(:pickup_ends_at, event.pickup_starts_at + 4.hours)
    end

    change_column_null :events, :pickup_ends_at, false
  end

  def down
    rename_column :events, :pickup_starts_at, :pickup_at
    remove_column :events, :pickup_ends_at
  end
end
