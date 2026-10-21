require "rails_helper"

RSpec.describe "Settings and push subscriptions" do
  before { sign_in }

  it "shows and updates the notification settings" do
    create(:push_subscription, last_sent_at: Time.current)

    get settings_path
    expect(response.body).to include("Notificação de vagas novas", 'value="40"', "data-push-public-key-value", "Chrome · desde")

    patch settings_path, params: { setting: { notify_min_score: 55, notifications_enabled: "0", auto_dismiss_restricted: "0", auto_dismiss_below_score: "25" } }
    expect(response).to redirect_to(settings_path)
    expect(Setting.current).to have_attributes(notify_min_score: 55, notifications_enabled: false, auto_dismiss_restricted: false, auto_dismiss_below_score: 25)

    patch settings_path, params: { setting: { notify_min_score: 150 } }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "shows the version and offers the update when there is one" do
    stub_request(:get, AppVersion::RELEASES_URL).to_return(body: { tag_name: "v99.0.0" }.to_json)

    get settings_path

    expect(response.body).to include("WorkMachine #{AppVersion.current}", "Versão nova disponível: <strong>99.0.0</strong>", "docker compose pull")
  end

  it "turns aggregator sources off and on" do
    get settings_path
    expect(response.body).to include("Fontes automáticas", 'id="source_gorails"')

    patch settings_path, params: { setting: { enabled_sources: [ "", *Sources.all.map(&:key) - %w[remote_ok hacker_news] ] } }

    expect(Setting.current.disabled_sources).to contain_exactly("remote_ok", "hacker_news")
  end

  it "shows the backups and runs one on demand" do
    dir = Pathname(Dir.mktmpdir)
    allow(DatabaseBackup).to receive(:dir).and_return(dir)

    get settings_path
    expect(response.body).to include("Backup do banco", "Nenhum backup ainda")

    post backup_settings_path
    expect(response).to redirect_to(settings_path)
    expect(flash[:notice]).to start_with("Backup feito: workmachine-")

    get settings_path
    expect(response.body).to include("1 cópia guardadas")

    allow(DatabaseBackup).to receive(:call).and_raise(Errno::EACCES, "/rails/backups")
    post backup_settings_path
    expect(flash[:alert]).to include("O backup falhou")
  ensure
    FileUtils.rm_rf(dir)
  end

  it "subscribes, updates and unsubscribes a browser" do
    body = { endpoint: "https://fcm.googleapis.com/fcm/send/xyz", keys: { p256dh: "key1", auth: "auth1" } }

    post push_subscriptions_path, params: body, as: :json
    post push_subscriptions_path, params: body.merge(keys: { p256dh: "key2", auth: "auth2" }), as: :json

    expect(PushSubscription.sole).to have_attributes(p256dh: "key2", auth: "auth2")

    delete unsubscribe_push_subscriptions_path, params: { endpoint: body[:endpoint] }, as: :json
    expect(PushSubscription.count).to eq(0)
  end

  it "removes a browser from the settings page" do
    subscription = create(:push_subscription)

    delete push_subscription_path(subscription)

    expect(response).to redirect_to(settings_path)
    expect(PushSubscription.count).to eq(0)
  end

  it "sends a test notification" do
    create(:push_subscription)
    allow(WebPush).to receive(:payload_send)

    post test_push_subscriptions_path, as: :json

    expect(response.parsed_body).to eq("ok" => true, "delivered" => 1)
    expect(WebPush).to have_received(:payload_send).with(hash_including(vapid: hash_including(subject: Setting::VAPID_SUBJECT)))
  end
end
