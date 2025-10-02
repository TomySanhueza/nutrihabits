class AddColumnsToNutritionists < ActiveRecord::Migration[7.1]
  def change
    add_column :nutritionists, :first_name, :string
    add_column :nutritionists, :last_name, :string
    add_column :nutritionists, :phone, :string
  end
end
