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

ActiveRecord::Schema[7.1].define(version: 2025_09_30_201100) do
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
    t.integer "nutritionist_id"
    t.integer "patient_id"
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "daily_check_ins", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "date"
    t.boolean "breakfast_adherence"
    t.boolean "lunch_adherence"
    t.boolean "dinner_adherence"
    t.boolean "snack_adherence"
    t.float "weight"
    t.integer "energy_level"
    t.string "mood"
    t.jsonb "activity"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_daily_check_ins_on_user_id"
  end

  create_table "meal_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "photo_url"
    t.float "ai_calories"
    t.jsonb "ai_macros"
    t.integer "ai_health_score"
    t.text "ai_feedback"
    t.datetime "logged_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_meal_logs_on_user_id"
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
    t.bigint "user_id", null: false
    t.integer "nutritionist_id"
    t.string "objective"
    t.float "calories"
    t.float "protein"
    t.float "fat"
    t.float "carbs"
    t.jsonb "meal_distribution"
    t.text "notes"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_nutrition_plans_on_user_id"
  end

  create_table "nutritionist_ai_chats", force: :cascade do |t|
    t.integer "nutritionist_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "nutritionist_ai_messages", force: :cascade do |t|
    t.bigint "nutritionist_ai_chat_id", null: false
    t.text "content"
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["nutritionist_ai_chat_id"], name: "index_nutritionist_ai_messages_on_nutritionist_ai_chat_id"
  end

  create_table "patient_ai_chats", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_patient_ai_chats_on_user_id"
  end

  create_table "patient_ai_messages", force: :cascade do |t|
    t.bigint "patient_ai_chat_id", null: false
    t.text "content"
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["patient_ai_chat_id"], name: "index_patient_ai_messages_on_patient_ai_chat_id"
  end

  create_table "patient_histories", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "nutritionist_id"
    t.date "visit_date"
    t.text "notes"
    t.float "weight"
    t.jsonb "metrics"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_patient_histories_on_user_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.float "weight"
    t.float "height"
    t.text "goals"
    t.text "conditions"
    t.text "lifestyle"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_profiles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
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
    t.string "role"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "daily_check_ins", "users"
  add_foreign_key "meal_logs", "users"
  add_foreign_key "messages", "chats"
  add_foreign_key "nutrition_plans", "users"
  add_foreign_key "nutritionist_ai_messages", "nutritionist_ai_chats"
  add_foreign_key "patient_ai_chats", "users"
  add_foreign_key "patient_ai_messages", "patient_ai_chats"
  add_foreign_key "patient_histories", "users"
  add_foreign_key "profiles", "users"
end
