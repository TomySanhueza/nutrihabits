class CreateMealLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :meal_logs do |t|
      t.references :patient, null: false, foreign_key: true
      t.string :photo_url
      t.float :ai_calories
      t.text :ai_macros
      t.integer :ai_health_score
      t.text :ai_feedback
      t.datetime :logged_at

      t.timestamps
    end
  end
end
