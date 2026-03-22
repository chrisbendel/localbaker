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
      assert_equal "Added!", flash[:notice]
    end

    test "should update quantity" do
      sign_in_as(@customer)

      # Create initial item
      post storefront_event_order_items_url(@store.slug, @event), params: {event_product_id: @product.id}
      item = OrderItem.last

      patch storefront_order_item_url(@store.slug, item), params: {order_item: {quantity: 5}}

      assert_redirected_to storefront_event_path(@store.slug, @event)
      assert_equal 5, item.reload.quantity
      assert_equal "Updated quantity.", flash[:notice]
    end

    test "should destroy item when quantity updated to 0" do
      sign_in_as(@customer)

      # Create initial item
      post storefront_event_order_items_url(@store.slug, @event), params: {event_product_id: @product.id}
      item = OrderItem.last

      assert_difference("OrderItem.count", -1) do
        patch storefront_order_item_url(@store.slug, item), params: {order_item: {quantity: 0}}
      end

      assert_redirected_to storefront_event_path(@store.slug, @event)
      assert_equal "Removed item.", flash[:notice]
    end

    test "should destroy item directly" do
      sign_in_as(@customer)

      # Create initial item
      post storefront_event_order_items_url(@store.slug, @event), params: {event_product_id: @product.id}
      item = OrderItem.last

      assert_difference("OrderItem.count", -1) do
        delete storefront_order_item_url(@store.slug, item)
      end

      assert_redirected_to storefront_event_path(@store.slug, @event)
      assert_equal "Removed item.", flash[:notice]
    end

    test "should prevent adding more than stock" do
      sign_in_as(@customer)

      # Try to add more than 10
      # But create logic is just "add 1". It checks remaining < 1.
      # To test failing, set stock to 0.
      @product.update!(quantity: 0)

      assert_no_difference("OrderItem.count") do
        post storefront_event_order_items_url(@store.slug, @event), params: {event_product_id: @product.id}
      end

      assert_redirected_to storefront_event_path(@store.slug, @event)
      assert_equal "Sorry, that item is out of stock!", flash[:alert]
    end
  end
end
