class CreatePatientHistories < ActiveRecord::Migration[7.1]
  def change
    create_table :patient_histories do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :nutritionist_id
      t.date :visit_date
      t.text :notes
      t.float :weight
      t.jsonb :metrics

      t.timestamps
    end
  end
end
