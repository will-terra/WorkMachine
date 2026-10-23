class DashboardController < ApplicationController
  GMAIL_SOURCES = %w[linkedin_alert application_replies].freeze

  def show
    @setup_routines, @routines = Routine.current.partition(&:once?)
    @checked = Routine.checked_keys
    @pipeline = JobApplication.group(:status).count
    @new_postings = JobPosting.triage_new.ranked.limit(6)
    @new_postings_count = JobPosting.triage_new.count
    @follow_ups = JobApplication.follow_up_due.order(:next_follow_up_on).to_a | JobApplication.waiting_answer.order(:applied_on).to_a
    @interviews = JobApplication.upcoming_interviews.where(interview_at: ..14.days.from_now).limit(4)
    @replies = ApplicationEmail.answers.includes(:job_application).where(received_at: 14.days.ago..).latest_first.limit(6)
    @last_fetch_at = SourceRun.where.not(source: GMAIL_SOURCES).maximum(:created_at)
    @last_gmail_at = SourceRun.where(source: GMAIL_SOURCES).maximum(:created_at)
  end
end
