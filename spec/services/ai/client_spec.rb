require "rails_helper"

RSpec.describe Ai::Client do
  around do |example|
    ENV["OPENROUTER_API_KEY"] = "sk-or-test"
    example.run
  ensure
    ENV.delete("OPENROUTER_API_KEY")
    ENV.delete("OPENROUTER_MODEL")
  end

  let(:posting) { create(:job_posting, title: "Rails Engineer") }
  let(:response_body) do
    {
      id: "gen-1", model: "deepseek/deepseek-v4-pro-0813",
      choices: [ { finish_reason: "stop", native_finish_reason: "end_turn", message: { role: "assistant", content: " Aderência: 8/10 " } } ],
      usage: { prompt_tokens: 1920, completion_tokens: 300, cost: 0.0082, prompt_tokens_details: { cached_tokens: 0, cache_write_tokens: 1800 } }
    }
  end

  def stub_openrouter(status: 200, body: response_body)
    stub_request(:post, Ai::Client::URL).to_return(status:, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  it "calls DeepSeek V4 Pro on OpenRouter with the profile and medium reasoning" do
    stub = stub_openrouter

    result = described_class.new.generate("fit_analysis", posting)

    expect(stub.with(headers: { "Authorization" => "Bearer sk-or-test", "X-Title" => "WorkMachine" }) { |request|
      body = JSON.parse(request.body)
      body["model"] == "deepseek/deepseek-v4-pro-0813" && body.dig("reasoning", "effort") == "medium" &&
        body.dig("messages", 0, "content").include?("<profile>") &&
        body.dig("messages", 1, "content").include?("Title: Rails Engineer") && body.dig("usage", "include") == true
    }).to have_been_requested
    expect(result).to have_attributes(text: "Aderência: 8/10", model: "deepseek/deepseek-v4-pro-0813", input_tokens: 1920,
                                      output_tokens: 300, cache_write_tokens: 1800, cache_read_tokens: 0, cost: 0.0082)
    expect(result).not_to be_refused
  end

  it "uses another model when configured, with an explicit cache breakpoint for Claude" do
    ENV["OPENROUTER_MODEL"] = "anthropic/claude-sonnet-5.5"
    stub = stub_openrouter

    described_class.new.generate("cv_summary", posting)

    expect(stub.with { |request|
      body = JSON.parse(request.body)
      body["model"] == "anthropic/claude-sonnet-5.5" && body.dig("messages", 0, "content", 0, "cache_control", "type") == "ephemeral"
    }).to have_been_requested
  end

  it "flags refusals and truncated answers" do
    refused = response_body.deep_merge(choices: [ { finish_reason: "stop", native_finish_reason: "refusal", message: { content: "" } } ])
    stub_openrouter(body: refused)
    expect(described_class.new.generate("message", posting)).to be_refused

    cut = response_body.deep_merge(choices: [ { finish_reason: "length", message: { content: "Oi" } } ])
    stub_openrouter(body: cut)
    expect(described_class.new.generate("message", posting)).to be_truncated
  end

  it "raises with the HTTP status and OpenRouter's message" do
    stub_openrouter(status: 402, body: { error: { code: 402, message: "Insufficient credits" } })

    expect { described_class.new.generate("fit_analysis", posting) }
      .to raise_error(Ai::Client::Error, "Insufficient credits") { expect(it.status).to eq(402) }
  end

  it "raises on an error inside a 200 response and on non-JSON errors" do
    stub_openrouter(body: { error: { code: 502, message: "Provider returned error" } })
    expect { described_class.new.generate("fit_analysis", posting) }.to raise_error(Ai::Client::Error) { expect(it.status).to eq(502) }

    stub_request(:post, Ai::Client::URL).to_return(status: 500, body: "<html>")
    expect { described_class.new.generate("fit_analysis", posting) }.to raise_error(Ai::Client::Error, /respondeu 500/)
  end

  it "knows when the key is configured and builds the text for the estimate" do
    expect(described_class).to be_configured
    expect(described_class.request_text("cv_summary", posting)).to include("<profile>", "Title: Rails Engineer")

    ENV["OPENROUTER_API_KEY"] = ""
    expect(described_class).not_to be_configured
  end
end
