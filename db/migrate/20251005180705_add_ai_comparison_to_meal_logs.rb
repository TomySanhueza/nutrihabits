class AddAiComparisonToMealLogs < ActiveRecord::Migration[7.1]
  def change
    add_column :meal_logs, :ai_comparison, :jsonb
  end
end
