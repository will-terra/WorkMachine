# Every morning: applications sent more than 5 days ago without any answer get a
# follow-up date for today, so they show up on the dashboard.
class FollowUpReminderJob < ApplicationJob
  queue_as :default

  def perform(date = Date.current)
    JobApplication.waiting_answer(date).find_each do |application|
      application.update!(next_follow_up_on: date)
    end
  end
end
