class CreatePatientAiChats < ActiveRecord::Migration[7.1]
  def change
    create_table :patient_ai_chats do |t|
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
