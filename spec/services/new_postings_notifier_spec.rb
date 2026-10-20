require "rails_helper"

RSpec.describe NewPostingsNotifier do
  let(:since) { 1.minute.ago }
  let!(:subscription) { create(:push_subscription) }

  let(:sent_messages) { [] }

  before { allow(WebPush).to receive(:payload_send) { |**args| sent_messages << JSON.parse(args[:message]) } }

  it "notifies one new posting at or above the minimum score, once" do
    posting = create(:job_posting, title: "Rails Developer", company: "Acme", score: 72, remote_scope: "brazil")
    create(:job_posting, score: 39)

    expect(described_class.call(since:)).to eq(1)
    expect(sent_messages.first).to include("title" => "Vaga nova com nota 72", "body" => "Rails Developer · Acme (Brasil)", "path" => "/vagas/#{posting.id}")
    expect(posting.reload.notified_at).to be_present
    expect(subscription.reload.last_sent_at).to be_present

    expect(described_class.call(since:)).to eq(0)
  end

  it "groups several postings in one notification with the top ones" do
    5.times { |i| create(:job_posting, title: "Vaga #{i}", score: 50 + i) }

    described_class.call(since:)

    message = sent_messages.sole
    expect(message["title"]).to eq("5 vagas novas com nota 40+")
    expect(message["body"].lines.first).to start_with("54 · Vaga 4")
    expect(message["body"]).to include("e mais 2")
    expect(message["path"]).to eq("/vagas?min_score=40")
  end

  it "respects the configured score, the switch and the time window" do
    Setting.current.update!(notify_min_score: 80)
    create(:job_posting, score: 70)
    create(:job_posting, score: 90, created_at: 2.hours.ago)
    expect(described_class.call(since:)).to eq(0)

    Setting.current.update!(notifications_enabled: false, notify_min_score: 10)
    expect(described_class.call(since:)).to eq(0)
    expect(WebPush).not_to have_received(:payload_send)
  end

  it "forgets expired browsers and survives push errors" do
    other = create(:push_subscription)
    response = instance_double(Net::HTTPResponse, body: "gone")
    allow(WebPush).to receive(:payload_send).with(hash_including(endpoint: subscription.endpoint))
      .and_raise(WebPush::ExpiredSubscription.new(response, "fcm.googleapis.com"))
    allow(WebPush).to receive(:payload_send).with(hash_including(endpoint: other.endpoint)).and_raise(SocketError)

    expect(PushSender.deliver_all(title: "t", body: "b", path: "/", tag: "x")).to eq(0)
    expect(PushSubscription.exists?(subscription.id)).to be(false)
    expect(other.reload).to be_present
  end
end
