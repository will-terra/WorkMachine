require "rails_helper"

RSpec.describe "Metrics" do
  before { sign_in }

  it "shows the tiles, the charts and the tables" do
    create(:job_application, origin: "Remotar", status: "hr_interview", applied_on: 3.days.ago.to_date, responded_on: 1.day.ago.to_date)
    create(:job_posting, source: "remotar", triage: "saved")

    get metrics_path(period: "30")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Taxa de resposta", "100%", "Candidaturas por semana", "Funil", "Entrevista ou teste", "Por origem da candidatura", "Remotar", "Fontes de vagas", "2 dias")
    expect(response.body).to include('aria-current="true"')
  end

  it "shows an empty state" do
    get metrics_path

    expect(response.body).to include("Nenhuma candidatura aplicada neste período", "Fontes de vagas", "Esta semana", "0 candidaturas", "Dica:")
  end
end
