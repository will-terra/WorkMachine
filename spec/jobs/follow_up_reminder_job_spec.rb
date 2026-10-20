require "rails_helper"

RSpec.describe FollowUpReminderJob do
  it "sets today's follow-up on applications waiting more than 5 days" do
    old = create(:job_application, status: "applied", applied_on: 6.days.ago.to_date)
    recent = create(:job_application, status: "applied", applied_on: 2.days.ago.to_date)
    scheduled = create(:job_application, status: "applied", applied_on: 10.days.ago.to_date, next_follow_up_on: 3.days.from_now.to_date)

    described_class.perform_now

    expect(old.reload.next_follow_up_on).to eq(Date.current)
    expect(recent.reload.next_follow_up_on).to be_nil
    expect(scheduled.reload.next_follow_up_on).to eq(3.days.from_now.to_date)
  end

  it "is scheduled in config/recurring.yml" do
    tasks = YAML.load(Rails.root.join("config/recurring.yml").read, aliases: true).fetch("production")

    expect(tasks.dig("fetch_jobs", "schedule")).to eq("every 3 hours")
    expect(tasks.dig("follow_up_reminder", "schedule")).to eq("every day at 8am America/Sao_Paulo")
  end
end
