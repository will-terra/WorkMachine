# Every hour: from 6 p.m. the day before an interview (profile time zone), one notification with
# the time, opening the application's preparation. Each interview date is reminded once.
class InterviewReminderJob < ApplicationJob
  queue_as :default

  def perform
    due = JobApplication.interview_reminder_due
    return if due.empty?

    notify(due) if Setting.current.notify_interviews?
    JobApplication.where(id: due.map(&:id)).update_all(interview_reminded_at: Time.current)
  end

  private
    def notify(due)
      due.each do |application|
        today = application.interview_at.to_date == Date.current
        PushSender.deliver_all(
          title: I18n.t(today ? "notifications.interview_today" : "notifications.interview_tomorrow", company: application.company),
          body: I18n.t("notifications.interview_body", time: I18n.l(application.interview_at, format: :hour), role: application.role),
          path: Rails.application.routes.url_helpers.edit_job_application_path(application, anchor: "entrevista"),
          tag: "interview-#{application.id}"
        )
      end
    end
end
