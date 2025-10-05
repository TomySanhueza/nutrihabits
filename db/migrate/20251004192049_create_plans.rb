class CreatePlans < ActiveRecord::Migration[7.1]
  def change
    create_table :plans do |t|
      t.references :nutrition_plan, null: false, foreign_key: true
      t.date :date
      t.string :mood
      t.string :energy_level
      t.string :activity
      t.text :notes

      t.timestamps
    end
  end
end
