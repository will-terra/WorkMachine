require "rails_helper"

RSpec.describe ApplicationReplies::Classifier do
  let(:application) { build(:job_application, company: "Acme", role: "Rails Dev", applied_on: Date.new(2026, 10, 1)) }
  let(:client) { instance_double(Ai::Client) }

  def classify(subject:, body: "", configured: false)
    allow(Ai::Client).to receive(:configured?).and_return(configured)
    described_class.new(client:).call(application:, from: "Acme <jobs@acme.com>", subject:, body:)
  end

  def ai_answer(json)
    Ai::Client::Result.new(text: json, model: "deepseek", finish_reason: "stop", input_tokens: 1, output_tokens: 1,
                           cache_read_tokens: 0, cache_write_tokens: 0, cost: 0.0004)
  end

  it "uses the AI model when OpenRouter is configured" do
    allow(client).to receive(:complete).and_return(ai_answer('{"category":"interview","summary":"Convite para entrevista técnica.","interview_type":"technical"}'))

    result = classify(subject: "Próximos passos", configured: true)

    expect(result).to have_attributes(category: "interview", interview_type: "technical", summary: "Convite para entrevista técnica.", classified_by: "ai")
    expect(client).to have_received(:complete).with(hash_including(json: true, user: include("Rails Dev at Acme")))
  end

  it "falls back to the rules when the AI answer is invalid or fails" do
    allow(client).to receive(:complete).and_return(ai_answer("nada de json"))
    expect(classify(subject: "Infelizmente não seguiremos com sua candidatura", configured: true)).to have_attributes(category: "rejection", classified_by: "rules")

    allow(client).to receive(:complete).and_return(ai_answer('{"category":"weird"}'))
    expect(classify(subject: "Oi", configured: true).category).to eq("other")
  end

  it "classifies with keyword rules without the AI" do
    expect(classify(subject: "Update on your application", body: "Unfortunately we decided to move forward with other candidates").category).to eq("rejection")
    expect(classify(subject: "Desafio técnico da vaga").category).to eq("assessment")
    expect(classify(subject: "Recebemos sua candidatura").category).to eq("confirmation")
    expect(classify(subject: "Vamos agendar uma entrevista?").to_h).to include(category: "interview", interview_type: "hr")
    expect(classify(subject: "Job offer - Rails Dev").category).to eq("offer")
    expect(classify(subject: "Promoção de Black Friday").category).to eq("unrelated")
    expect(classify(subject: "Sobre a vaga").category).to eq("other")
  end
end
