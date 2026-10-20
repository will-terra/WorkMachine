require "rails_helper"

RSpec.describe Setting do
  it "creates the single row with the defaults" do
    setting = described_class.current

    expect(setting).to have_attributes(notifications_enabled: true, notify_min_score: 40)
    expect(described_class.current).to eq(setting)
  end

  it "generates the VAPID keys once" do
    setting = described_class.current
    keys = setting.vapid_keys!

    expect(keys).to include(subject: Setting::VAPID_SUBJECT, public_key: be_present, private_key: be_present)
    expect(setting.reload.vapid_keys!).to eq(keys)
  end

  it "validates the minimum score" do
    expect(described_class.new(notify_min_score: 101)).not_to be_valid
  end
end

RSpec.describe PushSubscription do
  it "names the browser" do
    expect(build(:push_subscription).browser_name).to eq("Chrome")
    expect(build(:push_subscription, user_agent: "Mozilla/5.0 Chrome/140.0 Edg/140.0").browser_name).to eq("Edge")
    expect(build(:push_subscription, user_agent: "Firefox/131.0").browser_name).to eq("Firefox")
    expect(build(:push_subscription, user_agent: "Version/18.0 Safari/605").browser_name).to eq("Safari")
    expect(build(:push_subscription, user_agent: nil).browser_name).to eq("Navegador")
  end
end
