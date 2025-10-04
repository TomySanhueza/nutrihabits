class CreatePatientAiChats < ActiveRecord::Migration[7.1]
  def change
    create_table :patient_ai_chats do |t|
      t.references :patient, null: false, foreign_key: true
      t.jsonb :context

      t.timestamps
    end
  end
end
