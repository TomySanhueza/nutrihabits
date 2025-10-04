class CreateMeals < ActiveRecord::Migration[7.1]
  def change
    create_table :meals do |t|
      t.references :plan, null: false, foreign_key: true
      t.string :meal_type
      t.text :detail
      t.float :calories
      t.string :status

      t.timestamps
    end
  end
end
