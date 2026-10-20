# Every hour (config/recurring.yml): copies the database to the backups folder.
class DatabaseBackupJob < ApplicationJob
  queue_as :default

  def perform
    DatabaseBackup.call
  end
end
