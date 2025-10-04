class CreateNutritionistAiMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :nutritionist_ai_messages do |t|
      t.references :nutritionist_ai_chat, null: false, foreign_key: true
      t.text :content
      t.string :role
      t.jsonb :metadata

      t.timestamps
    end
  end
end
