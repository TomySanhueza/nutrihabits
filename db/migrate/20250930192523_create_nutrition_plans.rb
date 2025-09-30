class CreateNutritionPlans < ActiveRecord::Migration[7.1]
  def change
    create_table :nutrition_plans do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :nutritionist_id
      t.string :objective
      t.float :calories
      t.float :protein
      t.float :fat
      t.float :carbs
      t.jsonb :meal_distribution
      t.text :notes
      t.string :status

      t.timestamps
    end
  end
end
