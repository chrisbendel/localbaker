class AddUniqueIndexOnOrdersUserEvent < ActiveRecord::Migration[8.1]
  def up
    duplicates = select_all(<<~SQL).to_a
      SELECT user_id, event_id, COUNT(*) AS count, ARRAY_AGG(id) AS order_ids
      FROM orders
      GROUP BY user_id, event_id
      HAVING COUNT(*) > 1
    SQL

    if duplicates.any?
      report = duplicates.map { |d| "  user_id=#{d["user_id"]} event_id=#{d["event_id"]} count=#{d["count"]} ids=#{d["order_ids"]}" }.join("\n")
      raise ActiveRecord::IrreversibleMigration, <<~MSG
        Refusing to add unique index — duplicate orders exist for the same (user_id, event_id).

        #{report}

        Resolve manually before re-running this migration. Each row above represents
        multiple Order records for the same user on the same event. Decide which one
        to keep (likely the most recently confirmed, or the one with the most order
        items) and destroy the rest. Then re-run `bin/rails db:migrate`.

        Helpful console queries:
          dupes = Order.group(:user_id, :event_id).having("count(*) > 1").count
          # for each (user_id, event_id) group:
          # Order.where(user_id: u, event_id: e).order(created_at: :desc).each { |o| puts [o.id, o.confirmed_at, o.order_items.count].inspect }
      MSG
    end

    # Backs the model-level `validates :user_id, uniqueness: {scope: :event_id}`
    # in app/models/order.rb. Without this, concurrent find_or_create_by calls
    # (multi-tab, retries) can race past the validation and create duplicates.
    #
    # Existing index_orders_on_user_id is kept as the leading-column index.
    # event_id keeps its own index for queries scoped by event alone.
    add_index :orders, [:user_id, :event_id], unique: true
  end

  def down
    remove_index :orders, [:user_id, :event_id]
  end
end
