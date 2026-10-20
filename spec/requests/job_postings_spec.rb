require "rails_helper"

RSpec.describe "Job postings (triage)" do
  before { sign_in }

  describe "GET /vagas" do
    it "lists new postings by score with the explanation" do
      create(:job_posting, title: "Rails Dev baixa", score: 20)
      create(:job_posting, title: "Rails Dev alta", score: 90, matched_keywords: [ { "term" => "rails", "points" => 30 } ])
      create(:job_posting, title: "Vaga jogada fora", triage: "dismissed")
      SourceRun.create!(source: "remotive", status: "failed", error_message: "HttpClient::Error: 503")

      get job_postings_path

      expect(response.body).to include("rails +30", "HttpClient::Error: 503")
      expect(response.body.index("Rails Dev alta")).to be < response.body.index("Rails Dev baixa")
      expect(response.body).not_to include("Vaga jogada fora")
    end

    it "filters by source, region, seniority, score and text" do
      create(:job_posting, title: "Alvo", source: "greenhouse", remote_scope: "latam", seniority: "mid", score: 70)
      create(:job_posting, title: "Outra", source: "greenhouse", remote_scope: "us_only", seniority: "mid", score: 70)

      get job_postings_path(source: "greenhouse", remote_scope: "latam", seniority: "mid", min_score: 60, q: "alv", triage: "all")

      expect(response.body).to include("Alvo")
      expect(response.body).not_to include("Outra")
    end

    it "paginates" do
      create_list(:job_posting, JobPostingsController::PER_PAGE + 1)

      get job_postings_path(page: 1)

      expect(response.body).to include("Página 2 de 2", "Anteriores")
    end
  end

  it "shows a posting with its score breakdown" do
    posting = create(:job_posting, description: "Linha 1\n\nLinha 2", matched_keywords: [ { "term" => "7+ anos", "points" => -15 } ])

    get job_posting_path(posting)

    expect(response.body).to include("Linha 2", "7+ anos", "-15")
  end

  it "saves a posting as an application" do
    posting = create(:job_posting, title: "Rails Engineer", company: "Acme")

    expect { post save_job_posting_path(posting), as: :turbo_stream }.to change(JobApplication, :count).by(1)

    expect(response.body).to include("Salva em Candidaturas")
    expect(posting.reload).to be_triage_saved
    expect(JobApplication.last).to have_attributes(company: "Acme", role: "Rails Engineer", status: "saved")

    expect { post save_job_posting_path(posting) }.not_to change(JobApplication, :count)
  end

  it "dismisses and restores a posting" do
    posting = create(:job_posting)

    post dismiss_job_posting_path(posting)
    expect(posting.reload).to be_triage_dismissed
    expect(response).to redirect_to(job_posting_path(posting))

    post restore_job_posting_path(posting), as: :turbo_stream
    expect(posting.reload).to be_triage_new
  end

  it "adds a posting by hand" do
    get new_job_posting_path
    expect(response).to have_http_status(:ok)

    post job_postings_path, params: { job_posting: { title: "Dev Rails Pleno", company: "Acme", url: "https://acme.com/vaga", description: "Ruby on Rails" } }

    posting = JobPosting.last
    expect(posting).to have_attributes(source: "manual", seniority: "mid", score: 40)
    expect(response).to redirect_to(job_posting_path(posting))

    post job_postings_path, params: { job_posting: { title: "Dev Rails Pleno", company: "Acme", url: "https://acme.com/vaga" } }
    expect(flash[:notice]).to eq("Essa vaga já estava salva.")

    post job_postings_path, params: { job_posting: { title: "", url: "" } }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "starts a fetch in the background" do
    expect { post fetch_job_postings_path }.to have_enqueued_job(FetchJobsJob)
  end
end
