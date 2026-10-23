require "rails_helper"

RSpec.describe WeeklySummaryJob do
  let(:sent) { [] }

  before do
    create(:push_subscription)
    allow(WebPush).to receive(:payload_send) { |**args| sent << JSON.parse(args[:message]) }
    create(:job_application, status: "applied", applied_on: Date.new(2026, 10, 23))
  end

  it "sends once on Sunday from 6 p.m., opening Métricas" do
    travel_to(Time.zone.local(2026, 10, 25, 17, 20)) { described_class.perform_now }
    travel_to(Time.zone.local(2026, 10, 24, 19, 20)) { described_class.perform_now } # Saturday
    expect(sent).to be_empty

    travel_to(Time.zone.local(2026, 10, 25, 18, 20)) { described_class.perform_now }
    travel_to(Time.zone.local(2026, 10, 25, 21, 20)) { described_class.perform_now }

    expect(sent.sole).to include("title" => "Resumo da semana", "path" => "/metricas")
    expect(sent.sole["body"]).to start_with("1 candidatura · semana passada: 0").and include("Dica:")
  end

  it "stays quiet when turned off in Ajustes" do
    Setting.current.update!(notify_weekly_summary: false)

    travel_to(Time.zone.local(2026, 10, 25, 18, 20)) { described_class.perform_now }

    expect(sent).to be_empty
    expect(Setting.current.reload.weekly_summary_sent_on).to eq(Date.new(2026, 10, 25))
  end
end
