class AddAutoDismiss < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :auto_dismiss_restricted, :boolean, null: false, default: true
    add_column :settings, :auto_dismiss_below_score, :integer
    add_column :job_postings, :auto_dismissed_reason, :string
  end
end
