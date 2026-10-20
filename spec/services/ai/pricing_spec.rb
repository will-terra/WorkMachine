require "rails_helper"

RSpec.describe Ai::Pricing do
  before { Rails.cache.clear }

  it "reads the model prices from OpenRouter's model list" do
    stub_request(:get, Ai::Pricing::MODELS_URL).to_return(body: {
      data: [
        { id: "anthropic/claude-sonnet-5.5", pricing: { prompt: "0.000002", completion: "0.00001", input_cache_read: "0.0000001", input_cache_write: "0.0000025" } },
        { id: "deepseek/deepseek-v4-pro-0813", pricing: { prompt: "0.00000066", completion: "0.00000198", input_cache_read: "0.000000022" } }
      ]
    }.to_json)

    expect(described_class.for("anthropic/claude-sonnet-5.5")).to eq(input: 2.0, output: 10.0, cache_write: 2.5, cache_read: 0.1)
    expect(described_class.for("deepseek/deepseek-v4-pro-0813")).to eq(input: 0.66, output: 1.98, cache_write: 0.66, cache_read: 0.022)
  end

  it "falls back to the known prices for unknown models or when offline" do
    stub_request(:get, Ai::Pricing::MODELS_URL).to_return(body: { data: [] }.to_json)
    expect(described_class.for("x/unknown")).to eq(Ai::Pricing::FALLBACK)

    stub_request(:get, Ai::Pricing::MODELS_URL).to_return(status: 503)
    expect(described_class.for("x/other")).to eq(Ai::Pricing::FALLBACK)
  end

  it "estimates tokens and an upper bound per click" do
    expect(described_class.estimate_tokens("a" * 350)).to eq(100)
    expect(described_class.estimate("fit_analysis", 3000, Ai::Pricing::FALLBACK)).to be_within(1e-9).of(0.00792)
  end
end
