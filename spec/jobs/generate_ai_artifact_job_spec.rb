require "rails_helper"

RSpec.describe GenerateAiArtifactJob do
  let(:artifact) { create(:ai_artifact, status: "pending", content: nil, kind: "cv_summary", language: "en") }
  let(:client) { instance_double(Ai::Client) }

  def result(finish_reason: "stop", text: "Full Stack Engineer with about 3 years...")
    Ai::Client::Result.new(text:, model: "deepseek/deepseek-v4-pro-0813", finish_reason:, input_tokens: 150, output_tokens: 400,
                           cache_read_tokens: 1800, cache_write_tokens: 0, cost: 0.00438)
  end

  it "saves the text, the tokens and the cost reported by OpenRouter" do
    allow(client).to receive(:generate).with("cv_summary", artifact.job_posting, language: "en").and_return(result)

    described_class.perform_now(artifact, client:)

    expect(artifact.reload).to have_attributes(status: "completed", content: "Full Stack Engineer with about 3 years...",
                                               model: "deepseek/deepseek-v4-pro-0813", input_tokens: 150, output_tokens: 400, cache_read_tokens: 1800)
    expect(artifact.cost_usd.to_f).to eq(0.00438)
  end

  it "prepares an interview from the application" do
    application = create(:job_application, status: "tech_interview")
    prep = create(:ai_artifact, job_posting: nil, job_application: application, kind: "interview_prep", status: "pending", content: nil, language: "pt")
    allow(client).to receive(:generate).with("interview_prep", nil, language: "pt", application:).and_return(result(text: "O que a vaga mais valoriza"))

    described_class.perform_now(prep, client:)

    expect(prep.reload).to have_attributes(status: "completed", content: "O que a vaga mais valoriza")
  end

  it "flags answers cut at max_tokens" do
    allow(client).to receive(:generate).and_return(result(finish_reason: "length"))

    described_class.perform_now(artifact, client:)

    expect(artifact.reload.content).to end_with("[resposta cortada no limite de tokens]")
  end

  it "records a refusal" do
    allow(client).to receive(:generate).and_return(result(finish_reason: "refusal", text: ""))

    described_class.perform_now(artifact, client:)

    expect(artifact.reload).to have_attributes(status: "failed", error_message: "A IA recusou o pedido.")
  end

  it "explains key, credit, rate-limit and other API errors" do
    { 401 => /chave do OpenRouter é inválida/, 402 => /Sem créditos/, 429 => /limite de uso/, 500 => /Erro do OpenRouter: boom/ }.each do |status, message|
      artifact.update!(status: "pending")
      allow(client).to receive(:generate).and_raise(Ai::Client::Error.new("boom", status:))

      described_class.perform_now(artifact, client:)

      expect(artifact.reload).to have_attributes(status: "failed", error_message: message)
    end
  end

  it "explains connection problems" do
    allow(client).to receive(:generate).and_raise(SocketError)

    described_class.perform_now(artifact, client:)

    expect(artifact.reload.error_message).to start_with("Sem conexão com o OpenRouter")
  end

  it "skips artifacts that are not pending" do
    artifact.update!(status: "completed")

    expect { described_class.perform_now(artifact, client:) }.not_to raise_error
  end
end
