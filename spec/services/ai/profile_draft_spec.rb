require "rails_helper"

RSpec.describe Ai::ProfileDraft do
  let(:reply) do
    {
      name: "Ana Souza", headline: "Full Stack Engineer", primary_area: "fullstack", plan_b_area: "cooking", seniority: "mid",
      years_experience: "3", target_titles: [ "Desenvolvedora Full Stack", "" ], search_terms: [ "rails", "Rails" ],
      skills: [ { name: "Rails", level: "essential", synonyms: [ "Ruby on Rails" ] }, { name: "Go", level: "guru" }, "junk" ],
      ai_profile: "# Ana Souza", phone: "+55 11 99999-0000"
    }.to_json
  end
  let(:result) { Ai::Client::Result.new(text: reply, model: "m", finish_reason: "stop", input_tokens: 1, output_tokens: 1, cache_read_tokens: nil, cache_write_tokens: nil, cost: 0.001) }
  let(:client) { instance_double(Ai::Client, complete: result) }

  it "turns the model's JSON into clean profile attributes" do
    attributes, = described_class.new(client:).call("CV da Ana")

    expect(attributes).to eq(
      "name" => "Ana Souza", "headline" => "Full Stack Engineer", "ai_profile" => "# Ana Souza", "primary_area" => "fullstack",
      "seniority" => "mid", "years_experience" => 3, "target_titles" => [ "Desenvolvedora Full Stack" ], "search_terms" => [ "rails" ],
      "skills" => [ { "name" => "Rails", "level" => "essential", "synonyms" => [ "Ruby on Rails" ] }, { "name" => "Go", "level" => "important", "synonyms" => [] } ]
    )
    expect(client).to have_received(:complete).with(hash_including(json: true, user: "<cv>\nCV da Ana\n</cv>"))
  end

  it "lists the areas in the prompt and estimates the cost" do
    expect(described_class.system_text).to include('"backend"', '"product"')
    expect(described_class.estimate("x" * 3500, { cache_write: 1.0, output: 2.0 })).to be_within(0.0001).of((Ai::Pricing.estimate_tokens("#{described_class.system_text}\n#{"x" * 3500}") + 8_000) / 1_000_000.0)
  end

  it "returns an empty draft when the answer is not JSON" do
    allow(client).to receive(:complete).and_return(result.with(text: "Desculpe"))

    expect(described_class.new(client:).call("CV").first).to eq({})
  end
end
