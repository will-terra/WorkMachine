class AddWeeklySummaryToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :notify_weekly_summary, :boolean, default: true, null: false
    add_column :settings, :weekly_summary_sent_on, :date
  end
end
