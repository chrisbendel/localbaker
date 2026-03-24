# Clear existing data to ensure a fresh start in development
if Rails.env.development?
  puts "Cleaning database..."
  OrderItem.destroy_all
  Order.destroy_all
  EventProduct.destroy_all
  Event.destroy_all
  StoreNotification.destroy_all
  Store.destroy_all
  LoginCode.destroy_all
  User.destroy_all

  puts "Seeding demo data..."

  # 1. Create Baker
  baker = User.find_or_create_by!(email: "baker@example.com")
  store = Store.find_or_create_by!(user: baker) do |s|
    s.name = "The Crusty Loaf"
    s.slug = "the-crusty-loaf"
    s.description = "Artisanal naturally leavened breads baked in a wood-fired oven."
  end

  # 2. Create Buyers
  buyer1 = User.find_or_create_by!(email: "buyer1@example.com")
  buyer2 = User.find_or_create_by!(email: "buyer2@example.com")

  # 3. Create Events (as drafts first to satisfy validation)
  puts "Creating events..."

  past_event = store.events.create!(
    name: "Winter Warmth Bake",
    description: "Hearty ryes and festive loaves.",
    orders_close_at: 2.weeks.ago,
    pickup_at: 12.days.ago,
    published_at: nil
  )

  active_event = store.events.create!(
    name: "Spring Sourdough Special",
    description: "Fresh heritage wheat sourdough and seasonal herbs.",
    orders_close_at: 2.days.from_now,
    pickup_at: 4.days.from_now,
    published_at: nil
  )

  future_event = store.events.create!(
    name: "Next Week's Bake",
    description: "Testing some new recipes.",
    orders_close_at: 9.days.from_now,
    pickup_at: 11.days.from_now,
    published_at: nil
  )

  # 4. Create Products
  puts "Adding products..."

  products_data = [
    {name: "Classic Sourdough", price: 8.50, quantity: 20},
    {name: "Olive & Rosemary Focaccia", price: 12.00, quantity: 10},
    {name: "French Baguette", price: 4.00, quantity: 30},
    {name: "Whole Wheat Rye", price: 9.00, quantity: 15}
  ]

  [past_event, active_event, future_event].each do |event|
    products_data.each do |p|
      event.event_products.create!(p)
    end
  end

  # 5. Now Publish the events that should be published
  puts "Publishing events..."
  past_event.update!(published_at: 3.weeks.ago)
  active_event.update!(published_at: 1.day.ago)
  # future_event remains a draft

  # 6. Create Orders for Active Event
  puts "Placing sample orders..."

  # Order 1
  order1 = active_event.orders.create!(user: buyer1)
  order1.order_items.create!(
    event_product: active_event.event_products.find_by(name: "Classic Sourdough"),
    quantity: 2,
    unit_price_cents: 850
  )
  order1.order_items.create!(
    event_product: active_event.event_products.find_by(name: "French Baguette"),
    quantity: 1,
    unit_price_cents: 400
  )

  # Order 2
  order2 = active_event.orders.create!(user: buyer2)
  order2.order_items.create!(
    event_product: active_event.event_products.find_by(name: "Olive & Rosemary Focaccia"),
    quantity: 1,
    unit_price_cents: 1200
  )

  # 7. Create Orders for Past Event
  order3 = past_event.orders.create!(user: buyer1)
  order3.order_items.create!(
    event_product: past_event.event_products.find_by(name: "Classic Sourdough"),
    quantity: 1,
    unit_price_cents: 850
  )

  puts "Seeding complete!"
  puts "----------------"
  puts "Baker Login: baker@example.com"
  puts "Buyer 1 Login: buyer1@example.com"
  puts "Buyer 2 Login: buyer2@example.com"
  puts "Active Store: /s/the-crusty-loaf"
end
