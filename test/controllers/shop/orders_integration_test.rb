require "test_helper"

class Shop::OrdersIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @baker = User.create!(email: "baker-#{SecureRandom.hex}@example.com", plan: "pro")
    @store = Store.create!(name: "Test Bakery", slug: "test-bakery-#{SecureRandom.hex}", user: @baker, address: "123 Main St")
    @event = @store.events.create!(
      name: "Big Bake",
      orders_close_at: 1.day.from_now,
      pickup_starts_at: 2.days.from_now,
      pickup_ends_at: 2.days.from_now + 4.hours
    )
    @product = @event.event_products.create!(name: "Sourdough", quantity: 10, price_cents: 1000)
    @event.publish!

    @customer = User.create!(email: "customer-#{SecureRandom.hex}@example.com")
    sign_in_as(@customer)
    ActionMailer::Base.deliveries.clear
  end

  test "placing an order creates it and sends confirmation email" do
    assert_emails 1 do
      perform_enqueued_jobs do
        post shop_event_order_path(@store.slug, @event), params: {
          items: {@product.id.to_s => "2"},
          notes: "slice please"
        }
      end
    end

    assert_redirected_to shop_event_path(@store.slug, @event)
    order = @event.orders.find_by!(user: @customer)
    assert_equal 1, order.order_items.count
    assert_equal 2, order.order_items.first.quantity
    assert_equal "slice please", order.notes
  end

  test "placing an order with no items is rejected" do
    assert_no_difference "Order.count" do
      post shop_event_order_path(@store.slug, @event), params: {items: {}}
    end
    assert_redirected_to shop_event_path(@store.slug, @event)
    follow_redirect!
    assert_select ".alert", /at least one/i
  end

  test "placing an order over remaining stock is rejected" do
    assert_no_difference "Order.count" do
      post shop_event_order_path(@store.slug, @event), params: {
        items: {@product.id.to_s => "999"}
      }
    end
    assert_redirected_to shop_event_path(@store.slug, @event)
    follow_redirect!
    assert_select ".alert", /sold out|doesn't have/i
  end

  test "updating an existing order replaces items" do
    order = @event.orders.create!(user: @customer)
    order.order_items.create!(event_product: @product, quantity: 1, unit_price_cents: 1000)

    patch shop_event_order_path(@store.slug, @event), params: {
      items: {@product.id.to_s => "3"},
      notes: "updated note"
    }

    assert_redirected_to shop_event_path(@store.slug, @event)
    order.reload
    assert_equal 1, order.order_items.count
    assert_equal 3, order.order_items.first.quantity
    assert_equal "updated note", order.notes
  end

  test "cancelling an order destroys it" do
    order = @event.orders.create!(user: @customer)
    order.order_items.create!(event_product: @product, quantity: 1, unit_price_cents: 1000)

    assert_difference "Order.count", -1 do
      delete shop_event_order_path(@store.slug, @event)
    end

    assert_redirected_to shop_event_path(@store.slug, @event)
    follow_redirect!
    assert_select ".notice", /cancelled/i
  end

  test "creating a second order for the same event is rejected" do
    @event.orders.create!(user: @customer)

    assert_no_difference "Order.count" do
      post shop_event_order_path(@store.slug, @event), params: {
        items: {@product.id.to_s => "1"}
      }
    end
  end

  test "updating with qty=0 removes that item" do
    other_product = @event.event_products.create!(name: "Focaccia", quantity: 5, price_cents: 800)
    order = @event.orders.create!(user: @customer)
    order.order_items.create!(event_product: @product, quantity: 1, unit_price_cents: 1000)
    order.order_items.create!(event_product: other_product, quantity: 1, unit_price_cents: 800)

    patch shop_event_order_path(@store.slug, @event), params: {
      items: {@product.id.to_s => "0", other_product.id.to_s => "2"}
    }

    order.reload
    assert_equal 1, order.order_items.count
    assert_equal other_product.id, order.order_items.first.event_product_id
    assert_equal 2, order.order_items.first.quantity
  end

  test "cancellation sends an email to the customer" do
    order = @event.orders.create!(user: @customer)
    order.order_items.create!(event_product: @product, quantity: 1, unit_price_cents: 1000)

    assert_emails 1 do
      perform_enqueued_jobs do
        delete shop_event_order_path(@store.slug, @event)
      end
    end
  end

  test "creating an order on a closed event is rejected" do
    @event.update!(orders_close_at: 1.hour.ago)

    assert_no_difference "Order.count" do
      post shop_event_order_path(@store.slug, @event), params: {
        items: {@product.id.to_s => "1"}
      }
    end
    assert_redirected_to shop_event_path(@store.slug, @event)
    follow_redirect!
    assert_select ".alert", /closed/i
  end

  test "cancelling an order on a closed event is rejected" do
    order = @event.orders.create!(user: @customer)
    order.order_items.create!(event_product: @product, quantity: 1, unit_price_cents: 1000)
    @event.update!(orders_close_at: 1.hour.ago)

    assert_no_difference "Order.count" do
      delete shop_event_order_path(@store.slug, @event)
    end
    follow_redirect!
    assert_select ".alert", /closed/i
  end

  test "update accounts for own existing items when checking remaining stock" do
    # Product has 10 total. Customer already has 6. Should be able to update to 8.
    order = @event.orders.create!(user: @customer)
    order.order_items.create!(event_product: @product, quantity: 6, unit_price_cents: 1000)

    patch shop_event_order_path(@store.slug, @event), params: {
      items: {@product.id.to_s => "8"}
    }

    order.reload
    assert_equal 8, order.order_items.first.quantity
  end

  test "creating an order with delivery address saves it" do
    @event.update!(delivery_enabled: true)

    post shop_event_order_path(@store.slug, @event), params: {
      items: {@product.id.to_s => "1"},
      delivery_address: "123 Main St, Portland, OR 97201"
    }

    order = @event.orders.find_by!(user: @customer)
    assert_equal "123 Main St, Portland, OR 97201", order.delivery_address
  end

  test "blank notes save as nil" do
    post shop_event_order_path(@store.slug, @event), params: {
      items: {@product.id.to_s => "1"},
      notes: ""
    }
    order = @event.orders.find_by!(user: @customer)
    assert_nil order.notes
  end

  # --- Sellout scenarios ---
  # Sequential edge cases only. True concurrent oversell is deliberately
  # untested: the controller accepts rare oversell races by design (no row
  # locks — see Shop::OrdersController). Revisit alongside payments.

  test "buying exactly the remaining stock succeeds and sells the product out" do
    post shop_event_order_path(@store.slug, @event), params: {
      items: {@product.id.to_s => "10"}
    }

    assert @event.orders.exists?(user: @customer)
    assert_equal 0, @product.reload.remaining
    assert_not @product.available?
  end

  test "a second customer cannot order from a sold-out product" do
    @event.orders.create!(user: @customer)
      .order_items.create!(event_product: @product, quantity: 10, unit_price_cents: 1000)

    rival = User.create!(email: "rival-#{SecureRandom.hex}@example.com")
    sign_in_as(rival)

    assert_no_difference "Order.count" do
      post shop_event_order_path(@store.slug, @event), params: {
        items: {@product.id.to_s => "1"}
      }
    end
    follow_redirect!
    assert_select ".alert", /doesn't have that much left/i
  end

  test "a mixed order with one sold-out item is rejected wholesale, not partially" do
    second_product = @event.event_products.create!(name: "Baguette", quantity: 5, price_cents: 400)
    hoarder = User.create!(email: "hoarder-#{SecureRandom.hex}@example.com")
    @event.orders.create!(user: hoarder)
      .order_items.create!(event_product: @product, quantity: 10, unit_price_cents: 1000)

    assert_no_difference ["Order.count", "OrderItem.count"] do
      post shop_event_order_path(@store.slug, @event), params: {
        items: {@product.id.to_s => "1", second_product.id.to_s => "2"}
      }
    end
  end

  test "sold-out product renders without a quantity input on the event page" do
    hoarder = User.create!(email: "hoarder-#{SecureRandom.hex}@example.com")
    @event.orders.create!(user: hoarder)
      .order_items.create!(event_product: @product, quantity: 10, unit_price_cents: 1000)

    get shop_event_path(@store.slug, @event)

    assert_response :success
    assert_select ".product-row.sold-out", minimum: 1
    assert_select "#items_#{@product.id}", count: 0
  end
end
