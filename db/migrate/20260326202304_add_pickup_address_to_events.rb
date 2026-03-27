class AddPickupAddressToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :pickup_address, :string
  end
end
