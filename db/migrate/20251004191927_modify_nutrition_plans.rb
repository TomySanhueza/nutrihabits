class ModifyNutritionPlans < ActiveRecord::Migration[7.1]
  def change
    change_column :nutrition_plans, :meal_distribution, :text
    change_column :nutrition_plans, :objective, :text
  end
end
