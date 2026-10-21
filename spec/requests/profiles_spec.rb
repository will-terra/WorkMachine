require "rails_helper"

RSpec.describe "Profile" do
  before { sign_in }

  let(:profile) { Profile.current }

  it "shows the form with the area suggestions and the Radar searches" do
    get profile_path

    expect(response.body).to include("Área e objetivo", "Skills", "Buscas do Radar", "Texto para a IA", 'value="Rails"', "profile-form-areas-value")
    expect(response.body).to include("search_override_feed_contratando")
  end

  it "saves the profile and rescores the postings when the skills change" do
    expect {
      patch profile_path, params: { profile: {
        name: "Bia", primary_area: "data", seniority: "senior", years_experience: "6",
        target_titles: "Engenheira de Dados\nAnalista de Dados", regions: [ "", "brazil", "us" ], work_modes: [ "" ],
        skills: { "0" => { name: "Python", level: "essential", synonyms: "py" }, "1" => { name: "Rails", level: "extra", _destroy: "1" },
                  "blank" => { name: "" } },
        search_terms: "python, sql", avoid_terms: "", search_overrides: { feed_contratando: "  Python AND vaga ", feed_hiring: "" }
      } }
    }.to have_enqueued_job(RescorePostingsJob)

    expect(response).to redirect_to(profile_path)
    expect(flash[:notice]).to include("recalculadas")
    expect(profile.reload).to have_attributes(name: "Bia", primary_area: "data", seniority: "senior", years_experience: 6,
                                              target_titles: [ "Engenheira de Dados", "Analista de Dados" ], regions: %w[brazil us],
                                              work_modes: [], search_terms: %w[python sql], search_overrides: { "feed_contratando" => "Python AND vaga" })
    expect(profile.skills).to eq([ { "name" => "Python", "level" => "essential", "synonyms" => [ "py" ] } ])
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

    expect(response.body).to include("Prévia: nada foi salvo ainda", "Python Engineer", "(+20)", "Buscas do Radar que mudam", "python")
    expect(profile.reload.skill_names).to include("Rails")
  end
end
