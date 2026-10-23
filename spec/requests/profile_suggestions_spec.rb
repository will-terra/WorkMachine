require "rails_helper"

RSpec.describe "Profile suggestions" do
  before do
    sign_in
    Profile.current.update!(skills: [ { "name" => "Ruby on Rails", "level" => "essential" } ], avoid_terms: [])
    create_list(:job_posting, 10, triage: "saved", description: "Ruby on Rails")
    create_list(:job_posting, 30, triage: "dismissed", description: "PHP and Laravel")
  end

  it "shows the suggestions on the profile and the Painel, applies one and dismisses another" do
    get root_path
    expect(response.body).to include("O WorkMachine tem 2 sugestões para o seu perfil", "#sugestoes")

    get profile_path
    expect(response.body).to include("Sugestões das suas triagens", "Você descartou 30 vagas com “PHP” e não salvou nenhuma.", "Colocar em Evitar")

    post apply_profile_suggestions_path, params: { key: "avoid:php" }
    expect(response).to redirect_to(profile_path)
    expect(flash[:notice]).to include("PHP")
    expect(Profile.current.reload.avoid_terms).to eq([ "PHP" ])

    post dismiss_profile_suggestions_path, params: { key: "avoid:laravel" }
    expect(Setting.current.dismissed_suggestions).to eq([ "avoid:laravel" ])

    get profile_path
    expect(response.body).not_to include("Sugestões das suas triagens")
  end

  it "refuses a suggestion that no longer holds" do
    post apply_profile_suggestions_path, params: { key: "avoid:cobol" }

    expect(flash[:alert]).to eq("Essa sugestão não vale mais.")
  end
end
