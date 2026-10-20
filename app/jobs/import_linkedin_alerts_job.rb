# Every hour: imports the LinkedIn job alerts that arrived in Gmail (config/recurring.yml).
class ImportLinkedinAlertsJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: "import_linkedin_alerts", on_conflict: :discard

  def perform
    unless LinkedinAlerts::Importer.configured?
      Rails.logger.info("[ImportLinkedinAlertsJob] GMAIL_USER/GMAIL_APP_PASSWORD não configurados; nada a fazer.")
      return
    end

    run = SourceRun.create!(source: "linkedin_alert")
    result = LinkedinAlerts::Importer.new.call
    run.finish!(fetched: result.postings, created: result.created)
    NewPostingsNotifier.call(since: run.created_at)
  rescue StandardError => e
    run&.fail!(e)
    Rails.error.report(e, handled: true, context: { source: "linkedin_alert" })
  end
end
