class AddAddressToStores < ActiveRecord::Migration[8.1]
  def change
    add_column :stores, :address, :string
  end
end
