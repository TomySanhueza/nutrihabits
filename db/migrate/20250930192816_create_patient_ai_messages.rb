class CreatePatientAiMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :patient_ai_messages do |t|
      t.references :patient_ai_chat, null: false, foreign_key: true
      t.text :content
      t.string :role

      t.timestamps
    end
  end
end
