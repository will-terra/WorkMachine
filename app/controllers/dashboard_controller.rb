class DashboardController < ApplicationController
  def show
    @new_postings = JobPosting.triage_new.ranked.limit(8)
    @new_postings_count = JobPosting.triage_new.count
    @follow_ups = JobApplication.follow_up_due.order(:next_follow_up_on)
    @waiting_answer = JobApplication.waiting_answer.order(:applied_on)
    @pipeline = JobApplication.group(:status).count
    @checked = Routine.checked_keys
  end
end
