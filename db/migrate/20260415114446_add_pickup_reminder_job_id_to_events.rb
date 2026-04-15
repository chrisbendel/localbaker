class AddPickupReminderJobIdToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :pickup_reminder_job_id, :string
  end
end
