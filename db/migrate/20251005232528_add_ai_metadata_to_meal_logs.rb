class AddAiMetadataToMealLogs < ActiveRecord::Migration[7.1]
  def change
    add_column :meal_logs, :ai_metadata, :jsonb, default: {}, null: false
  end
end
