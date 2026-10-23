require "rails_helper"

RSpec.describe "Interview preparation" do
  before { sign_in }

  let(:posting) { create(:job_posting, title: "Rails Engineer", company: "Nimbus Labs") }
  let!(:application) { create(:job_application, company: "Nimbus Labs", role: "Rails Engineer", status: "hr_interview", job_posting: posting) }

  it "offers the preparation on the application, the card, the posting and the Painel" do
    allow(Ai::Client).to receive(:configured?).and_return(true)
    application.update!(interview_at: 2.days.from_now.change(hour: 14, min: 30))

    get edit_job_application_path(application)
    expect(response.body).to include("Preparação de entrevista", "Entrevista marcada para", "Preparar entrevista", "Entrevista em")

    get job_applications_path(view: "board")
    expect(response.body).to include("entrevista #{I18n.l(application.interview_at, format: :day_month_hour)}", "edit#entrevista")

    get job_posting_path(posting)
    expect(response.body).to include("Preparar entrevista")

    get root_path
    expect(response.body).to include("Próximas entrevistas", "Nimbus Labs")
  end

  it "has no preparation for an application that is not at an interview stage" do
    application.update!(status: "applied")

    get edit_job_application_path(application)

    expect(response.body).not_to include("Preparação de entrevista")
  end

  it "asks for the key, then creates the preparation for the application in the interface language" do
    post job_application_ai_artifacts_path(application), params: { kind: "interview_prep" }
    expect(response).to redirect_to(edit_job_application_path(application, anchor: "entrevista"))
    expect(flash[:alert]).to be_present

    allow(Ai::Client).to receive(:configured?).and_return(true)
    expect {
      post job_application_ai_artifacts_path(application), params: { kind: "interview_prep", language: "en" }
    }.to have_enqueued_job(GenerateAiArtifactJob)

    expect(AiArtifact.last).to have_attributes(kind: "interview_prep", job_application: application, job_posting: posting, language: "pt")
    expect(response).to redirect_to(edit_job_application_path(application, anchor: "entrevista"))

    post job_application_ai_artifacts_path(application), params: { kind: "fit_analysis" }
    expect(response).to have_http_status(:unprocessable_content)
    post job_posting_ai_artifacts_path(posting), params: { kind: "interview_prep" }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "shows the sheet on the application only, and deletes it back to the application" do
    allow(Ai::Client).to receive(:configured?).and_return(true)
    prep = create(:ai_artifact, job_posting: posting, job_application: application, kind: "interview_prep", content: "Perguntas para fazer à empresa")

    get edit_job_application_path(application)
    expect(response.body).to include("Perguntas para fazer à empresa", "Preparar de novo")

    get job_posting_path(posting)
    expect(response.body).not_to include("Perguntas para fazer à empresa")

    delete ai_artifact_path(prep)
    expect(response).to redirect_to(edit_job_application_path(application, anchor: "entrevista"))
  end

  it "estimates the preparation's cost on the paid model" do
    allow(Ai::Client).to receive(:configured?).and_return(true)
    Setting.current.update!(ai_plan: "paid")
    allow(Ai::Pricing).to receive(:for).and_return(Ai::Pricing::FALLBACK)

    get estimate_job_application_ai_artifacts_path(application)

    expect(response.body).to match(/preparação de entrevista ≈ US\$ 0,0\d\d/)
  end

  it "saves the interview date from the form and the reminder setting" do
    patch job_application_path(application), params: { job_application: { interview_at: "2026-11-03T15:00" } }
    expect(application.reload.interview_at).to eq(Time.zone.local(2026, 11, 3, 15))

    patch settings_path, params: { setting: { notify_interviews: "0", notify_weekly_summary: "0" } }
    expect(Setting.current).to have_attributes(notify_interviews: false, notify_weekly_summary: false)
  end
end
