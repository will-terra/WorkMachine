# Hourly copy of the main SQLite database to backups/ (docker-compose.yml mounts a Windows
# folder there, WORKMACHINE_BACKUP_DIR). Keeps every copy of the last KEEP_HOURS hours and,
# before that, the last copy of each day for KEEP_DAYS days. Uses SQLite's online backup
# API on its own read-only connection, so the app keeps running during the copy.
class DatabaseBackup
  KEEP_HOURS = 24
  KEEP_DAYS = 14
  PATTERN = "workmachine-*.sqlite3".freeze
  NAME = /workmachine-(\d{4}-\d{2}-\d{2})-(\d{2})(\d{2})\.sqlite3\z/
  BUSY_RETRIES = 40

  class Error < StandardError; end

  def self.dir
    Rails.root.join("backups")
  end

  def self.files
    dir.glob(PATTERN).select { it.basename.to_s.match?(NAME) }.sort.reverse
  end

  def self.call(now: Time.current)
    new.call(now:)
  end

  def call(now:)
    self.class.dir.mkpath
    path = self.class.dir.join("workmachine-#{now.strftime("%Y-%m-%d-%H%M")}.sqlite3")
    copy_to(path)
    prune(now)
    Setting.current.update!(last_backup_at: now, last_backup_error: nil)
    path
  rescue StandardError => e
    Setting.current.update!(last_backup_error: "#{e.class}: #{e.message}".truncate(500))
    raise
  end

  private
    def copy_to(path)
      temp = Pathname("#{path}.tmp")
      source = SQLite3::Database.new(database_path, readonly: true)
      destination = SQLite3::Database.new(temp.to_s)
      backup = SQLite3::Backup.new(destination, "main", source, "main")
      step_until_done(backup)
      backup.finish
      # A single self-contained file: opening the copy later creates no -wal/-shm files.
      destination.execute("PRAGMA journal_mode = DELETE")
      destination.close
      temp.rename(path)
    ensure
      source&.close
      destination&.close unless destination.nil? || destination.closed?
      temp.delete if temp&.exist?
    end

    # SQLite answers BUSY while another connection is writing; wait a little and go on.
    def step_until_done(backup)
      BUSY_RETRIES.times do
        case backup.step(-1)
        when SQLite3::Constants::ErrorCode::DONE then return
        when SQLite3::Constants::ErrorCode::BUSY, SQLite3::Constants::ErrorCode::LOCKED then sleep 0.25
        else raise Error, "a cópia do SQLite falhou"
        end
      end
      raise Error, "o banco ficou ocupado por tempo demais"
    end

    def database_path
      Rails.root.join(ActiveRecord::Base.connection_db_config.database).to_s
    end

    # Every copy from the last KEEP_HOURS hours, then the newest copy of each of the last KEEP_DAYS days.
    def prune(now)
      recent, older = self.class.files.partition { taken_at(it) > now - KEEP_HOURS.hours }
      daily = older.group_by { taken_at(it).to_date }.values.map(&:first).first(KEEP_DAYS)
      (older - daily).each(&:delete)
      recent
    end

    def taken_at(file)
      date, hour, minute = file.basename.to_s.match(NAME).captures
      Time.zone.parse("#{date} #{hour}:#{minute}")
    end
end
