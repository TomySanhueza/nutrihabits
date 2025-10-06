class AddTitleAndModelToNutritionistAiChats < ActiveRecord::Migration[7.1]
  def change
    add_column :nutritionist_ai_chats, :title, :string
    add_column :nutritionist_ai_chats, :model, :string
  end
end
