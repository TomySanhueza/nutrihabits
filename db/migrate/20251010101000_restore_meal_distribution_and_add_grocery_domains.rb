class RestoreMealDistributionAndAddGroceryDomains < ActiveRecord::Migration[7.1]
  def up
    change_column :nutrition_plans,
                  :meal_distribution,
                  :jsonb,
                  using: "CASE WHEN meal_distribution IS NULL OR meal_distribution = '' THEN NULL ELSE meal_distribution::jsonb END"

    create_table :user_supermarket_preferences do |t|
      t.references :patient, null: false, foreign_key: true, index: { unique: true }
      t.string :country_code, null: false
      t.string :currency, null: false
      t.string :retailer_slug, null: false
      t.string :retailer_name
      t.jsonb :fallback_retailers, default: []

      t.timestamps
    end

    create_table :grocery_lists do |t|
      t.references :patient, null: false, foreign_key: true
      t.references :nutrition_plan, foreign_key: true
      t.date :date_from, null: false
      t.date :date_to, null: false
      t.string :retailer_slug, null: false
      t.string :country_code, null: false
      t.string :currency, null: false
      t.string :generated_by, null: false, default: "patient"
      t.string :status, null: false, default: "generated"
      t.jsonb :source_summary, default: {}

      t.timestamps
    end

    create_table :grocery_list_items do |t|
      t.references :grocery_list, null: false, foreign_key: true
      t.string :ingredient_name, null: false
      t.string :normalized_name, null: false
      t.decimal :quantity_value, precision: 10, scale: 2, default: 0, null: false
      t.string :quantity_unit, null: false, default: "unit"
      t.jsonb :meal_types, default: []
      t.jsonb :source_dates, default: []
      t.text :notes

      t.timestamps
    end

    create_table :grocery_product_matches do |t|
      t.references :grocery_list_item, null: false, foreign_key: true
      t.string :external_id
      t.string :retailer_slug, null: false
      t.string :country_code, null: false
      t.string :name, null: false
      t.string :brand
      t.string :package_size
      t.decimal :price, precision: 10, scale: 2
      t.string :currency
      t.boolean :availability, default: true, null: false
      t.string :product_url
      t.integer :rank
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    create_table :patient_priority_snapshots do |t|
      t.references :patient, null: false, foreign_key: true
      t.references :nutritionist, null: false, foreign_key: true
      t.string :priority_level, null: false
      t.float :score, default: 0, null: false
      t.jsonb :reasons, default: []
      t.text :recommended_action
      t.text :outreach_draft
      t.datetime :captured_at, null: false

      t.timestamps
    end
  end

  def down
    drop_table :patient_priority_snapshots
    drop_table :grocery_product_matches
    drop_table :grocery_list_items
    drop_table :grocery_lists
    drop_table :user_supermarket_preferences
    change_column :nutrition_plans, :meal_distribution, :text
  end
end
