require "rails_helper"

RSpec.describe "Profile" do
  before { sign_in }

  let(:profile) { Profile.current }

  it "shows the form with the area suggestions and the Radar searches" do
    get profile_path

    expect(response.body).to include("O que procura", "Skills", "Evitar", "Prévia das notas", "Buscas do Radar", "Texto para a IA", 'value="Rails"', "profile-form-areas-value")
    expect(response.body).to include("search_override_feed_contratando")
  end

  it "saves the profile and rescores the postings when the skills change" do
    expect {
      patch profile_path, params: { profile: {
        name: "Bia", primary_area: "data", seniority: "senior", years_experience: "6",
        target_titles: "Engenheira de Dados\nAnalista de Dados", regions: [ "", "brazil", "us" ], work_modes: [ "" ],
        skills: { "0" => { name: "Python", level: "essential", synonyms: "py" }, "1" => { name: "Rails", level: "extra", _destroy: "1" },
                  "1761091234567890" => { name: "" } },
        search_terms: "python, sql", avoid_terms: [ "", "PHP", "presencial" ], search_overrides: { feed_contratando: "  Python AND vaga ", feed_hiring: "" }
      } }
    }.to have_enqueued_job(RescorePostingsJob)

    expect(response).to redirect_to(profile_path)
    expect(flash[:notice]).to include("recalculadas")
    expect(profile.reload).to have_attributes(name: "Bia", primary_area: "data", seniority: "senior", years_experience: 6,
                                              target_titles: [ "Engenheira de Dados", "Analista de Dados" ], regions: %w[brazil us],
                                              work_modes: [], search_terms: %w[python sql], avoid_terms: %w[PHP presencial], search_overrides: { "feed_contratando" => "Python AND vaga" })
    expect(profile.skills).to eq([ { "name" => "Python", "level" => "essential", "synonyms" => [ "py" ] } ])
  end

  it "tells when the change brings LinkedIn alerts to turn on" do
    patch profile_path, params: { profile: { target_titles: "Engenheira de Plataforma" } }

    expect(flash[:notice]).to end_with("recalculadas. O Radar tem 1 alerta do LinkedIn novo para ativar.")
  end

  it "clears the skills and the terms to avoid when every chip is removed" do
    profile.update!(avoid_terms: [ "PHP" ])

    patch profile_path, params: { profile: { skills: { "-1" => { name: "" } }, avoid_terms: [ "" ] } }

    expect(profile.reload).to have_attributes(skills: [], avoid_terms: [])
  end

  it "does not keep a search equal to the suggestion" do
    patch profile_path, params: { profile: { search_overrides: { feed_contratando: 'Rails AND (vaga OR contratando OR "estamos contratando")' } } }

    expect(profile.reload.search_overrides).to eq({})
    expect(flash[:notice]).to eq("Perfil salvo.")
  end

  it "shows the errors" do
    patch profile_path, params: { profile: { seniority: "guru" } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Nível")
  end

  it "previews the new scores and searches without saving" do
    create(:job_posting, title: "Python Engineer", description: "Python and SQL", score: 10)

    patch preview_profile_path, params: { profile: { skills: { "0" => { name: "Python", level: "essential" } }, search_terms: "python" } }

    expect(response.body).to include("1 das últimas vagas muda de nota", "Python Engineer", "+20", "buscas do Radar mudam", "python")
    expect(profile.reload.skill_names).to include("Rails")
  end

  describe "CV and AI draft" do
    let(:pdf) { fixture_file_upload("cv.pdf", "application/pdf") }

    before { stub_request(:get, Ai::Pricing::MODELS_URL).to_return(body: { data: [] }.to_json) }

    around do |example|
      ENV["OPENROUTER_API_KEY"] = "chave-de-teste"
      example.run
    ensure
      ENV.delete("OPENROUTER_API_KEY")
    end

    it "reads the CV, makes the draft in the background and opens it in the form" do
      post upload_cv_profile_path, params: { cv: pdf }
      expect(response).to redirect_to(profile_path(anchor: "cv"))
      expect(flash[:notice]).to include("Currículo lido")
      expect(profile.reload.cv).to be_attached
      expect(profile.cv_text).to start_with("Ana Souza")

      get profile_path
      expect(response.body).to include("cv.pdf", "Montar perfil a partir do CV", "grátis com o modelo gratuito")

      expect { post draft_profile_path }.to have_enqueued_job(ProfileDraftJob)
      get cv_profile_path
      expect(response.body).to include("Montando o rascunho", 'data-controller="poll"')

      profile.update!(cv_draft: { "name" => "Ana do CV", "skills" => [ { "name" => "Elixir", "level" => "essential", "synonyms" => [] } ] }, cv_draft_status: "done")
      get cv_profile_path
      expect(response.body).to include("Rascunho pronto", "Abrir no formulário")

      get profile_path(rascunho: 1)
      expect(response.body).to include("Rascunho da IA no formulário", 'value="Ana do CV"', 'value="Elixir"', 'name="from_draft"')
      expect(profile.reload.name).to eq("Ana Souza")

      patch profile_path, params: { from_draft: "1", profile: { name: "Ana do CV" } }
      expect(profile.reload).to have_attributes(name: "Ana do CV", cv_draft: nil)
    end

    it "explains what is missing" do
      post draft_profile_path
      expect(flash[:alert]).to eq("Envie o currículo primeiro.")

      ENV.delete("OPENROUTER_API_KEY")
      post draft_profile_path
      expect(flash[:alert]).to include("chave do OpenRouter")

      post upload_cv_profile_path, params: { cv: fixture_file_upload("candidaturas_excel.csv", "image/png") }
      expect(flash[:alert]).to include("PDF, DOCX ou TXT")
    end

    it "discards the draft" do
      profile.update!(cv_text: "CV", cv_draft: { "name" => "X" }, cv_draft_status: "done")

      delete discard_draft_profile_path

      expect(profile.reload.cv_draft).to be_nil
    end
  end
end
