class CreateChats < ActiveRecord::Migration[7.1]
  def change
    create_table :chats do |t|
      t.integer :nutritionist_id
      t.integer :patient_id
      t.string :title

      t.timestamps
    end
  end
end
