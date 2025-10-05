class ModifyMealsTable < ActiveRecord::Migration[7.1]
  def change
    remove_column :meals, :detail, :text
    add_column :meals, :ingredients, :string
    add_column :meals, :recipe, :string
    add_column :meals, :protein, :float
    add_column :meals, :carbs, :float
    add_column :meals, :fat, :float
  end
end
