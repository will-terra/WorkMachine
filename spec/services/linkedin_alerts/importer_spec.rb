require "rails_helper"

RSpec.describe LinkedinAlerts::Importer do
  let(:alert) { fixture_text("emails/linkedin_job_alert.eml") }
  let(:imap) { instance_double(Net::IMAP, login: true, examine: true, logout: true, disconnect: true, disconnected?: false) }
  let(:importer) { described_class.new(imap_factory: -> { imap }) }

  around do |example|
    old = ENV.to_h.slice("GMAIL_USER", "GMAIL_APP_PASSWORD")
    ENV["GMAIL_USER"] = "ana@example.com"
    ENV["GMAIL_APP_PASSWORD"] = "abcd efgh ijkl mnop"
    example.run
  ensure
    ENV.delete("GMAIL_USER")
    ENV.delete("GMAIL_APP_PASSWORD")
    ENV.update(old)
  end

  def fetch_data(*bodies)
    bodies.map { instance_double(Net::IMAP::FetchData, attr: { "BODY[]" => it }) }
  end

  it "imports the jobs read-only and remembers the Message-ID" do
    allow(imap).to receive(:uid_search).and_return([ 11 ])
    allow(imap).to receive(:uid_fetch).with([ 11 ], "BODY.PEEK[]").and_return(fetch_data(alert))

    travel_to Time.zone.local(2026, 10, 20, 9) do
      result = importer.call

      expect(result).to have_attributes(emails: 1, postings: 3, created: 3)
    end

    expect(imap).to have_received(:login).with("ana@example.com", "abcdefghijklmnop")
    expect(imap).to have_received(:examine).with("INBOX")
    expect(imap).to have_received(:uid_search).with([ "SINCE", "06-Oct-2026", "OR", "FROM", "jobalerts-noreply@linkedin.com", "FROM", "jobs-noreply@linkedin.com" ])
    expect(JobPosting.find_by!(url: "https://www.linkedin.com/jobs/view/4012345678")).to have_attributes(source: "linkedin_alert", company: "Acme Tecnologia", remote_scope: "brazil", seniority: "mid")
    expect(ProcessedEmail.last).to have_attributes(postings_count: 3, message_id: "1234567890.111.JavaMail.app@lor1-app12345.prod.linkedin.com")
  end

  it "skips e-mails already processed and searches since the last one" do
    ProcessedEmail.create!(message_id: "1234567890.111.JavaMail.app@lor1-app12345.prod.linkedin.com", received_at: Time.zone.local(2026, 10, 19, 7))
    allow(imap).to receive(:uid_search).and_return([ 11 ])
    allow(imap).to receive(:uid_fetch).and_return(fetch_data(alert))

    with_env("LINKEDIN_ALERT_SENDERS" => "jobalerts-noreply@linkedin.com") do
      expect(importer.call).to have_attributes(emails: 0, created: 0)
    end

    expect(imap).to have_received(:uid_search).with([ "SINCE", "18-Oct-2026", "FROM", "jobalerts-noreply@linkedin.com" ])
    expect(JobPosting.count).to eq(0)
  end

  it "uses another mailbox when configured and copes with nothing found" do
    allow(imap).to receive(:uid_search).and_return([])

    with_env("GMAIL_MAILBOX" => "[Gmail]/Todos os e-mails") { importer.call }

    expect(imap).to have_received(:examine).with("[Gmail]/Todos os e-mails")
    expect(imap).to have_received(:logout)
  end

  it "explains when Google wants an app password instead of the account password" do
    allow(imap).to receive(:login).and_raise(Net::IMAP::NoResponseError.new(imap_response("Application-specific password required: https://support.google.com/accounts/answer/185833 (Failure)")))

    expect { importer.call }.to raise_error(LinkedinAlerts::Importer::LoginError, /senha de app.*16 letras/)
  end

  it "explains other login failures and always disconnects" do
    allow(imap).to receive(:login).and_raise(Net::IMAP::NoResponseError.new(imap_response("[AUTHENTICATIONFAILED] Invalid credentials (Failure)")))
    allow(imap).to receive(:logout).and_raise(IOError)

    expect { importer.call }.to raise_error(LinkedinAlerts::Importer::LoginError, /Invalid credentials.*senha de app em Ajustes/)
    expect(imap).to have_received(:disconnect)
  end

  def imap_response(text)
    Net::IMAP::TaggedResponse.new("RUBY0001", "NO", Net::IMAP::ResponseText.new(nil, text), "")
  end

  it "knows when Gmail is configured" do
    expect(described_class).to be_configured
    with_env("GMAIL_APP_PASSWORD" => "") { expect(described_class).not_to be_configured }
  end

  def with_env(values)
    old = values.keys.index_with { ENV[it] }
    values.each { |key, value| ENV[key] = value }
    yield
  ensure
    old.each { |key, value| ENV[key] = value }
  end
end
