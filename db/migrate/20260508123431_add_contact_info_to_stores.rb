class AddContactInfoToStores < ActiveRecord::Migration[8.1]
  def change
    add_column :stores, :contact_email, :string
    add_column :stores, :contact_phone, :string
  end
end
