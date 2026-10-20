# One execution of an aggregator source. Used to respect each source's minimum interval
# (Remotive asks for at most 4 calls a day) and to show the last results on the triage screen.
class SourceRun < ApplicationRecord
  enum :status, { running: "running", succeeded: "succeeded", failed: "failed" }, prefix: true, validate: true

  validates :source, presence: true

  scope :latest_first, -> { order(created_at: :desc, id: :desc) }

  def self.last_success_at(source)
    status_succeeded.where(source:).maximum(:created_at)
  end

  # Latest run of each source, for the status panel.
  def self.latest_per_source
    where(id: group(:source).select("MAX(id)")).order(:source)
  end

  def finish!(fetched:, created:)
    update!(status: "succeeded", fetched_count: fetched, created_count: created, finished_at: Time.current)
  end

  def fail!(error)
    update!(status: "failed", error_message: "#{error.class}: #{error.message}".truncate(1000), finished_at: Time.current)
  end
end
