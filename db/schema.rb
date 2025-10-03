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

ActiveRecord::Schema[7.1].define(version: 2025_10_03_150553) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "nutrition_plans", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.bigint "nutritionist_id", null: false
    t.string "objective"
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

  add_foreign_key "nutrition_plans", "nutritionists"
  add_foreign_key "nutrition_plans", "patients"
  add_foreign_key "patients", "nutritionists"
  add_foreign_key "profiles", "nutritionists"
  add_foreign_key "profiles", "patients"
end
