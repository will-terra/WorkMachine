require "rails_helper"

RSpec.describe "AI artifacts" do
  before { sign_in }

  let(:posting) { create(:job_posting) }

  context "with the API key configured" do
    before { allow(Ai::Client).to receive(:configured?).and_return(true) }

    it "creates a pending artifact and enqueues the generation" do
      expect {
        post job_posting_ai_artifacts_path(posting), params: { kind: "message", language: "en" }
      }.to have_enqueued_job(GenerateAiArtifactJob)

      expect(posting.ai_artifacts.last).to have_attributes(kind: "message", language: "en", status: "pending")
      expect(response).to redirect_to(job_posting_path(posting, anchor: "ia"))
    end

    it "rejects unknown kinds" do
      post job_posting_ai_artifacts_path(posting), params: { kind: "poem" }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "shows the buttons, the results and a polling frame for pending ones" do
      create(:ai_artifact, job_posting: posting, content: "Aderência: 9/10", cost_usd: 0.0123)
      pending = create(:ai_artifact, job_posting: posting, status: "pending", content: nil)

      get job_posting_path(posting)

      expect(response.body).to include("Analisar fit", "Aderência: 9/10", "US$ 0,0123", %(data-poll-url-value="/ia/#{pending.id}"), 'data-controller="poll"')
    end

    it "estimates the cost per click from the prompt size and OpenRouter prices" do
      allow(Ai::Pricing).to receive(:for).and_return(Ai::Pricing::FALLBACK)

      get estimate_job_posting_ai_artifacts_path(posting)

      expect(response.body).to match(/análise de fit ≈ US\$ 0,0\d\d/)
      expect(response.body).to include("turbo-frame")
    end
  end

  it "asks for the key when it is missing" do
    allow(Ai::Client).to receive(:configured?).and_return(false)

    expect { post job_posting_ai_artifacts_path(posting), params: { kind: "fit_analysis" } }.not_to change(AiArtifact, :count)
    expect(flash[:alert]).to include("OPENROUTER_API_KEY")

    get job_posting_path(posting)
    expect(response.body).to include("coloque sua chave")

    get estimate_job_posting_ai_artifacts_path(posting)
    expect(response.body).not_to include("Custo estimado")
  end

  it "renders one artifact for polling and deletes it" do
    artifact = create(:ai_artifact, job_posting: posting, status: "failed", error_message: "A IA recusou o pedido")

    get ai_artifact_path(artifact)
    expect(response.body).to include("A IA recusou o pedido", %(id="ai_artifact_#{artifact.id}"))

    expect { delete ai_artifact_path(artifact) }.to change(AiArtifact, :count).by(-1)
    expect(response).to redirect_to(job_posting_path(posting, anchor: "ia"))
  end
end
