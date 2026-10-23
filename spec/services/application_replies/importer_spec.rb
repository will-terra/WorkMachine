require "rails_helper"

RSpec.describe ApplicationReplies::Importer do
  let(:imap) { instance_double(Net::IMAP, login: true, examine: true, logout: true, disconnect: true, disconnected?: false) }
  let(:classifier) { instance_double(ApplicationReplies::Classifier) }
  let(:importer) { described_class.new(imap_factory: -> { imap }, classifier:) }
  let!(:acme) { create(:job_application, company: "Acme", role: "Rails Dev", status: "applied", applied_on: Date.new(2026, 10, 1), next_follow_up_on: Date.current) }

  around do |example|
    ENV["GMAIL_USER"] = "ana@gmail.com"
    ENV["GMAIL_APP_PASSWORD"] = "abcdabcdabcdabcd"
    example.run
  ensure
    ENV.delete("GMAIL_USER")
    ENV.delete("GMAIL_APP_PASSWORD")
  end

  def envelope(uid, subject:, name:, address:, id: "msg-#{uid}@mail")
    mailbox, host = address.split("@")
    Net::IMAP::FetchData.new(uid, { "UID" => uid, "ENVELOPE" => Net::IMAP::Envelope.new(
      "Mon, 19 Oct 2026 10:00:00 -0300", subject, [ Net::IMAP::Address.new(name, nil, mailbox, host) ], nil, nil, nil, nil, nil, nil, "<#{id}>"
    ) })
  end

  def body(uid, text)
    [ Net::IMAP::FetchData.new(uid, { "BODY[]" => Mail.new { |m| m.from = "jobs@acme.com"; m.subject = "x"; m.body = text }.to_s }) ]
  end

  def answer(category, summary = "Resumo", interview_type = "hr")
    ApplicationReplies::Classifier::Result.new(category:, summary:, interview_type:, classified_by: "ai")
  end

  before do
    allow(imap).to receive(:uid_search).and_return([ 1, 2, 3 ])
    allow(imap).to receive(:uid_fetch).with([ 1, 2, 3 ], %w[UID ENVELOPE]).and_return([
      envelope(1, subject: "Acme · Next steps", name: "Acme Recruiting", address: "jobs@acme.com"),
      envelope(2, subject: "Newsletter", name: "Outra Empresa", address: "news@outra.com"),
      envelope(3, subject: "Acme alert", name: "LinkedIn", address: "jobalerts-noreply@linkedin.com")
    ])
    allow(imap).to receive(:uid_fetch).with(1, "BODY.PEEK[]").and_return(body(1, "Gostaríamos de agendar uma entrevista"))
    allow(WebPush).to receive(:payload_send)
    create(:push_subscription)
  end

  it "reads only the e-mails that mention an applied company, moves the card and notifies" do
    allow(classifier).to receive(:call).and_return(answer("interview", "Convite para entrevista com o RH."))

    travel_to Time.zone.local(2026, 10, 20, 12) do
      expect(importer.call).to have_attributes(matched: 1, moved: 1)
    end

    expect(imap).to have_received(:uid_search).with([ "SINCE", "20-Sep-2026" ])
    expect(classifier).to have_received(:call).once.with(hash_including(application: acme, subject: "Acme · Next steps", body: include("agendar uma entrevista")))
    expect(acme.reload).to have_attributes(status: "hr_interview", responded_on: Date.new(2026, 10, 19), next_follow_up_on: nil)
    expect(ApplicationEmail.sole).to have_attributes(category: "interview", status_before: "applied", status_after: "hr_interview", from_name: "Acme Recruiting")
    expect(WebPush).to have_received(:payload_send).with(hash_including(message: include("Acme: convite para entrevista")))
    expect(Setting.current.replies_checked_at).to eq(Time.zone.local(2026, 10, 20, 12))
  end

  it "keeps the interview date the e-mail sets" do
    interview_at = Time.zone.local(2026, 10, 23, 14)
    allow(classifier).to receive(:call).and_return(
      ApplicationReplies::Classifier::Result.new(category: "interview", summary: "Entrevista técnica marcada.", interview_type: "technical",
                                                 classified_by: "ai", interview_at:)
    )

    travel_to(Time.zone.local(2026, 10, 20, 12)) { importer.call }

    expect(acme.reload).to have_attributes(status: "tech_interview", interview_at:)
  end

  it "never reads the same e-mail twice and searches since the last check" do
    allow(classifier).to receive(:call).and_return(answer("confirmation"))
    importer.call
    Setting.current.update!(replies_checked_at: Time.zone.local(2026, 10, 18, 9))

    importer.call

    expect(classifier).to have_received(:call).once
    expect(imap).to have_received(:uid_search).with([ "SINCE", "17-Oct-2026" ])
    expect(acme.reload.status).to eq("applied")
    expect(WebPush).not_to have_received(:payload_send)
  end

  it "rejects from any stage, does not move backwards and ignores unrelated e-mails" do
    acme.update!(status: "tech_interview")
    allow(classifier).to receive(:call).and_return(answer("recruiter_contact"))
    expect(importer.call).to have_attributes(matched: 1, moved: 0)
    expect(acme.reload.status).to eq("tech_interview")

    ApplicationEmail.delete_all
    allow(classifier).to receive(:call).and_return(answer("rejection", "Seguiram com outra pessoa."))
    expect(importer.call.moved).to eq(1)
    expect(acme.reload.status).to eq("rejected")

    ApplicationEmail.delete_all
    acme.update!(status: "applied")
    allow(classifier).to receive(:call).and_return(answer("unrelated", ""))
    expect(importer.call).to have_attributes(matched: 0, moved: 0)
    expect(ApplicationEmail.sole.category).to eq("unrelated")
  end

  it "maps AI and technical interviews, tests and offers" do
    { [ "interview", "ai" ] => "ai_interview", [ "interview", "technical" ] => "tech_interview", [ "assessment", "hr" ] => "take_home", [ "offer", "hr" ] => "offer" }.each do |(category, type), status|
      ApplicationEmail.delete_all
      acme.update!(status: "applied")
      allow(classifier).to receive(:call).and_return(answer(category, "x", type))

      importer.call

      expect(acme.reload.status).to eq(status)
    end
  end

  it "runs every hour when Gmail is configured and the option is on" do
    allow(described_class).to receive(:new).and_return(instance_double(described_class, call: described_class::Result.new(matched: 2, moved: 1)))

    ImportApplicationRepliesJob.perform_now
    expect(SourceRun.last).to have_attributes(source: "application_replies", status: "succeeded", fetched_count: 2, created_count: 1)

    Setting.current.update!(track_replies: false)
    expect { ImportApplicationRepliesJob.perform_now }.not_to change(SourceRun, :count)

    Setting.current.update!(track_replies: true)
    allow(described_class).to receive(:new).and_raise(GmailSession::LoginError, "senha")
    ImportApplicationRepliesJob.perform_now
    expect(SourceRun.last).to have_attributes(status: "failed", error_message: include("senha"))
  end
end
