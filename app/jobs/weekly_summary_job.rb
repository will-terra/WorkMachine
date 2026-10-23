# Sundays from 6 p.m. (profile time zone): one notification with the week in numbers and a tip,
# opening Métricas. Sent once a week, even if the app was off at 6 p.m.
class WeeklySummaryJob < ApplicationJob
  queue_as :default
  HOUR = 18

  def perform
    setting = Setting.current
    return unless Date.current.sunday? && Time.current.hour >= HOUR && setting.weekly_summary_sent_on != Date.current

    setting.update!(weekly_summary_sent_on: Date.current)
    return unless setting.notify_weekly_summary?

    summary = WeeklySummary.new
    PushSender.deliver_all(title: I18n.t("weekly_summary.title"), body: summary.lines.join("\n"),
                           path: Rails.application.routes.url_helpers.metrics_path, tag: "weekly-summary")
  end
end
