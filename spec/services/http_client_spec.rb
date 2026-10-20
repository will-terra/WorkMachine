require "rails_helper"

RSpec.describe HttpClient do
  it "sends a User-Agent and follows redirects" do
    stub_request(:get, "https://a.example.com/").to_return(status: 301, headers: { "Location" => "/b" })
    stub_request(:get, "https://a.example.com/b").with(headers: { "User-Agent" => HttpClient::USER_AGENT }).to_return(body: "olá")

    body = described_class.get("https://a.example.com/")

    expect(body).to eq("olá")
    expect(body.encoding).to eq(Encoding::UTF_8)
  end

  it "stops after too many redirects" do
    stub_request(:get, "https://loop.example.com/").to_return(status: 302, headers: { "Location" => "/" })

    expect { described_class.get("https://loop.example.com/") }.to raise_error(HttpClient::Error, /Redirecionamentos/)
  end

  it "raises on HTTP errors and invalid JSON" do
    stub_request(:get, "https://e.example.com/500").to_return(status: 500)
    stub_request(:get, "https://e.example.com/json").to_return(body: "<html>")

    expect { described_class.get("https://e.example.com/500") }.to raise_error(HttpClient::Error, /500/)
    expect { described_class.get_json("https://e.example.com/json") }.to raise_error(HttpClient::Error, /JSON inválido/)
  end
end
