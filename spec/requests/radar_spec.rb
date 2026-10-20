require "rails_helper"

RSpec.describe "Radar" do
  before { sign_in }

  it "shows the searches, platforms, consultancies and groups" do
    create(:consultancy, name: "Yoctoo", kind: "tech")

    get radar_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Buscas na aba Vagas", "Ruby on Remote", "Yoctoo", "Vagas TI Brasil")
    expect(response.body).to include(CGI.escapeHTML(Radar.url_for("li_jobs", Radar.searches.first["query"])))
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
