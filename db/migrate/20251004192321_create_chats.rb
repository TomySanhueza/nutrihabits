class CreateChats < ActiveRecord::Migration[7.1]
  def change
    create_table :chats do |t|
      t.references :nutritionist, null: false, foreign_key: true
      t.references :patient, null: false, foreign_key: true
      t.string :title
      t.datetime :last_read_at

      t.timestamps
    end
  end
end
