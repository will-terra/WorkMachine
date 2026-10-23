require "rails_helper"

RSpec.describe "Tailored CV" do
  before do
    sign_in
    Profile.current.update!(name: "Ana Souza", cv_text: "Ruby on Rails developer.", skills: [ { "name" => "Ruby on Rails", "level" => "essential" } ])
  end

  let(:posting) { create(:job_posting, title: "Rails Engineer", company: "Nimbus Labs", description: "Ruby on Rails, PostgreSQL and Kubernetes.") }
  let(:cv) { "# Ana Souza\nBackend Engineer\n## Experience\n### Rails Engineer, Acme (2022 – 2025)\n- Ruby on Rails and PostgreSQL in production" }

  it "is asked from the posting's AI buttons" do
    allow(Ai::Client).to receive(:configured?).and_return(true)

    get job_posting_path(posting)
    expect(response.body).to include("CV adaptado (PDF)")

    expect { post job_posting_ai_artifacts_path(posting), params: { kind: "tailored_cv" } }.to have_enqueued_job(GenerateAiArtifactJob)
    expect(posting.ai_artifacts.last.kind).to eq("tailored_cv")
  end

  it "shows the keyword coverage against the original CV and opens a printable page" do
    artifact = create(:ai_artifact, job_posting: posting, kind: "tailored_cv", content: cv)

    get job_posting_path(posting)
    expect(response.body).to include("2 de 3 termos da vaga estão no CV adaptado", "no seu CV original: 1 de 3", "Kubernetes", "Abrir e baixar em PDF")

    get cv_ai_artifact_path(artifact)
    expect(response.body).to include("<title>CV Ana Souza - Nimbus Labs</title>", "<h1>Ana Souza</h1>", "<li>Ruby on Rails and PostgreSQL in production</li>",
                                     "Cobertura: 2 de 3 termos da vaga.", "Faltam: Kubernetes.", "window.print()", "@page")
    expect(response.body).not_to include("nav-scroll")
  end

  it "has no printable page for other results or unfinished ones" do
    fit = create(:ai_artifact, job_posting: posting, kind: "fit_analysis")
    pending = create(:ai_artifact, job_posting: posting, kind: "tailored_cv", status: "pending", content: nil)

    get cv_ai_artifact_path(fit)
    expect(response).to have_http_status(:not_found)
    get cv_ai_artifact_path(pending)
    expect(response).to have_http_status(:not_found)
  end
end
