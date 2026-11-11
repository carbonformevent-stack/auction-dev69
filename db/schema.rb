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

ActiveRecord::Schema[8.1].define(version: 2026_11_11_120000) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "auctions", force: :cascade do |t|
    t.integer "product_id", null: false
    t.integer "auction_type", default: 0, null: false
    t.integer "starting_price", null: false
    t.datetime "starts_at", null: false
    t.datetime "ends_at", null: false
    t.integer "status", default: 0, null: false
    t.json "settings", default: {}, null: false
    t.bigint "winner_bid_id"
    t.integer "created_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_auctions_on_created_by_id"
    t.index ["product_id", "created_at"], name: "index_auctions_on_product_id_and_created_at"
    t.index ["product_id"], name: "index_auctions_one_active_per_product", unique: true, where: "status IN (0, 1)"
    t.index ["status", "ends_at"], name: "index_auctions_on_status_and_ends_at"
    t.index ["status", "starts_at"], name: "index_auctions_on_status_and_starts_at"
    t.check_constraint "auction_type IN (0)", name: "auctions_auction_type_valid"
    t.check_constraint "ends_at > starts_at", name: "auctions_ends_after_start"
    t.check_constraint "starting_price BETWEEN 1 AND 20000", name: "auctions_starting_price_range"
    t.check_constraint "status IN (0, 1, 2, 3, 4)", name: "auctions_status_valid"
  end

  create_table "product_reviews", force: :cascade do |t|
    t.integer "product_id", null: false
    t.integer "reviewer_id", null: false
    t.integer "decision", null: false
    t.text "reason"
    t.datetime "created_at", null: false
    t.index ["product_id", "created_at"], name: "index_product_reviews_on_product_id_and_created_at"
    t.index ["reviewer_id"], name: "index_product_reviews_on_reviewer_id"
    t.check_constraint "decision <> 1 OR reason IS NOT NULL", name: "product_reviews_rejection_has_reason"
    t.check_constraint "decision IN (0, 1)", name: "product_reviews_decision_valid"
  end

  create_table "products", force: :cascade do |t|
    t.integer "seller_id", null: false
    t.integer "category", null: false
    t.integer "starting_price", null: false
    t.string "title", null: false
    t.text "description", null: false
    t.integer "desired_duration_minutes", default: 1440, null: false
    t.integer "status", default: 0, null: false
    t.datetime "submitted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["seller_id", "updated_at"], name: "index_products_on_seller_id_and_updated_at"
    t.index ["status", "submitted_at"], name: "index_products_on_status_and_submitted_at"
    t.check_constraint "category IN (0, 1, 2, 3)", name: "products_category_valid"
    t.check_constraint "desired_duration_minutes BETWEEN 60 AND 10080", name: "products_desired_duration_range"
    t.check_constraint "starting_price BETWEEN 1 AND 20000", name: "products_starting_price_range"
    t.check_constraint "status IN (0, 1, 2, 3)", name: "products_status_valid"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "name"
    t.string "provider", null: false
    t.string "uid", null: false
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "auctions", "products"
  add_foreign_key "auctions", "users", column: "created_by_id"
  add_foreign_key "product_reviews", "products"
  add_foreign_key "product_reviews", "users", column: "reviewer_id"
  add_foreign_key "products", "users", column: "seller_id"
end
