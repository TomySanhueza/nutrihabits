class CreatePatientHistories < ActiveRecord::Migration[7.1]
  def change
    create_table :patient_histories do |t|
      t.references :patient, null: false, foreign_key: true
      t.references :nutritionist, null: false, foreign_key: true
      t.references :nutrition_plan, null: false, foreign_key: true
      t.date :visit_date
      t.text :notes
      t.float :weight
      t.text :metrics

      t.timestamps
    end
  end
end
