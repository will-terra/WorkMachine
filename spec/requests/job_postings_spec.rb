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

    it "sorts by newest and keeps the filters in the page" do
      create(:job_posting, title: "Antiga e boa", score: 90, posted_at: 5.days.ago)
      create(:job_posting, title: "Nova e fraca", score: 10, posted_at: 1.hour.ago)

      get job_postings_path(sort: "recent", period: "7", keyword: "rails", salary: "1")
      expect(response.body).to include("mais novas primeiro", "Limpar filtros", 'selected="selected" value="recent"', "Com salário")

      get job_postings_path(sort: "recent")
      expect(response.body.index("Nova e fraca")).to be < response.body.index("Antiga e boa")
    end

    it "offers to dismiss everything with a confirmation" do
      create_list(:job_posting, 2)

      get job_postings_path
      expect(response.body).to include("Descartar todas (2)", "data-turbo-confirm=\"Descartar 2 vagas?")

      get job_postings_path(min_score: 40)
      expect(response.body).to include("Descartar as 2 desta lista")

      get job_postings_path(triage: "saved")
      expect(response.body).not_to include("Descartar todas")
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

  describe "POST /vagas/:id/apply" do
    it "saves the posting straight into the applied column" do
      posting = create(:job_posting, title: "Rails Engineer", company: "Curotec")
      create(:job_application, status: "applied")

      get job_posting_path(posting)
      expect(response.body).to include("Salvar em aplicadas", "Salvar em Candidaturas", "turbo:submit-end-&gt;close-tab#closeOnSuccess")

      post apply_job_posting_path(posting)

      expect(response).to redirect_to(job_posting_path(posting))
      expect(flash[:notice]).to eq("Curotec · Rails Engineer está em Candidaturas como aplicada.")
      expect(posting.reload).to be_triage_saved
      expect(posting.job_application).to have_attributes(status: "applied", applied_on: Date.current, position: 1)

      get job_posting_path(posting)
      expect(response.body).not_to include("Salvar em aplicadas")
    end

    it "moves an application that was only saved" do
      posting = create(:job_posting)
      post save_job_posting_path(posting)

      expect { post apply_job_posting_path(posting) }.not_to change(JobApplication, :count)
      expect(posting.job_application.reload).to have_attributes(status: "applied", applied_on: Date.current)
    end

    it "does not move an application that is further along" do
      posting = create(:job_posting)
      application = create(:job_application, job_posting: posting, status: "tech_interview")

      post apply_job_posting_path(posting)

      expect(application.reload.status).to eq("tech_interview")
      expect(flash[:notice]).to include("entrevista técnica")
    end
  end

  it "lists auto-dismissed postings, marks partial scores and restores clearing the reason" do
    auto = create(:job_posting, title: "Vaga dos EUA", triage: "dismissed", auto_dismissed_reason: "só EUA/Canadá")
    create(:job_posting, title: "Descartada à mão", triage: "dismissed")
    create(:job_posting, title: "Alerta sem texto", description: nil)

    get job_postings_path
    expect(response.body).to include("Alerta sem texto", "nota parcial")

    get job_postings_path(triage: "auto")
    expect(response.body).to include("Vaga dos EUA", "descartada automaticamente: só EUA/Canadá")
    expect(response.body).not_to include("Descartada à mão")

    get job_posting_path(auto)
    expect(response.body).to include("automaticamente: só EUA/Canadá")

    post restore_job_posting_path(auto)
    expect(auto.reload).to have_attributes(triage: "new", auto_dismissed_reason: nil)
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

  describe "POST /vagas/dismiss_all" do
    it "dismisses only the new postings that match the filters" do
      high = create(:job_posting, score: 80)
      low = create(:job_posting, score: 10)
      saved = create(:job_posting, score: 10, triage: "saved")

      post dismiss_all_job_postings_path, params: { min_score: 40, triage: "all" }

      expect(response).to redirect_to(job_postings_path(min_score: 40, triage: "new", sort: "score"))
      expect(flash[:notice]).to start_with("1 vaga descartada")
      expect([ high.reload.triage, low.reload.triage, saved.reload.triage ]).to eq(%w[dismissed new saved])
    end

    it "dismisses all new postings without filters" do
      create_list(:job_posting, 3)

      post dismiss_all_job_postings_path

      expect(flash[:notice]).to start_with("3 vagas descartadas")
      expect(JobPosting.triage_new.count).to eq(0)
    end
  end

  it "starts a fetch in the background" do
    expect { post fetch_job_postings_path }.to have_enqueued_job(FetchJobsJob)
  end

  it "also imports the LinkedIn alerts when Gmail is configured" do
    allow(LinkedinAlerts::Importer).to receive(:configured?).and_return(true)

    expect { post fetch_job_postings_path }.to have_enqueued_job(ImportLinkedinAlertsJob)
  end
end
