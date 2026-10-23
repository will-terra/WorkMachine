require "rails_helper"

RSpec.describe InterviewReminderJob do
  let(:sent) { [] }
  let!(:application) { create(:job_application, company: "Nimbus Labs", role: "Rails Engineer", status: "tech_interview", interview_at: Time.zone.local(2026, 10, 23, 14, 30)) }

  before do
    create(:push_subscription)
    allow(WebPush).to receive(:payload_send) { |**args| sent << JSON.parse(args[:message]) }
  end

  it "reminds once, from 6 p.m. the day before, opening the preparation" do
    travel_to(Time.zone.local(2026, 10, 22, 17, 5)) { described_class.perform_now }
    expect(sent).to be_empty

    travel_to(Time.zone.local(2026, 10, 22, 18, 5)) { 2.times { described_class.perform_now } }

    expect(sent.sole).to include("title" => "Entrevista amanhã: Nimbus Labs", "body" => "14:30 · Rails Engineer. A preparação está no app.",
                                 "path" => "/candidaturas/#{application.id}/edit#entrevista")
  end

  it "says today when the interview was set for the same day, and reminds again for a new date" do
    travel_to(Time.zone.local(2026, 10, 23, 9)) { described_class.perform_now }
    expect(sent.last["title"]).to eq("Entrevista hoje: Nimbus Labs")

    application.update!(interview_at: Time.zone.local(2026, 10, 27, 10))
    travel_to(Time.zone.local(2026, 10, 26, 20)) { described_class.perform_now }
    expect(sent.size).to eq(2)
  end

  it "skips past interviews and closed applications, and stays quiet when turned off" do
    create(:job_application, status: "rejected", interview_at: Time.zone.local(2026, 10, 23, 10))
    create(:job_application, status: "hr_interview", interview_at: Time.zone.local(2026, 10, 21, 10))
    Setting.current.update!(notify_interviews: false)

    travel_to(Time.zone.local(2026, 10, 22, 19)) { described_class.perform_now }

    expect(sent).to be_empty
    expect(application.reload.interview_reminded_at).to be_present
  end
end
