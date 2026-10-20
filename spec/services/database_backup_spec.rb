require "rails_helper"

RSpec.describe DatabaseBackup do
  # The backup reads the database file through its own connection, so the data must be committed.
  self.use_transactional_tests = false

  let(:dir) { Pathname(Dir.mktmpdir) }

  before { allow(described_class).to receive(:dir).and_return(dir) }

  after do
    FileUtils.rm_rf(dir)
    [ JobApplication, Setting ].each(&:delete_all)
  end

  def touch(name)
    FileUtils.touch(dir.join("workmachine-#{name}.sqlite3"))
  end

  it "copies the committed database into a timestamped file" do
    create(:job_application, company: "Acme")

    path = described_class.call(now: Time.zone.local(2026, 10, 21, 14, 30))

    expect(path.basename.to_s).to eq("workmachine-2026-10-21-1430.sqlite3")
    copy = SQLite3::Database.new(path.to_s)
    expect(copy.get_first_value("SELECT company FROM job_applications")).to eq("Acme")
    expect(copy.get_first_value("PRAGMA journal_mode")).to eq("delete")
    copy.close
    expect(Setting.current).to have_attributes(last_backup_at: Time.zone.local(2026, 10, 21, 14, 30), last_backup_error: nil)
    expect(dir.glob("*.tmp")).to be_empty
  end

  it "keeps every copy of the last 24 hours and one per day for 14 days" do
    now = Time.zone.local(2026, 10, 21, 14, 30)
    touch("2026-10-21-1330")
    touch("2026-10-20-1530")                                   # within 24 h
    touch("2026-10-20-0930")                                   # older than 24 h: newest of its day
    touch("2026-10-20-0830")                                   # same day, older: removed
    (1..20).each { |day| touch("2026-09-#{format("%02d", day)}-2330") } # one per day, only 14 days kept

    described_class.call(now:)
    names = described_class.files.map { it.basename.to_s.delete_prefix("workmachine-").delete_suffix(".sqlite3") }

    expect(names.first(3)).to eq(%w[2026-10-21-1430 2026-10-21-1330 2026-10-20-1530])
    expect(names).to include("2026-10-20-0930")
    expect(names).not_to include("2026-10-20-0830")
    expect(names.size).to eq(3 + 14)
  end

  it "waits while the database is busy and records failures" do
    backup = instance_double(SQLite3::Backup, finish: true)
    allow(SQLite3::Backup).to receive(:new).and_return(backup)
    allow(backup).to receive(:step).and_return(SQLite3::Constants::ErrorCode::BUSY, SQLite3::Constants::ErrorCode::DONE)
    allow_any_instance_of(described_class).to receive(:sleep)

    expect(described_class.call).to be_exist

    allow(backup).to receive(:step).and_return(SQLite3::Constants::ErrorCode::IOERR)
    expect { described_class.call }.to raise_error(DatabaseBackup::Error, /falhou/)
    expect(Setting.current.last_backup_error).to include("falhou")

    allow(backup).to receive(:step).and_return(SQLite3::Constants::ErrorCode::LOCKED)
    expect { described_class.call }.to raise_error(DatabaseBackup::Error, /ocupado/)
  end

  it "runs every hour" do
    tasks = YAML.load(Rails.root.join("config/recurring.yml").read, aliases: true).fetch("development")

    expect(tasks.dig("database_backup", "schedule")).to eq("every hour at minute 30")
    allow(described_class).to receive(:call)
    DatabaseBackupJob.perform_now
    expect(described_class).to have_received(:call)
  end
end
