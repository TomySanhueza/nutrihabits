class CreateDailyCheckIns < ActiveRecord::Migration[7.1]
  def change
    create_table :daily_check_ins do |t|
      t.references :user, null: false, foreign_key: true
      t.date :date
      t.boolean :breakfast_adherence
      t.boolean :lunch_adherence
      t.boolean :dinner_adherence
      t.boolean :snack_adherence
      t.float :weight
      t.integer :energy_level
      t.string :mood
      t.jsonb :activity
      t.text :notes

      t.timestamps
    end
  end
end
