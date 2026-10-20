# Every hour (config/recurring.yml): reads the companies' replies in Gmail and updates the kanban.
class ImportApplicationRepliesJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: "import_application_replies", on_conflict: :discard

  def perform
    return unless GmailSession.configured? && Setting.current.track_replies?

    run = SourceRun.create!(source: "application_replies")
    result = ApplicationReplies::Importer.new.call
    run.finish!(fetched: result.matched, created: result.moved)
  rescue StandardError => e
    run&.fail!(e)
    Rails.error.report(e, handled: true, context: { source: "application_replies" })
  end
end
