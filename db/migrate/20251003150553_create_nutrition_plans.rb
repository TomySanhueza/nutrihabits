class CreateNutritionPlans < ActiveRecord::Migration[7.1]
  def change
    create_table :nutrition_plans do |t|
      t.references :patient, null: false, foreign_key: true
      t.references :nutritionist, null: false, foreign_key: true
      t.string :objective
      t.float :calories
      t.float :protein
      t.float :fat
      t.float :carbs
      t.jsonb :meal_distribution
      t.text :notes
      t.text :ai_rationale
      t.string :status
      t.date :start_date
      t.date :end_date

      t.timestamps
    end
  end
end
