require "test_helper"

module Storefront
  class OrderItemsControllerTest < ActionDispatch::IntegrationTest
    def setup
      @owner = User.create!(email: "owner-#{SecureRandom.hex(4)}@example.com")
      @store = Store.create!(name: "Test Store", slug: "test-store-#{SecureRandom.hex(4)}", user: @owner)
      @event = @store.events.create!(name: "Test Event", orders_close_at: 1.day.from_now, pickup_at: 2.days.from_now)
      @product = @event.event_products.create!(name: "Sourdough", price: 10, quantity: 10)
      @event.publish!

      @customer = User.create!(email: "customer-#{SecureRandom.hex(4)}@example.com")
    end

    test "should require authentication" do
      post storefront_event_order_items_url(@store.slug, @event), params: {event_product_id: @product.id}
      assert_redirected_to new_session_path
      assert_equal "Sign in to continue.", flash[:alert]
    end

    test "should create order item for authenticated user" do
      sign_in_as(@customer)

      assert_difference("OrderItem.count", 1) do
        post storefront_event_order_items_url(@store.slug, @event), params: {event_product_id: @product.id}
      end

      assert_redirected_to storefront_event_path(@store.slug, @event)
      assert_equal "Added #{@product.name}", flash[:notice]
    end

    test "should increment quantity when adding same product again" do
      sign_in_as(@customer)

      post storefront_event_order_items_url(@store.slug, @event), params: {event_product_id: @product.id}
      item = OrderItem.last

      assert_no_difference("OrderItem.count") do
        post storefront_event_order_items_url(@store.slug, @event), params: {event_product_id: @product.id}
      end

      assert_equal 2, item.reload.quantity
    end

    test "should destroy item directly" do
      sign_in_as(@customer)

      post storefront_event_order_items_url(@store.slug, @event), params: {event_product_id: @product.id}
      item = OrderItem.last

      assert_difference("OrderItem.count", -1) do
        delete storefront_order_item_url(@store.slug, item)
      end

      assert_redirected_to storefront_event_path(@store.slug, @event)
      assert_equal "Removed #{@product.name}", flash[:notice]
    end

    test "should prevent adding more than stock" do
      sign_in_as(@customer)

      @product.update!(quantity: 0)

      assert_no_difference("OrderItem.count") do
        post storefront_event_order_items_url(@store.slug, @event), params: {event_product_id: @product.id}
      end

      assert_redirected_to storefront_event_path(@store.slug, @event)
      assert_equal "Sorry, that item is out of stock!", flash[:alert]
    end

    test "should block adding to order for draft event" do
      draft_event = @store.events.create!(name: "Draft Event", orders_close_at: 1.day.from_now, pickup_at: 2.days.from_now)
      draft_product = draft_event.event_products.create!(name: "Item", price: 10, quantity: 10)
      sign_in_as(@customer)

      assert_no_difference("OrderItem.count") do
        post storefront_event_order_items_url(@store.slug, draft_event), params: {event_product_id: draft_product.id}
      end

      assert_redirected_to storefront_event_path(@store.slug, draft_event)
      assert_equal "Sorry, orders for this event are closed.", flash[:alert]
    end

    test "should block adding to order when orders are closed" do
      @event.update_columns(orders_close_at: 1.hour.ago)
      sign_in_as(@customer)

      assert_no_difference("OrderItem.count") do
        post storefront_event_order_items_url(@store.slug, @event), params: {event_product_id: @product.id}
      end

      assert_redirected_to storefront_event_path(@store.slug, @event)
      assert_equal "Sorry, orders for this event are closed.", flash[:alert]
    end

    test "should block destroying order item when orders are closed" do
      sign_in_as(@customer)
      post storefront_event_order_items_url(@store.slug, @event), params: {event_product_id: @product.id}
      item = OrderItem.last

      @event.update_columns(orders_close_at: 1.hour.ago)

      assert_no_difference("OrderItem.count") do
        delete storefront_order_item_url(@store.slug, item)
      end

      assert_redirected_to storefront_event_path(@store.slug, @event)
      assert_equal "Sorry, orders for this event are closed.", flash[:alert]
    end
  end
end
