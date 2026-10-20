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

  describe "morning notification" do
    let!(:template) { create(:message_template, name: "Follow-up de candidatura (PT)", language: "pt") }
    let(:sent) { [] }

    before do
      create(:push_subscription)
      allow(WebPush).to receive(:payload_send) { |**args| sent << JSON.parse(args[:message]) }
    end

    it "lists the follow-ups due and opens the filled-in message when there is one" do
      application = create(:job_application, company: "Acme", status: "applied", applied_on: 6.days.ago.to_date)

      described_class.perform_now

      expect(sent.sole).to include("title" => "Follow-up hoje: Acme", "path" => "/mensagens?job_application_id=#{application.id}#message_template_#{template.id}")
      expect(sent.sole["body"]).to include("Sem resposta há 5+ dias: Acme")
    end

    it "groups several follow-ups and respects the setting" do
      %w[Acme Globex Initech Umbrella].each { create(:job_application, company: it, status: "applied", applied_on: 8.days.ago.to_date) }

      described_class.perform_now
      expect(sent.sole).to include("title" => "4 follow-ups para hoje", "path" => "/")
      expect(sent.sole["body"]).to include("e mais 1")

      Setting.current.update!(notify_follow_ups: false)
      described_class.perform_now
      expect(sent.size).to eq(1)
    end

    it "stays quiet when nothing is due" do
      described_class.perform_now

      expect(sent).to be_empty
    end
  end

  it "is scheduled in config/recurring.yml" do
    tasks = YAML.load(Rails.root.join("config/recurring.yml").read, aliases: true).fetch("production")

    expect(tasks.dig("fetch_jobs", "schedule")).to eq("every 3 hours")
    expect(tasks.dig("follow_up_reminder", "schedule")).to eq("every day at 8am America/Sao_Paulo")
  end
end
