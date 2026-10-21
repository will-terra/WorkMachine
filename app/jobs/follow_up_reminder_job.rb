# Every morning at 8am in the profile's time zone (the job runs every hour and acts at 8):
# applications sent more than 5 days ago without any answer get a follow-up date for today,
# and a notification lists the follow-ups due, opening the follow-up message already filled in.
class FollowUpReminderJob < ApplicationJob
  queue_as :default
  HOUR = 8

  def perform(date = nil)
    return if date.nil? && Time.current.hour != HOUR

    date ||= Date.current
    JobApplication.waiting_answer(date).find_each do |application|
      application.update!(next_follow_up_on: date)
    end
    notify(JobApplication.follow_up_due(date).order(:applied_on).to_a)
  end

  private
    def notify(due)
      return if due.empty? || !Setting.current.notify_follow_ups?

      names = due.first(3).map(&:company).to_sentence(last_word_connector: " e ")
      names += " e mais #{due.size - 3}" if due.size > 3
      PushSender.deliver_all(
        title: due.one? ? "Follow-up hoje: #{due.first.company}" : "#{due.size} follow-ups para hoje",
        body: "Sem resposta há #{JobApplication::FOLLOW_UP_AFTER.in_days.to_i}+ dias: #{names}. A mensagem de follow-up já vem preenchida.",
        path: due.one? ? MessageTemplate.follow_up_path(due.first) : "/",
        tag: "follow-ups"
      )
    end
end
