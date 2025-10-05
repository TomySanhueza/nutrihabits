class UpdateMealLogsTable < ActiveRecord::Migration[7.1]
  def change
    # Cambiar relación de patient_id a meal_id
    remove_reference :meal_logs, :patient, foreign_key: true
    add_reference :meal_logs, :meal, foreign_key: true

    # Eliminar columna ai_macros
    remove_column :meal_logs, :ai_macros, :text

    # Agregar nuevas columnas
    add_column :meal_logs, :meal_type, :string
    add_column :meal_logs, :ai_protein, :float
    add_column :meal_logs, :ai_carbs, :float
    add_column :meal_logs, :ai_fat, :float

    # Cambiar ai_health_score de integer a float
    change_column :meal_logs, :ai_health_score, :float
  end
end
