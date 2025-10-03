class CreateProfiles < ActiveRecord::Migration[7.1]
  def change
    create_table :profiles do |t|
      t.float :weight
      t.float :height
      t.text :goals
      t.text :conditions
      t.text :lifestyle
      t.text :diagnosis
      t.references :nutritionist, null: false, foreign_key: true
      t.references :patient, null: false, foreign_key: true

      t.timestamps
    end
  end
end
