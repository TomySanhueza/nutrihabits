class AddOperationalStateToPatientsAndMealLogs < ActiveRecord::Migration[7.1]
  def change
    add_column :patients, :onboarding_state, :string, default: "draft", null: false
    add_column :patients, :invitation_sent_at, :datetime
    add_column :patients, :invitation_accepted_at, :datetime
    add_column :patients, :access_suspended_at, :datetime
    add_column :patients, :last_seen_at, :datetime
    add_index :patients, :onboarding_state

    add_column :meal_logs, :analysis_status, :string, default: "not_requested", null: false
    add_column :meal_logs, :analysis_error, :text
    add_index :meal_logs, :analysis_status
  end
end
