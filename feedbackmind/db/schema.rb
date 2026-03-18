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

ActiveRecord::Schema[7.2].define(version: 2026_03_18_000008) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "vector"

  create_table "accounts", force: :cascade do |t|
    t.string "name", null: false
    t.string "subdomain", null: false
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.integer "plan", default: 0, null: false
    t.integer "feedback_count_this_month", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plan"], name: "index_accounts_on_plan"
    t.index ["stripe_customer_id"], name: "index_accounts_on_stripe_customer_id", unique: true, where: "(stripe_customer_id IS NOT NULL)"
    t.index ["subdomain"], name: "index_accounts_on_subdomain", unique: true
  end

  create_table "chat_messages", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "user_id", null: false
    t.integer "role", default: 0, null: false
    t.text "content", null: false
    t.integer "source_feedback_ids", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "created_at"], name: "index_chat_messages_on_account_id_and_created_at"
    t.index ["account_id"], name: "index_chat_messages_on_account_id"
    t.index ["user_id", "created_at"], name: "index_chat_messages_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_chat_messages_on_user_id"
  end

  create_table "feedbacks", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "source_id", null: false
    t.string "external_id"
    t.text "content", null: false
    t.string "author_email"
    t.string "author_name"
    t.integer "sentiment"
    t.string "topics", default: [], array: true
    t.jsonb "metadata", default: {}
    t.datetime "received_at"
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.vector "embedding", limit: 1536
    t.index ["account_id", "received_at"], name: "index_feedbacks_on_account_id_and_received_at"
    t.index ["account_id"], name: "index_feedbacks_on_account_id"
    t.index ["embedding"], name: "index_feedbacks_on_embedding_hnsw", opclass: :vector_cosine_ops, using: :hnsw
    t.index ["processed_at"], name: "index_feedbacks_unprocessed", where: "(processed_at IS NULL)"
    t.index ["sentiment"], name: "index_feedbacks_on_sentiment"
    t.index ["source_id", "external_id"], name: "index_feedbacks_on_source_id_and_external_id", unique: true, where: "(external_id IS NOT NULL)"
    t.index ["source_id"], name: "index_feedbacks_on_source_id"
    t.index ["topics"], name: "index_feedbacks_on_topics", using: :gin
  end

  create_table "sources", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.integer "source_type", null: false
    t.jsonb "config", default: {}
    t.boolean "active", default: false, null: false
    t.datetime "last_synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "active"], name: "index_sources_on_account_id_and_active"
    t.index ["account_id", "source_type"], name: "index_sources_on_account_id_and_source_type"
    t.index ["account_id"], name: "index_sources_on_account_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.bigint "account_id", null: false
    t.string "name"
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "role"], name: "index_users_on_account_id_and_role"
    t.index ["account_id"], name: "index_users_on_account_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "weekly_syntheses", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.date "week_start", null: false
    t.integer "feedback_count", default: 0
    t.jsonb "top_themes", default: []
    t.text "executive_summary"
    t.jsonb "biggest_risk", default: {}
    t.string "quick_wins", default: [], array: true
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "week_start"], name: "index_weekly_syntheses_on_account_id_and_week_start", unique: true
    t.index ["account_id"], name: "index_weekly_syntheses_on_account_id"
    t.index ["week_start"], name: "index_weekly_syntheses_on_week_start"
  end

  add_foreign_key "chat_messages", "accounts"
  add_foreign_key "chat_messages", "users"
  add_foreign_key "feedbacks", "accounts"
  add_foreign_key "feedbacks", "sources"
  add_foreign_key "sources", "accounts"
  add_foreign_key "users", "accounts"
  add_foreign_key "weekly_syntheses", "accounts"
end
