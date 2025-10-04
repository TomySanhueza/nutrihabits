class CreateNutritionistAiChats < ActiveRecord::Migration[7.1]
  def change
    create_table :nutritionist_ai_chats do |t|
      t.references :nutritionist, null: false, foreign_key: true
      t.jsonb :context

      t.timestamps
    end
  end
end
