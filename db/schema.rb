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

ActiveRecord::Schema[8.1].define(version: 2026_10_23_170000) do
  create_table "activated_alerts", force: :cascade do |t|
    t.string "search_key", null: false
    t.string "query", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["query"], name: "index_activated_alerts_on_query", unique: true
  end

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

  create_table "ai_artifacts", force: :cascade do |t|
    t.integer "job_posting_id"
    t.string "kind", null: false
    t.string "status", default: "pending", null: false
    t.string "language"
    t.text "content"
    t.string "model"
    t.integer "input_tokens"
    t.integer "output_tokens"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "cache_write_tokens"
    t.integer "cache_read_tokens"
    t.decimal "cost_usd", precision: 10, scale: 6
    t.integer "job_application_id"
    t.index ["job_application_id"], name: "index_ai_artifacts_on_job_application_id"
    t.index ["job_posting_id", "kind"], name: "index_ai_artifacts_on_job_posting_id_and_kind"
    t.index ["job_posting_id"], name: "index_ai_artifacts_on_job_posting_id"
  end

  create_table "application_emails", force: :cascade do |t|
    t.integer "job_application_id", null: false
    t.string "message_id", null: false
    t.string "from_name"
    t.string "from_address"
    t.string "subject"
    t.datetime "received_at"
    t.string "category", null: false
    t.text "summary"
    t.string "status_before"
    t.string "status_after"
    t.string "classified_by", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_application_id"], name: "index_application_emails_on_job_application_id"
    t.index ["message_id"], name: "index_application_emails_on_message_id", unique: true
  end

  create_table "consultancies", force: :cascade do |t|
    t.string "name", null: false
    t.string "url", null: false
    t.string "kind", null: false
    t.date "registered_on"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_consultancies_on_name", unique: true
  end

  create_table "contacts", force: :cascade do |t|
    t.string "name", null: false
    t.string "company"
    t.string "linkedin_url"
    t.string "kind", default: "recruiter", null: false
    t.date "last_contacted_on"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "headline"
    t.index ["linkedin_url"], name: "index_contacts_on_linkedin_url", unique: true, where: "linkedin_url IS NOT NULL"
  end

  create_table "job_applications", force: :cascade do |t|
    t.integer "job_posting_id"
    t.string "company", null: false
    t.string "role", null: false
    t.string "origin"
    t.string "status", default: "saved", null: false
    t.date "applied_on"
    t.date "next_follow_up_on"
    t.string "contact_name"
    t.string "contact_url"
    t.string "salary_range"
    t.text "notes"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "board_checked_at"
    t.date "responded_on"
    t.datetime "interview_at"
    t.datetime "interview_reminded_at"
    t.index ["job_posting_id"], name: "index_job_applications_on_job_posting_id"
    t.index ["next_follow_up_on"], name: "index_job_applications_on_next_follow_up_on"
    t.index ["status", "position"], name: "index_job_applications_on_status_and_position"
  end

  create_table "job_postings", force: :cascade do |t|
    t.string "title", null: false
    t.string "company"
    t.string "url", null: false
    t.string "fingerprint", null: false
    t.string "source", null: false
    t.string "external_id"
    t.string "location_text"
    t.string "remote_scope", default: "unknown", null: false
    t.text "description"
    t.string "salary_text"
    t.datetime "posted_at"
    t.integer "score", default: 0, null: false
    t.json "matched_keywords", default: [], null: false
    t.string "seniority", default: "unknown", null: false
    t.string "triage", default: "new", null: false
    t.json "raw", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "notified_at"
    t.string "auto_dismissed_reason"
    t.datetime "closed_at"
    t.index ["fingerprint"], name: "index_job_postings_on_fingerprint"
    t.index ["source", "external_id"], name: "index_job_postings_on_source_and_external_id"
    t.index ["triage", "score"], name: "index_job_postings_on_triage_and_score"
    t.index ["url"], name: "index_job_postings_on_url", unique: true
  end

  create_table "message_templates", force: :cascade do |t|
    t.string "name", null: false
    t.string "language", default: "pt", null: false
    t.text "body", null: false
    t.integer "max_chars"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_message_templates_on_name", unique: true
  end

  create_table "processed_emails", force: :cascade do |t|
    t.string "message_id", null: false
    t.string "subject"
    t.datetime "received_at"
    t.integer "postings_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_processed_emails_on_message_id", unique: true
  end

  create_table "profiles", force: :cascade do |t|
    t.string "name"
    t.string "headline"
    t.string "location"
    t.string "time_zone", default: "Brasilia", null: false
    t.string "languages"
    t.string "linkedin_url"
    t.string "github_url"
    t.string "portfolio_url"
    t.string "primary_area"
    t.string "plan_b_area"
    t.json "target_titles", default: [], null: false
    t.json "target_titles_en", default: [], null: false
    t.string "seniority", default: "mid", null: false
    t.integer "years_experience"
    t.json "work_modes", default: ["remote"], null: false
    t.json "regions", default: ["brazil", "latam", "worldwide"], null: false
    t.integer "salary_brl_min"
    t.integer "salary_brl_max"
    t.integer "salary_usd_min"
    t.integer "salary_usd_max"
    t.json "skills", default: [], null: false
    t.json "avoid_terms", default: [], null: false
    t.json "search_terms", default: [], null: false
    t.json "plan_b_terms", default: [], null: false
    t.json "domains", default: [], null: false
    t.json "search_overrides", default: {}, null: false
    t.text "ai_profile"
    t.text "cv_text"
    t.json "dream_posting_ids", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "cv_draft"
    t.string "cv_draft_status"
    t.text "cv_draft_error"
  end

  create_table "push_subscriptions", force: :cascade do |t|
    t.string "endpoint", null: false
    t.string "p256dh", null: false
    t.string "auth", null: false
    t.string "user_agent"
    t.datetime "last_sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["endpoint"], name: "index_push_subscriptions_on_endpoint", unique: true
  end

  create_table "routine_checks", force: :cascade do |t|
    t.date "date", null: false
    t.string "item_key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date", "item_key"], name: "index_routine_checks_on_date_and_item_key", unique: true
  end

  create_table "routine_items", force: :cascade do |t|
    t.integer "routine_slot_id", null: false
    t.string "key", null: false
    t.text "label", null: false
    t.string "url"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_routine_items_on_key", unique: true
    t.index ["routine_slot_id"], name: "index_routine_items_on_routine_slot_id"
  end

  create_table "routine_slots", force: :cascade do |t|
    t.integer "routine_id", null: false
    t.string "title", null: false
    t.string "time"
    t.string "period", default: "daily", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["routine_id"], name: "index_routine_slots_on_routine_id"
  end

  create_table "routines", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.boolean "notifications_enabled", default: true, null: false
    t.integer "notify_min_score", default: 40, null: false
    t.string "vapid_public_key"
    t.string "vapid_private_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_backup_at"
    t.text "last_backup_error"
    t.boolean "auto_dismiss_restricted", default: true, null: false
    t.integer "auto_dismiss_below_score"
    t.boolean "track_replies", default: true, null: false
    t.datetime "replies_checked_at"
    t.boolean "notify_replies", default: true, null: false
    t.boolean "notify_follow_ups", default: true, null: false
    t.json "disabled_sources", default: [], null: false
    t.text "openrouter_api_key"
    t.string "openrouter_model"
    t.text "gmail_user"
    t.text "gmail_app_password"
    t.text "api_token"
    t.datetime "onboarded_at"
    t.string "ai_plan", default: "free", null: false
    t.datetime "routines_seeded_at"
    t.string "locale", default: "auto", null: false
    t.string "detected_locale"
    t.boolean "notify_interviews", default: true, null: false
    t.json "dismissed_suggestions", default: [], null: false
    t.boolean "notify_weekly_summary", default: true, null: false
    t.date "weekly_summary_sent_on"
  end

  create_table "source_runs", force: :cascade do |t|
    t.string "source", null: false
    t.string "status", default: "running", null: false
    t.integer "fetched_count", default: 0, null: false
    t.integer "created_count", default: 0, null: false
    t.text "error_message"
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["source", "created_at"], name: "index_source_runs_on_source_and_created_at"
  end

  create_table "target_companies", force: :cascade do |t|
    t.string "name", null: false
    t.string "ats", null: false
    t.string "board_slug", null: false
    t.boolean "active", default: true, null: false
    t.boolean "example", default: false, null: false
    t.datetime "last_fetched_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discovered_at"
    t.integer "discovered_from_id"
    t.index ["ats", "board_slug"], name: "index_target_companies_on_ats_and_board_slug", unique: true
    t.index ["discovered_from_id"], name: "index_target_companies_on_discovered_from_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "ai_artifacts", "job_postings", on_delete: :cascade
  add_foreign_key "application_emails", "job_applications", on_delete: :cascade
  add_foreign_key "job_applications", "job_postings", on_delete: :nullify
  add_foreign_key "routine_items", "routine_slots"
  add_foreign_key "routine_slots", "routines"
  add_foreign_key "sessions", "users"
  add_foreign_key "target_companies", "job_postings", column: "discovered_from_id", on_delete: :nullify
end
