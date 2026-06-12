class AddPaymentTrackingToOrders < ActiveRecord::Migration[8.1]
  # Payment happens off-platform (cash/Venmo at pickup); the baker just
  # records that it happened.
  def change
    add_column :orders, :paid_at, :datetime
    add_column :orders, :picked_up_at, :datetime
  end
end
