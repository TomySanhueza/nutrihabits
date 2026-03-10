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

ActiveRecord::Schema[7.1].define(version: 2026_03_10_111000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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

  create_table "chats", force: :cascade do |t|
    t.bigint "nutritionist_id", null: false
    t.bigint "patient_id", null: false
    t.string "title"
    t.datetime "last_read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["nutritionist_id"], name: "index_chats_on_nutritionist_id"
    t.index ["patient_id"], name: "index_chats_on_patient_id"
  end

  create_table "grocery_list_items", force: :cascade do |t|
    t.bigint "grocery_list_id", null: false
    t.string "ingredient_name", null: false
    t.string "normalized_name", null: false
    t.decimal "quantity_value", precision: 10, scale: 2, default: "0.0", null: false
    t.string "quantity_unit", default: "unit", null: false
    t.jsonb "meal_types", default: []
    t.jsonb "source_dates", default: []
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["grocery_list_id"], name: "index_grocery_list_items_on_grocery_list_id"
  end

  create_table "grocery_lists", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.bigint "nutrition_plan_id"
    t.date "date_from", null: false
    t.date "date_to", null: false
    t.string "retailer_slug", null: false
    t.string "country_code", null: false
    t.string "currency", null: false
    t.string "generated_by", default: "patient", null: false
    t.string "status", default: "generated", null: false
    t.jsonb "source_summary", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["nutrition_plan_id"], name: "index_grocery_lists_on_nutrition_plan_id"
    t.index ["patient_id"], name: "index_grocery_lists_on_patient_id"
  end

  create_table "grocery_product_matches", force: :cascade do |t|
    t.bigint "grocery_list_item_id", null: false
    t.string "external_id"
    t.string "retailer_slug", null: false
    t.string "country_code", null: false
    t.string "name", null: false
    t.string "brand"
    t.string "package_size"
    t.decimal "price", precision: 10, scale: 2
    t.string "currency"
    t.boolean "availability", default: true, null: false
    t.string "product_url"
    t.integer "rank"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["grocery_list_item_id"], name: "index_grocery_product_matches_on_grocery_list_item_id"
  end

  create_table "meal_logs", force: :cascade do |t|
    t.string "photo_url"
    t.float "ai_calories"
    t.float "ai_health_score"
    t.text "ai_feedback"
    t.datetime "logged_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "meal_id"
    t.float "ai_protein"
    t.float "ai_carbs"
    t.float "ai_fat"
    t.jsonb "ai_comparison"
    t.string "analysis_status", default: "not_requested", null: false
    t.text "analysis_error"
    t.index ["analysis_status"], name: "index_meal_logs_on_analysis_status"
    t.index ["meal_id"], name: "index_meal_logs_on_meal_id"
  end

  create_table "meals", force: :cascade do |t|
    t.bigint "plan_id", null: false
    t.string "meal_type"
    t.float "calories"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ingredients"
    t.string "recipe"
    t.float "protein"
    t.float "carbs"
    t.float "fat"
    t.index ["plan_id"], name: "index_meals_on_plan_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "chat_id", null: false
    t.text "content"
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_messages_on_chat_id"
  end

  create_table "nutrition_plans", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.bigint "nutritionist_id", null: false
    t.text "objective"
    t.float "calories"
    t.float "protein"
    t.float "fat"
    t.float "carbs"
    t.jsonb "meal_distribution"
    t.text "notes"
    t.text "ai_rationale"
    t.string "status"
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["nutritionist_id"], name: "index_nutrition_plans_on_nutritionist_id"
    t.index ["patient_id"], name: "index_nutrition_plans_on_patient_id"
  end

  create_table "nutritionist_ai_chats", force: :cascade do |t|
    t.bigint "nutritionist_id", null: false
    t.jsonb "context"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.string "model"
    t.index ["nutritionist_id"], name: "index_nutritionist_ai_chats_on_nutritionist_id"
  end

  create_table "nutritionist_ai_messages", force: :cascade do |t|
    t.bigint "nutritionist_ai_chat_id", null: false
    t.text "content"
    t.string "role"
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["nutritionist_ai_chat_id"], name: "index_nutritionist_ai_messages_on_nutritionist_ai_chat_id"
  end

  create_table "nutritionists", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.index ["email"], name: "index_nutritionists_on_email", unique: true
    t.index ["reset_password_token"], name: "index_nutritionists_on_reset_password_token", unique: true
  end

  create_table "patient_ai_chats", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.jsonb "context"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["patient_id"], name: "index_patient_ai_chats_on_patient_id"
  end

  create_table "patient_ai_messages", force: :cascade do |t|
    t.bigint "patient_ai_chat_id", null: false
    t.text "content"
    t.string "role"
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["patient_ai_chat_id"], name: "index_patient_ai_messages_on_patient_ai_chat_id"
  end

  create_table "patient_histories", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.bigint "nutritionist_id", null: false
    t.bigint "nutrition_plan_id", null: false
    t.date "visit_date"
    t.text "notes"
    t.float "weight"
    t.text "metrics"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["nutrition_plan_id"], name: "index_patient_histories_on_nutrition_plan_id"
    t.index ["nutritionist_id"], name: "index_patient_histories_on_nutritionist_id"
    t.index ["patient_id"], name: "index_patient_histories_on_patient_id"
  end

  create_table "patient_priority_snapshots", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.bigint "nutritionist_id", null: false
    t.string "priority_level", null: false
    t.float "score", default: 0.0, null: false
    t.jsonb "reasons", default: []
    t.text "recommended_action"
    t.text "outreach_draft"
    t.datetime "captured_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["nutritionist_id"], name: "index_patient_priority_snapshots_on_nutritionist_id"
    t.index ["patient_id"], name: "index_patient_priority_snapshots_on_patient_id"
  end

  create_table "patients", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "nutritionist_id", null: false
    t.string "onboarding_state", default: "draft", null: false
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.datetime "access_suspended_at"
    t.datetime "last_seen_at"
    t.index ["email"], name: "index_patients_on_email", unique: true
    t.index ["nutritionist_id"], name: "index_patients_on_nutritionist_id"
    t.index ["onboarding_state"], name: "index_patients_on_onboarding_state"
    t.index ["reset_password_token"], name: "index_patients_on_reset_password_token", unique: true
  end

  create_table "plans", force: :cascade do |t|
    t.bigint "nutrition_plan_id", null: false
    t.date "date"
    t.string "mood"
    t.string "energy_level"
    t.string "activity"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["nutrition_plan_id"], name: "index_plans_on_nutrition_plan_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.float "weight"
    t.float "height"
    t.text "goals"
    t.text "conditions"
    t.text "lifestyle"
    t.text "diagnosis"
    t.bigint "patient_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["patient_id"], name: "index_profiles_on_patient_id", unique: true
  end

  create_table "user_supermarket_preferences", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.string "country_code", null: false
    t.string "currency", null: false
    t.string "retailer_slug", null: false
    t.string "retailer_name"
    t.jsonb "fallback_retailers", default: []
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["patient_id"], name: "index_user_supermarket_preferences_on_patient_id", unique: true
  end

  create_table "weight_patients", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.date "date"
    t.float "weight"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["patient_id"], name: "index_weight_patients_on_patient_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "chats", "nutritionists"
  add_foreign_key "chats", "patients"
  add_foreign_key "grocery_list_items", "grocery_lists"
  add_foreign_key "grocery_lists", "nutrition_plans"
  add_foreign_key "grocery_lists", "patients"
  add_foreign_key "grocery_product_matches", "grocery_list_items"
  add_foreign_key "meal_logs", "meals"
  add_foreign_key "meals", "plans"
  add_foreign_key "messages", "chats"
  add_foreign_key "nutrition_plans", "nutritionists"
  add_foreign_key "nutrition_plans", "patients"
  add_foreign_key "nutritionist_ai_chats", "nutritionists"
  add_foreign_key "nutritionist_ai_messages", "nutritionist_ai_chats"
  add_foreign_key "patient_ai_chats", "patients"
  add_foreign_key "patient_ai_messages", "patient_ai_chats"
  add_foreign_key "patient_histories", "nutrition_plans"
  add_foreign_key "patient_histories", "nutritionists"
  add_foreign_key "patient_histories", "patients"
  add_foreign_key "patient_priority_snapshots", "nutritionists"
  add_foreign_key "patient_priority_snapshots", "patients"
  add_foreign_key "patients", "nutritionists"
  add_foreign_key "plans", "nutrition_plans"
  add_foreign_key "profiles", "patients"
  add_foreign_key "user_supermarket_preferences", "patients"
  add_foreign_key "weight_patients", "patients"
end
