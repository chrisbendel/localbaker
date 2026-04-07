class AddProfileFieldsToStores < ActiveRecord::Migration[8.1]
  def change
    add_column :stores, :bio, :text
    add_column :stores, :instagram_handle, :string
    add_column :stores, :facebook_url, :string
    add_column :stores, :website_url, :string
    add_column :stores, :venmo_handle, :string
    add_column :stores, :paypal_url, :string
  end
end
