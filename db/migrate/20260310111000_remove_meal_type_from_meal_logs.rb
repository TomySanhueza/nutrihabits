class RemoveMealTypeFromMealLogs < ActiveRecord::Migration[7.1]
  def up
    remove_column :meal_logs, :meal_type, :string
  end

  def down
    add_column :meal_logs, :meal_type, :string

    execute <<~SQL
      UPDATE meal_logs
      SET meal_type = meals.meal_type
      FROM meals
      WHERE meals.id = meal_logs.meal_id
    SQL
  end
end
