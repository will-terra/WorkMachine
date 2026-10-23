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
    expect(body).to include("o que fazer à mão", "1 com erro (Remotive)", "Gmail não configurado", "GoRails Jobs")
    expect(body).to match(%r{GoRails Jobs</a>.*?<td class="text-right font-mono text-\[12.5px\]">4</td>}m)
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

  describe "LinkedIn alerts" do
    let(:searches) { Radar.alert_searches }

    it "lists the alerts with a box, the ones already on at the end, and counts the ones left" do
      cargos = searches.find { it["key"] == "alert_cargos" }
      ActivatedAlert.create!(search_key: "alert_cargos", query: cargos["query"], created_at: Time.zone.local(2026, 10, 20, 9))

      get radar_path

      body = response.body
      left = searches.size - 1
      expect(body).to include("#{left} alertas do LinkedIn para ativar", 'href="#linkedin_alerts"', "1 de #{searches.size} alertas ativados", "ativado em 20/10")
      expect(body).to match(%r{id="pending_alerts_count"[^>]*>#{left}</span>})
      expect(body).to include('id="alert_alert_nivel"', 'id="alert_alert_cargos"')
      expect(body.index('id="alert_alert_nivel"')).to be < body.index('id="alert_alert_cargos"')
      expect(body).not_to include("Buscas antigas que continuam ativadas")
    end

    it "lists the alerts turned on for a query that the profile no longer makes" do
      ActivatedAlert.create!(search_key: "alert_cargos", query: '("Desenvolvedor Python" OR "Python Developer")')

      get radar_path

      expect(response.body).to include("Buscas antigas que continuam ativadas", "Cargos alvo", "Desenvolvedor Python",
                                       "1 alerta antigo para desligar no LinkedIn")
    end

    it "keeps the link to the alerts when they are all on" do
      searches.each { ActivatedAlert.create!(search_key: it["key"], query: it["query"]) }

      get radar_path

      expect(response.body).to include("Os #{searches.size} alertas do LinkedIn estão ativados", 'href="#linkedin_alerts"',
                                       "#{searches.size} de #{searches.size} alertas ativados")
      expect(response.body).not_to include("para ativar", "linkedin_alerts_li_region")
    end

    it "hides the notice while the profile is empty" do
      Profile.current.update!(skills: [], search_terms: [])

      get radar_path

      expect(response.body).not_to include("para ativar")
    end
  end

  it "applies and remembers the filters" do
    get radar_path(li_region: "world_remote", li_period: "r2592000")
    get radar_path

    expect(response.body).to include("geoId=92000000&amp;f_WT=2&amp;f_TPR=r2592000")
  end
end

RSpec.describe "Activated alerts" do
  before { sign_in }

  let(:search) { Radar.alert_searches.first }

  it "turns an alert on and off, sending the list back in its new order" do
    post activated_alerts_path, params: { search_key: search["key"], query: search["query"] }, as: :turbo_stream

    expect(response.media_type).to eq(Mime[:turbo_stream])
    alert = ActivatedAlert.sole
    expect(alert).to have_attributes(search_key: search["key"], query: search["query"])
    expect(response.body).to include("linkedin_alerts_list", "pending_alerts_count", "1 de #{Radar.alert_searches.size} alertas ativados")

    post activated_alerts_path, params: { search_key: search["key"], query: search["query"] }, as: :turbo_stream
    expect(ActivatedAlert.count).to eq(1)

    delete activated_alert_path(alert)

    expect(response).to redirect_to(radar_path(anchor: "linkedin_alerts"))
    expect(ActivatedAlert.count).to eq(0)
  end

  it "ignores an alert that is already off" do
    delete activated_alert_path(42), as: :turbo_stream

    expect(response).to have_http_status(:ok)
  end
end

RSpec.describe "Consultancies" do
  before { sign_in }

  let(:consultancy) { create(:consultancy) }

  it "marks a consultancy as registered and back" do
    patch consultancy_path(consultancy), params: { registered: "1" }, as: :turbo_stream

    expect(response.media_type).to eq(Mime[:turbo_stream])
    expect(response.body).to include('target="registrations"', "1/1", "1 de 1 cadastros feitos", "1 cadastrado")
    expect(consultancy.reload.registered_on).to eq(Date.current)

    patch consultancy_path(consultancy), params: { registered: "0" }

    expect(response).to redirect_to(radar_path(anchor: "cadastros"))
    expect(consultancy.reload.registered_on).to be_nil
  end

  it "keeps the original registration date" do
    consultancy.update!(registered_on: Date.new(2026, 9, 1))

    patch consultancy_path(consultancy), params: { registered: "1" }

    expect(consultancy.reload.registered_on).to eq(Date.new(2026, 9, 1))
  end
end
