require "rails_helper"

RSpec.describe AppVersion do
  it "reads the installed version from VERSION or from the image" do
    expect(described_class.current).to eq(Rails.root.join("VERSION").read.strip)

    ENV["APP_VERSION"] = "v9.1.0"
    expect(described_class.current).to eq("9.1.0")
  ensure
    ENV.delete("APP_VERSION")
  end

  it "tells when GitHub has a newer release" do
    stub_request(:get, described_class::RELEASES_URL).to_return(body: { tag_name: "v99.0.0" }.to_json)
    expect(described_class.update_available?).to be(true)

    stub_request(:get, described_class::RELEASES_URL).to_return(body: { tag_name: "v0.1.0" }.to_json)
    expect(described_class.update_available?).to be(false)
  end

  it "stays quiet without a release or without network" do
    expect(described_class.update_available?).to be_falsey

    stub_request(:get, described_class::RELEASES_URL).to_raise(SocketError)
    expect(described_class.latest).to be_nil
  end
end
