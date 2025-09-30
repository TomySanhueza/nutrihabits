class CreateNutritionistAiChats < ActiveRecord::Migration[7.1]
  def change
    create_table :nutritionist_ai_chats do |t|
      t.integer :nutritionist_id

      t.timestamps
    end
  end
end
