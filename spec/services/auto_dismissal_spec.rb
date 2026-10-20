require "rails_helper"

RSpec.describe AutoDismissal do
  def ingest(**attributes)
    JobIngestor.call({ source: "greenhouse", title: "Rails Engineer", company: "Acme #{SecureRandom.hex(3)}", url: "https://jobs.example.com/#{SecureRandom.hex(4)}",
                       description: "Ruby on Rails" }.merge(attributes)).posting
  end

  it "dismisses US-only, Europe-only and restricted-country postings on arrival" do
    expect(ingest(location_text: "Remote, United States")).to have_attributes(triage: "dismissed", auto_dismissed_reason: "só EUA/Canadá")
    expect(ingest(location_text: "Remote, Germany")).to have_attributes(triage: "dismissed", auto_dismissed_reason: "só Europa")
    expect(ingest(location_text: "Remote, India; Remote, Japan")).to have_attributes(triage: "dismissed", auto_dismissed_reason: "local restrito")
    expect(ingest(location_text: "Remote - LATAM")).to have_attributes(triage: "new", auto_dismissed_reason: nil)
  end

  it "dismisses below the minimum score only when configured" do
    expect(ingest(title: "Office Assistant", description: "Excel")).to be_triage_new

    Setting.current.update!(auto_dismiss_below_score: 25)
    expect(ingest(title: "Office Assistant", description: "Excel")).to have_attributes(triage: "dismissed", auto_dismissed_reason: "nota abaixo de 25")
  end

  it "can be turned off and never touches postings saved by hand" do
    expect(ingest(source: "extension", location_text: "Remote, United States")).to be_triage_new

    Setting.current.update!(auto_dismiss_restricted: false)
    expect(ingest(location_text: "Remote, United States")).to be_triage_new
  end

  it "does not notify auto-dismissed postings" do
    allow(WebPush).to receive(:payload_send)
    create(:push_subscription)
    since = 1.minute.ago

    ingest(location_text: "Remote, United States", description: "Ruby on Rails, React, Hotwire, Sidekiq")

    expect(NewPostingsNotifier.call(since:)).to eq(0)
  end
end
