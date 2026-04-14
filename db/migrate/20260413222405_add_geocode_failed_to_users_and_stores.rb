class AddGeocodeFailedToUsersAndStores < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :geocode_failed, :boolean, default: false, null: false
    add_column :stores, :geocode_failed, :boolean, default: false, null: false
    add_column :stores, :listed, :boolean, default: true, null: false
  end
end
