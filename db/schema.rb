# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_22_180923) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "event_products", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "event_id", null: false
    t.string "name"
    t.integer "price_cents"
    t.integer "quantity"
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_event_products_on_event_id"
  end

  create_table "events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.datetime "orders_close_at"
    t.datetime "pickup_at"
    t.datetime "published_at"
    t.integer "store_id", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_events_on_store_id"
  end

  create_table "login_codes", force: :cascade do |t|
    t.string "code_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.integer "user_id", null: false
    t.index ["user_id", "created_at"], name: "index_login_codes_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_login_codes_on_user_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "event_product_id", null: false
    t.integer "order_id", null: false
    t.integer "quantity"
    t.integer "unit_price_cents"
    t.datetime "updated_at", null: false
    t.index ["event_product_id"], name: "index_order_items_on_event_product_id"
    t.index ["order_id"], name: "index_order_items_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "event_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["event_id"], name: "index_orders_on_event_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "store_notifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "store_id", null: false
    t.string "unsubscribe_token"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["store_id"], name: "index_store_notifications_on_store_id"
    t.index ["unsubscribe_token"], name: "index_store_notifications_on_unsubscribe_token", unique: true
    t.index ["user_id", "store_id"], name: "index_store_notifications_on_user_and_store", unique: true
    t.index ["user_id"], name: "index_store_notifications_on_user_id"
  end

  create_table "stores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.string "slug"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["slug"], name: "index_stores_on_slug", unique: true
    t.index ["user_id"], name: "index_stores_on_user_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "event_products", "events"
  add_foreign_key "events", "stores"
  add_foreign_key "login_codes", "users"
  add_foreign_key "order_items", "event_products"
  add_foreign_key "order_items", "orders"
  add_foreign_key "orders", "events"
  add_foreign_key "orders", "users"
  add_foreign_key "store_notifications", "stores"
  add_foreign_key "store_notifications", "users"
  add_foreign_key "stores", "users"
end
