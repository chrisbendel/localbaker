class AddUniqueIndexOnOrdersUserEvent < ActiveRecord::Migration[8.1]
  def change
    # Backs the model-level `validates :user_id, uniqueness: {scope: :event_id}`
    # in app/models/order.rb. Without this, concurrent find_or_create_by calls
    # (multi-tab, retries) can race past the validation and create duplicates.
    #
    # Existing index_orders_on_user_id is kept as the leading-column index.
    # event_id keeps its own index for queries scoped by event alone.
    add_index :orders, [:user_id, :event_id], unique: true
  end
end
