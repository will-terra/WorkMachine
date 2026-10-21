require "rails_helper"

RSpec.describe "Onboarding" do
  before { sign_in }

  it "shows the steps and what is done" do
    get onboarding_path

    expect(response.body).to include("Chave da IA e Gmail", "Seu perfil", "Primeira busca", "Revisar o perfil", "Buscar vagas e começar")
    get root_path
    expect(response.body).to include("Continuar a configuração")
  end

  it "runs the first search and finishes" do
    expect { post finish_onboarding_path(search: 1) }.to have_enqueued_job(FetchJobsJob)

    expect(response).to redirect_to(job_postings_path)
    expect(Setting.current).to be_onboarded
    get root_path
    expect(response.body).not_to include("Continuar a configuração")
  end

  it "can be skipped" do
    post finish_onboarding_path

    expect(response).to redirect_to(root_path)
    expect(Setting.current).to be_onboarded
  end

  it "asks for the profile before the first search" do
    Profile.delete_all
    Current.profile = nil

    get onboarding_path
    expect(response.body).to include("Preencha o perfil primeiro", "Montar o perfil")
  end
end
