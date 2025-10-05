class AddAiMetadataToNutritionPlans < ActiveRecord::Migration[7.1]
  def change
    add_column :nutrition_plans, :ai_metadata, :jsonb, default: {}, null: false
    add_column :nutrition_plans, :ai_criteria_explanation, :text
  end
end
