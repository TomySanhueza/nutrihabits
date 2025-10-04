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

ActiveRecord::Schema[7.1].define(version: 2025_10_04_192451) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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

  create_table "meal_logs", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.string "photo_url"
    t.float "ai_calories"
    t.text "ai_macros"
    t.integer "ai_health_score"
    t.text "ai_feedback"
    t.datetime "logged_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["patient_id"], name: "index_meal_logs_on_patient_id"
  end

  create_table "meals", force: :cascade do |t|
    t.bigint "plan_id", null: false
    t.string "meal_type"
    t.text "detail"
    t.float "calories"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.text "meal_distribution"
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
    t.index ["email"], name: "index_patients_on_email", unique: true
    t.index ["nutritionist_id"], name: "index_patients_on_nutritionist_id"
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
    t.bigint "nutritionist_id", null: false
    t.bigint "patient_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["nutritionist_id"], name: "index_profiles_on_nutritionist_id"
    t.index ["patient_id"], name: "index_profiles_on_patient_id"
  end

  add_foreign_key "chats", "nutritionists"
  add_foreign_key "chats", "patients"
  add_foreign_key "meal_logs", "patients"
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
  add_foreign_key "patients", "nutritionists"
  add_foreign_key "plans", "nutrition_plans"
  add_foreign_key "profiles", "nutritionists"
  add_foreign_key "profiles", "patients"
end
