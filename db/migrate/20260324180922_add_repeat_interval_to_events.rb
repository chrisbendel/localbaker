class AddRepeatIntervalToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :repeat_interval, :integer
  end
end
