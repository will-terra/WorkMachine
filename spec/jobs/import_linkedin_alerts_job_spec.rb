require "rails_helper"

RSpec.describe ImportLinkedinAlertsJob do
  it "does nothing without Gmail credentials" do
    allow(LinkedinAlerts::Importer).to receive(:configured?).and_return(false)

    expect { described_class.perform_now }.not_to change(SourceRun, :count)
  end

  it "records a successful run" do
    allow(LinkedinAlerts::Importer).to receive(:configured?).and_return(true)
    allow(LinkedinAlerts::Importer).to receive(:new).and_return(instance_double(LinkedinAlerts::Importer, call: LinkedinAlerts::Importer::Result.new(emails: 2, postings: 5, created: 4)))

    described_class.perform_now

    expect(SourceRun.last).to have_attributes(source: "linkedin_alert", status: "succeeded", fetched_count: 5, created_count: 4)
  end

  it "records a failure" do
    allow(LinkedinAlerts::Importer).to receive(:configured?).and_return(true)
    allow(LinkedinAlerts::Importer).to receive(:new).and_raise(SocketError, "sem rede")

    described_class.perform_now

    expect(SourceRun.last).to have_attributes(status: "failed", error_message: "SocketError: sem rede")
  end
end
