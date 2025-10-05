class CreateWeightPatients < ActiveRecord::Migration[7.1]
  def change
    create_table :weight_patients do |t|
      t.references :patient, null: false, foreign_key: true
      t.date :date
      t.float :weight

      t.timestamps
    end
  end
end
