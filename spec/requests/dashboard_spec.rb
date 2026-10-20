require "rails_helper"

RSpec.describe "Dashboard" do
  before { sign_in }

  it "shows new postings, follow-ups and the routine" do
    create(:job_posting, title: "Senior Rails Engineer", score: 80)
    create(:job_posting, title: "Descartada", triage: "dismissed")
    create(:job_application, company: "Acme", status: "applied", next_follow_up_on: Date.current)
    create(:job_application, company: "Globex", status: "applied", applied_on: 7.days.ago.to_date)

    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Senior Rails Engineer", "Acme", "Globex", "Rotina de hoje")
    expect(response.body).not_to include("Descartada")
  end

  it "shows empty states" do
    get root_path

    expect(response.body).to include("Nenhuma vaga nova", "Nada para cobrar hoje")
  end
end

RSpec.describe "PWA" do
  it "serves the manifest without login" do
    get pwa_manifest_path(format: :json)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["name"]).to eq("WorkMachine")
  end

  it "serves the service worker" do
    get pwa_service_worker_path(format: :js)

    expect(response).to have_http_status(:ok)
  end
end
