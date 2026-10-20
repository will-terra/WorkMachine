require "rails_helper"

RSpec.describe "Radar" do
  before { sign_in }

  it "shows the manual tasks by frequency with a summary of the automated sources" do
    create(:consultancy, name: "RailsDevs", kind: "platform", registered_on: Date.current)
    create(:consultancy, name: "Yoctoo", kind: "tech")
    SourceRun.create!(source: "gorails", status: "succeeded", created_count: 4)
    SourceRun.create!(source: "remotive", status: "failed", error_message: "HttpClient::Error: 503")
    create(:job_posting)

    get radar_path

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to include("O que fazer à mão", "Vagas novas (1)", "1 com erro (Remotive)", "Gmail não configurado", "GoRails Jobs", "4 novas")
    expect(body).to include("Publicações no LinkedIn", "Grupos do Telegram", "Ruby on Remote", "1 de 2 cadastros feitos", "Plataformas com perfil", "Yoctoo")
    expect(body.index("Todo dia")).to be < body.index("Toda semana")
    expect(body.index("Toda semana")).to be < body.index('id="linkedin_alerts"')
  end

  it "shows how the LinkedIn alerts are arriving" do
    allow(LinkedinAlerts::Importer).to receive(:configured?).and_return(true)
    ProcessedEmail.create!(message_id: "a@linkedin.com", received_at: Time.zone.local(2026, 10, 20, 8, 42))

    get radar_path

    expect(response.body).to include("1 alerta lido; o último chegou em 20/10 08:42")
  end

  it "applies and remembers the filters" do
    get radar_path(li_region: "world_remote", li_period: "r2592000")
    get radar_path

    expect(response.body).to include("geoId=92000000&amp;f_WT=2&amp;f_TPR=r2592000")
  end
end

RSpec.describe "Consultancies" do
  before { sign_in }

  let(:consultancy) { create(:consultancy) }

  it "marks a consultancy as registered and back" do
    patch consultancy_path(consultancy), params: { registered: "1" }, as: :turbo_stream

    expect(response.media_type).to eq(Mime[:turbo_stream])
    expect(consultancy.reload.registered_on).to eq(Date.current)

    patch consultancy_path(consultancy), params: { registered: "0" }

    expect(response).to redirect_to(radar_path(anchor: "consultorias"))
    expect(consultancy.reload.registered_on).to be_nil
  end

  it "keeps the original registration date" do
    consultancy.update!(registered_on: Date.new(2026, 9, 1))

    patch consultancy_path(consultancy), params: { registered: "1" }

    expect(consultancy.reload.registered_on).to eq(Date.new(2026, 9, 1))
  end
end
