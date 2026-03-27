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

ActiveRecord::Schema[8.1].define(version: 2026_03_27_164916) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vector"

  create_table "accounts", force: :cascade do |t|
    t.string "api_token"
    t.datetime "created_at", null: false
    t.integer "feedback_count_this_month", default: 0
    t.string "name", null: false
    t.integer "plan", default: 0, null: false
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.string "subdomain", null: false
    t.datetime "updated_at", null: false
    t.index ["api_token"], name: "index_accounts_on_api_token", unique: true
    t.index ["plan"], name: "index_accounts_on_plan"
    t.index ["stripe_customer_id"], name: "index_accounts_on_stripe_customer_id", unique: true, where: "(stripe_customer_id IS NOT NULL)"
    t.index ["subdomain"], name: "index_accounts_on_subdomain", unique: true
  end

  create_table "changelog_entries", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.text "body", null: false
    t.integer "category", default: 0, null: false
    t.string "cover_image_url"
    t.datetime "created_at", null: false
    t.datetime "published_at"
    t.string "slug", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.string "version"
    t.index ["account_id", "category"], name: "index_changelog_entries_on_account_id_and_category"
    t.index ["account_id", "published_at"], name: "index_changelog_entries_on_account_id_and_published_at"
    t.index ["account_id", "slug"], name: "index_changelog_entries_on_account_id_and_slug", unique: true
    t.index ["account_id"], name: "index_changelog_entries_on_account_id"
    t.index ["user_id"], name: "index_changelog_entries_on_user_id"
  end

  create_table "changelog_entry_feature_requests", force: :cascade do |t|
    t.bigint "changelog_entry_id", null: false
    t.datetime "created_at", null: false
    t.bigint "feature_request_id", null: false
    t.datetime "updated_at", null: false
    t.index ["changelog_entry_id", "feature_request_id"], name: "idx_changelog_feature_request_unique", unique: true
    t.index ["changelog_entry_id"], name: "index_changelog_entry_feature_requests_on_changelog_entry_id"
    t.index ["feature_request_id"], name: "index_changelog_entry_feature_requests_on_feature_request_id"
  end

  create_table "chat_messages", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.integer "role", default: 0, null: false
    t.integer "source_feedback_ids", default: [], array: true
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["account_id", "created_at"], name: "index_chat_messages_on_account_id_and_created_at"
    t.index ["account_id"], name: "index_chat_messages_on_account_id"
    t.index ["user_id", "created_at"], name: "index_chat_messages_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_chat_messages_on_user_id"
  end

  create_table "companies", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.string "domain"
    t.integer "feedback_count", default: 0, null: false
    t.jsonb "metadata", default: {}
    t.decimal "mrr", precision: 10, scale: 2
    t.string "name", null: false
    t.text "notes"
    t.integer "plan_tier"
    t.string "segment"
    t.datetime "updated_at", null: false
    t.index ["account_id", "domain"], name: "index_companies_on_account_id_and_domain", unique: true, where: "(domain IS NOT NULL)"
    t.index ["account_id", "feedback_count"], name: "index_companies_on_account_id_and_feedback_count"
    t.index ["account_id", "mrr"], name: "index_companies_on_account_id_and_mrr"
    t.index ["account_id", "segment"], name: "index_companies_on_account_id_and_segment"
    t.index ["account_id"], name: "index_companies_on_account_id"
  end

  create_table "feature_request_feedbacks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "feature_request_id", null: false
    t.bigint "feedback_id", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_request_id", "feedback_id"], name: "idx_fr_feedback_unique", unique: true
    t.index ["feature_request_id"], name: "index_feature_request_feedbacks_on_feature_request_id"
    t.index ["feedback_id"], name: "index_feature_request_feedbacks_on_feedback_id"
  end

  create_table "feature_requests", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.text "admin_notes"
    t.string "author_email"
    t.string "author_name"
    t.string "category"
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "merged_into_id"
    t.string "priority_label"
    t.integer "priority_score"
    t.datetime "published_at"
    t.datetime "shipped_at"
    t.string "slug", null: false
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.integer "votes_count", default: 0, null: false
    t.index ["account_id", "category"], name: "index_feature_requests_on_account_id_and_category"
    t.index ["account_id", "priority_score"], name: "index_feature_requests_on_account_id_and_priority_score"
    t.index ["account_id", "slug"], name: "index_feature_requests_on_account_id_and_slug", unique: true
    t.index ["account_id", "status"], name: "index_feature_requests_on_account_id_and_status"
    t.index ["account_id", "votes_count"], name: "index_feature_requests_on_account_id_and_votes_count"
    t.index ["account_id"], name: "index_feature_requests_on_account_id"
    t.index ["author_email"], name: "index_feature_requests_on_author_email"
    t.index ["merged_into_id"], name: "index_feature_requests_on_merged_into_id"
    t.index ["user_id"], name: "index_feature_requests_on_user_id"
  end

  create_table "feedbacks", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "author_email"
    t.string "author_name"
    t.bigint "company_id"
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.vector "embedding", limit: 1536
    t.string "external_id"
    t.jsonb "metadata", default: {}
    t.string "priority_label"
    t.text "priority_reasoning"
    t.integer "priority_score"
    t.datetime "processed_at"
    t.datetime "received_at"
    t.integer "sentiment"
    t.bigint "source_id", null: false
    t.string "tags", default: [], array: true
    t.string "topics", default: [], array: true
    t.datetime "updated_at", null: false
    t.index ["account_id", "priority_score"], name: "index_feedbacks_on_account_id_and_priority_score"
    t.index ["account_id", "received_at"], name: "index_feedbacks_on_account_id_and_received_at"
    t.index ["account_id"], name: "index_feedbacks_on_account_id"
    t.index ["company_id", "received_at"], name: "index_feedbacks_on_company_id_and_received_at"
    t.index ["company_id"], name: "index_feedbacks_on_company_id"
    t.index ["embedding"], name: "index_feedbacks_on_embedding_hnsw", opclass: :vector_cosine_ops, using: :hnsw
    t.index ["processed_at"], name: "index_feedbacks_unprocessed", where: "(processed_at IS NULL)"
    t.index ["sentiment"], name: "index_feedbacks_on_sentiment"
    t.index ["source_id", "external_id"], name: "index_feedbacks_on_source_id_and_external_id", unique: true, where: "(external_id IS NOT NULL)"
    t.index ["source_id"], name: "index_feedbacks_on_source_id"
    t.index ["tags"], name: "index_feedbacks_on_tags", using: :gin
    t.index ["topics"], name: "index_feedbacks_on_topics", using: :gin
  end

  create_table "nps_responses", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "category"
    t.text "comment"
    t.datetime "created_at", null: false
    t.bigint "feedback_id"
    t.jsonb "metadata", default: {}
    t.bigint "nps_survey_id", null: false
    t.string "page_url"
    t.string "respondent_email"
    t.string "respondent_id"
    t.string "respondent_name"
    t.integer "score", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "category"], name: "index_nps_responses_on_account_id_and_category"
    t.index ["account_id"], name: "index_nps_responses_on_account_id"
    t.index ["feedback_id"], name: "index_nps_responses_on_feedback_id"
    t.index ["nps_survey_id", "created_at"], name: "index_nps_responses_on_nps_survey_id_and_created_at"
    t.index ["nps_survey_id", "respondent_email"], name: "index_nps_responses_on_nps_survey_id_and_respondent_email"
    t.index ["nps_survey_id"], name: "index_nps_responses_on_nps_survey_id"
  end

  create_table "nps_surveys", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.boolean "active", default: true
    t.string "brand_color", default: "#1c1917"
    t.datetime "created_at", null: false
    t.string "followup_question", default: "What's the main reason for your score?"
    t.string "name", null: false
    t.string "position", default: "bottom-right"
    t.string "question", default: "How likely are you to recommend us to a friend or colleague?", null: false
    t.integer "responses_count", default: 0, null: false
    t.jsonb "settings", default: {}
    t.string "survey_token", null: false
    t.string "thank_you_message", default: "Thanks for your feedback!"
    t.datetime "updated_at", null: false
    t.index ["account_id", "active"], name: "index_nps_surveys_on_account_id_and_active"
    t.index ["account_id"], name: "index_nps_surveys_on_account_id"
    t.index ["survey_token"], name: "index_nps_surveys_on_survey_token", unique: true
  end

  create_table "saved_views", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "filters", default: {}, null: false
    t.string "icon"
    t.string "name", null: false
    t.integer "position", default: 0
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["account_id", "user_id"], name: "index_saved_views_on_account_id_and_user_id"
    t.index ["account_id"], name: "index_saved_views_on_account_id"
    t.index ["user_id"], name: "index_saved_views_on_user_id"
  end

  create_table "sources", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.boolean "active", default: false, null: false
    t.jsonb "config", default: {}
    t.datetime "created_at", null: false
    t.datetime "last_synced_at"
    t.integer "source_type", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "active"], name: "index_sources_on_account_id_and_active"
    t.index ["account_id", "source_type"], name: "index_sources_on_account_id_and_source_type"
    t.index ["account_id"], name: "index_sources_on_account_id"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "checklist_dismissed_at"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.string "name"
    t.datetime "onboarding_completed_at"
    t.integer "onboarding_step"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "role"], name: "index_users_on_account_id_and_role"
    t.index ["account_id"], name: "index_users_on_account_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "votes", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.bigint "feature_request_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.string "voter_email", null: false
    t.string "voter_name"
    t.index ["account_id", "voter_email"], name: "index_votes_on_account_id_and_voter_email"
    t.index ["account_id"], name: "index_votes_on_account_id"
    t.index ["feature_request_id", "voter_email"], name: "idx_votes_unique_per_email", unique: true
    t.index ["feature_request_id"], name: "index_votes_on_feature_request_id"
    t.index ["user_id"], name: "index_votes_on_user_id"
  end

  create_table "weekly_syntheses", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.jsonb "biggest_risk", default: {}
    t.datetime "created_at", null: false
    t.text "executive_summary"
    t.integer "feedback_count", default: 0
    t.string "quick_wins", default: [], array: true
    t.datetime "sent_at"
    t.jsonb "top_themes", default: []
    t.datetime "updated_at", null: false
    t.date "week_start", null: false
    t.index ["account_id", "week_start"], name: "index_weekly_syntheses_on_account_id_and_week_start", unique: true
    t.index ["account_id"], name: "index_weekly_syntheses_on_account_id"
    t.index ["week_start"], name: "index_weekly_syntheses_on_week_start"
  end

  add_foreign_key "changelog_entries", "accounts"
  add_foreign_key "changelog_entries", "users"
  add_foreign_key "changelog_entry_feature_requests", "changelog_entries"
  add_foreign_key "changelog_entry_feature_requests", "feature_requests"
  add_foreign_key "chat_messages", "accounts"
  add_foreign_key "chat_messages", "users"
  add_foreign_key "companies", "accounts"
  add_foreign_key "feature_request_feedbacks", "feature_requests"
  add_foreign_key "feature_request_feedbacks", "feedbacks"
  add_foreign_key "feature_requests", "accounts"
  add_foreign_key "feature_requests", "feature_requests", column: "merged_into_id"
  add_foreign_key "feature_requests", "users"
  add_foreign_key "feedbacks", "accounts"
  add_foreign_key "feedbacks", "companies"
  add_foreign_key "feedbacks", "sources"
  add_foreign_key "nps_responses", "accounts"
  add_foreign_key "nps_responses", "feedbacks"
  add_foreign_key "nps_responses", "nps_surveys"
  add_foreign_key "nps_surveys", "accounts"
  add_foreign_key "saved_views", "accounts"
  add_foreign_key "saved_views", "users"
  add_foreign_key "sources", "accounts"
  add_foreign_key "users", "accounts"
  add_foreign_key "votes", "accounts"
  add_foreign_key "votes", "feature_requests"
  add_foreign_key "votes", "users"
  add_foreign_key "weekly_syntheses", "accounts"
end
