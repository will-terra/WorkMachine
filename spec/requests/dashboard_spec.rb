require "rails_helper"

RSpec.describe "Dashboard" do
  it "shows the dashboard to the signed-in user" do
    sign_in

    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Painel")
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
