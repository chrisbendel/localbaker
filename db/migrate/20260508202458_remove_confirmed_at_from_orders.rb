class RemoveConfirmedAtFromOrders < ActiveRecord::Migration[8.1]
  # Single-form checkout refactor — Order existing means committed.
  # No more cart/pending state, so confirmed_at is redundant.
  def change
    remove_column :orders, :confirmed_at, :datetime
  end
end
