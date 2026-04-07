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

  # 1. Create Users
  baker1 = User.find_or_create_by!(email: "baker@example.com") { |u| u.name = "Alice Baker" }
  baker2 = User.find_or_create_by!(email: "baker2@example.com") { |u| u.name = "Bob Sweets" }
  baker3 = User.find_or_create_by!(email: "baker3@example.com") { |u| u.name = "Charlie Bagels" }

  buyer1 = User.find_or_create_by!(email: "buyer1@example.com") { |u| u.name = "Diana Buyer" }
  buyer2 = User.find_or_create_by!(email: "buyer2@example.com") { |u| u.name = "Evan Spender" }
  buyer3 = User.find_or_create_by!(email: "buyer3@example.com") { |u| u.name = "Fiona Foodie" }

  puts "Creating stores..."
  # 2. Create Stores
  store1 = Store.find_or_create_by!(user: baker1) do |s|
    s.name = "The Crusty Loaf"
    s.slug = "the-crusty-loaf"
    s.description = "Artisanal naturally leavened breads baked in a wood-fired oven."
    s.address = "123 Main St, Springfield"
    s.bio = "Alice has been baking sourdough for over 10 years, starting in her small apartment and now serving the whole neighborhood."
    s.instagram_handle = "thecrustyloaf"
    s.venmo_handle = "alicebakes"
  end

  store2 = Store.find_or_create_by!(user: baker2) do |s|
    s.name = "The Sweet Spot"
    s.slug = "the-sweet-spot"
    s.description = "Decadent cakes, cookies, and sweet treats perfect for any occasion."
    s.address = "456 Sugar Ln, Springfield"
  end

  store3 = Store.find_or_create_by!(user: baker3) do |s|
    s.name = "Sunrise Bagels"
    s.slug = "sunrise-bagels"
    s.description = "Authentic boiled and baked New York style bagels."
    s.address = "789 Morning Ave, Springfield"
  end

  puts "Creating events..."
  # 3. Create Events (Drafts initially)
  # Store 1 Events
  s1_past = store1.events.create!(
    name: "Winter Warmth Bake",
    description: "Hearty ryes and festive loaves.",
    orders_close_at: 2.weeks.ago,
    pickup_at: 12.days.ago,
    pickup_address: "123 Main St, Springfield",
    published_at: nil
  )
  s1_active = store1.events.create!(
    name: "Spring Sourdough Special",
    description: "Fresh heritage wheat sourdough and seasonal herbs.",
    orders_close_at: 2.days.from_now,
    pickup_at: 4.days.from_now,
    pickup_address: "123 Main St, Springfield",
    published_at: nil
  )
  s1_prep = store1.events.create!(
    name: "Mid-Week Pizza Night",
    description: "Sourdough pizza dough and fresh toppings.",
    orders_close_at: 1.day.ago,
    pickup_at: 2.days.from_now,
    pickup_address: "123 Main St, Springfield",
    published_at: nil
  )
  s1_future = store1.events.create!(
    name: "Next Week's Bake",
    description: "Testing some new recipes.",
    orders_close_at: 9.days.from_now,
    pickup_at: 11.days.from_now,
    pickup_address: "123 Main St, Springfield",
    published_at: nil # Draft
  )

  # Store 2 Events
  s2_active = store2.events.create!(
    name: "Weekend Pastry Box",
    description: "Assorted weekend treats including croissants and macarons.",
    orders_close_at: 3.days.from_now,
    pickup_at: 5.days.from_now,
    pickup_address: "456 Sugar Ln, Springfield",
    published_at: nil
  )

  # Store 3 Events
  s3_active = store3.events.create!(
    name: "Sunday Morning Bagel Drop",
    description: "Fresh hot bagels, cream cheese, and lox.",
    orders_close_at: 1.day.from_now,
    pickup_at: 2.days.from_now,
    pickup_address: "789 Morning Ave, Springfield",
    published_at: nil
  )
  s3_prep = store3.events.create!(
    name: "Saturday Bagel Pack",
    description: "Pre-order your weekend bagels. Pickup Saturday morning.",
    orders_close_at: 2.days.ago,
    pickup_at: 1.day.from_now,
    pickup_address: "789 Morning Ave, Springfield",
    published_at: nil
  )

  s3_future = store3.events.create!(
    name: "Bagels & Babka",
    description: "Testing out a new chocolate babka recipe along with our classic bagels.",
    orders_close_at: 8.days.from_now,
    pickup_at: 10.days.from_now,
    pickup_address: "789 Morning Ave, Springfield",
    published_at: nil # Draft
  )

  puts "Adding products..."
  # 4. Create Products
  s1_products = [
    {name: "Classic Sourdough", price_cents: 850, quantity: 20},
    {name: "Olive & Rosemary Focaccia", price_cents: 1200, quantity: 10},
    {name: "French Baguette", price_cents: 400, quantity: 30},
    {name: "Whole Wheat Rye", price_cents: 900, quantity: 15}
  ]

  s2_products = [
    {name: "Chocolate Croissant", price_cents: 450, quantity: 25},
    {name: "Lemon Tart", price_cents: 600, quantity: 12},
    {name: "Assorted Macarons (6-pack)", price_cents: 1500, quantity: 20}
  ]

  s3_products = [
    {name: "Everything Bagel (pack of 6)", price_cents: 1000, quantity: 40},
    {name: "Plain Bagel (pack of 6)", price_cents: 900, quantity: 30},
    {name: "Scallion Cream Cheese (8oz)", price_cents: 550, quantity: 20}
  ]

  s3_future_products = [
    {name: "Everything Bagel (pack of 6)", price_cents: 1000, quantity: 30},
    {name: "Chocolate Babka Loaf", price_cents: 1400, quantity: 15}
  ]

  [s1_past, s1_active, s1_future, s1_prep].each do |event|
    s1_products.each { |p| event.event_products.create!(p) }
  end

  s2_products.each { |p| s2_active.event_products.create!(p) }
  s3_products.each { |p| s3_active.event_products.create!(p) }
  s3_products.each { |p| s3_prep.event_products.create!(p) }
  s3_future_products.each { |p| s3_future.event_products.create!(p) }

  puts "Publishing events..."
  # 4b. Publish events now that they have products
  s1_past.update!(published_at: 3.weeks.ago)
  s1_active.update!(published_at: 1.day.ago)
  s1_prep.update!(published_at: 3.days.ago)
  s2_active.update!(published_at: 2.days.ago)
  s3_active.update!(published_at: 4.days.ago)
  s3_prep.update!(published_at: 5.days.ago)

  puts "Placing sample orders..."
  # 5. Create Orders

  # Store 1 Orders
  order1 = s1_active.orders.create!(user: buyer1)
  order1.order_items.create!(
    event_product: s1_active.event_products.find_by(name: "Classic Sourdough"),
    quantity: 2,
    unit_price_cents: 850
  )
  order1.order_items.create!(
    event_product: s1_active.event_products.find_by(name: "French Baguette"),
    quantity: 1,
    unit_price_cents: 400
  )

  order2 = s1_active.orders.create!(user: buyer2)
  order2.order_items.create!(
    event_product: s1_active.event_products.find_by(name: "Olive & Rosemary Focaccia"),
    quantity: 1,
    unit_price_cents: 1200
  )

  # Store 1 Prep Orders (orders closed, pickup upcoming — baker needs to start baking)
  order_prep1 = s1_prep.orders.create!(user: buyer1)
  order_prep1.order_items.create!(
    event_product: s1_prep.event_products.find_by(name: "Classic Sourdough"),
    quantity: 2,
    unit_price_cents: 850
  )
  order_prep1.order_items.create!(
    event_product: s1_prep.event_products.find_by(name: "Olive & Rosemary Focaccia"),
    quantity: 1,
    unit_price_cents: 1200
  )

  order_prep2 = s1_prep.orders.create!(user: buyer2)
  order_prep2.order_items.create!(
    event_product: s1_prep.event_products.find_by(name: "French Baguette"),
    quantity: 3,
    unit_price_cents: 400
  )
  order_prep2.order_items.create!(
    event_product: s1_prep.event_products.find_by(name: "Whole Wheat Rye"),
    quantity: 1,
    unit_price_cents: 900
  )

  order_prep3 = s1_prep.orders.create!(user: buyer3)
  order_prep3.order_items.create!(
    event_product: s1_prep.event_products.find_by(name: "Classic Sourdough"),
    quantity: 1,
    unit_price_cents: 850
  )

  order3 = s1_past.orders.create!(user: buyer1)
  order3.order_items.create!(
    event_product: s1_past.event_products.find_by(name: "Classic Sourdough"),
    quantity: 1,
    unit_price_cents: 850
  )

  # Store 2 Orders
  order4 = s2_active.orders.create!(user: buyer3)
  order4.order_items.create!(
    event_product: s2_active.event_products.find_by(name: "Chocolate Croissant"),
    quantity: 4,
    unit_price_cents: 450
  )
  order4.order_items.create!(
    event_product: s2_active.event_products.find_by(name: "Lemon Tart"),
    quantity: 1,
    unit_price_cents: 600
  )

  # Store 3 Prep Orders
  order_s3_prep1 = s3_prep.orders.create!(user: buyer1)
  order_s3_prep1.order_items.create!(
    event_product: s3_prep.event_products.find_by(name: "Everything Bagel (pack of 6)"),
    quantity: 2,
    unit_price_cents: 1000
  )
  order_s3_prep1.order_items.create!(
    event_product: s3_prep.event_products.find_by(name: "Scallion Cream Cheese (8oz)"),
    quantity: 1,
    unit_price_cents: 550
  )

  order_s3_prep2 = s3_prep.orders.create!(user: buyer3)
  order_s3_prep2.order_items.create!(
    event_product: s3_prep.event_products.find_by(name: "Plain Bagel (pack of 6)"),
    quantity: 1,
    unit_price_cents: 900
  )

  # Store 3 Orders
  order5 = s3_active.orders.create!(user: buyer2)
  order5.order_items.create!(
    event_product: s3_active.event_products.find_by(name: "Everything Bagel (pack of 6)"),
    quantity: 1,
    unit_price_cents: 1000
  )
  order5.order_items.create!(
    event_product: s3_active.event_products.find_by(name: "Scallion Cream Cheese (8oz)"),
    quantity: 1,
    unit_price_cents: 550
  )

  # Subscriptions
  puts "Adding store subscribers..."
  buyer1.store_notifications.create!(store: store1)
  buyer2.store_notifications.create!(store: store1)
  buyer3.store_notifications.create!(store: store2)
  buyer1.store_notifications.create!(store: store3)
  buyer2.store_notifications.create!(store: store3)

  puts "Seeding complete!"
  puts "----------------"
  puts "Bakers:"
  puts "- #{baker1.email} (/s/#{store1.slug})"
  puts "- #{baker2.email} (/s/#{store2.slug})"
  puts "- #{baker3.email} (/s/#{store3.slug})"
  puts "Buyers:"
  puts "- #{buyer1.email}"
  puts "- #{buyer2.email}"
  puts "- #{buyer3.email}"
end
