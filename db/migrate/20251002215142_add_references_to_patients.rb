class AddReferencesToPatients < ActiveRecord::Migration[7.1]
  def change
    add_reference :patients, :nutritionist, null: false, foreign_key: true
  end
end
