class RemoveRedundantNutritionistReferenceFromProfiles < ActiveRecord::Migration[7.1]
  def up
    duplicate_patient_ids = select_values(<<~SQL.squish)
      SELECT patient_id
      FROM profiles
      GROUP BY patient_id
      HAVING COUNT(*) > 1
    SQL

    if duplicate_patient_ids.any?
      raise StandardError, "Cannot enforce unique profiles per patient. Duplicate patient_ids: #{duplicate_patient_ids.join(', ')}"
    end

    remove_reference :profiles, :nutritionist, foreign_key: true
    remove_index :profiles, :patient_id if index_exists?(:profiles, :patient_id)
    add_index :profiles, :patient_id, unique: true
  end

  def down
    remove_index :profiles, :patient_id
    add_reference :profiles, :nutritionist, null: true, foreign_key: true

    execute <<~SQL
      UPDATE profiles
      SET nutritionist_id = patients.nutritionist_id
      FROM patients
      WHERE patients.id = profiles.patient_id
    SQL

    change_column_null :profiles, :nutritionist_id, false
  end
end
