class AddBackupToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :last_backup_at, :datetime
    add_column :settings, :last_backup_error, :text
  end
end
