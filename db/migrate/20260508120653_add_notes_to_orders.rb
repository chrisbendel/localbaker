class AddNotesToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :notes, :text
  end
end
