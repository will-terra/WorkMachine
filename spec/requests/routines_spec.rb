require "rails_helper"

RSpec.describe "Routine" do
  let(:search_items) { Routine.current.find { it.name == "Rotina de busca" }.items.size }

  before { sign_in }

  it "shows the checklist and the rules" do
    get routine_path

    expect(response.body).to include("Manhã", "Uma vez por semana", "Aderência antes de volume.", "0/#{search_items} feitos")
    expect(response.body).to include("Configuração do app", "Cadastrar seu perfil em uma plataforma da lista do Radar", %(href="/radar#cadastros"))
  end

  it "toggles an item with Turbo Stream" do
    post toggle_routine_path(key: "m1"), as: :turbo_stream

    expect(response.media_type).to eq(Mime[:turbo_stream])
    expect(response.body).to include("routine_item_m1", "checked", "routine_progress_bar_", "1/#{search_items} feitos")
    expect(Routine.checked_keys).to include("m1")
  end

  it "toggles back with a plain form post" do
    Routine.toggle!("m1")

    post toggle_routine_path(key: "m1"), headers: { "HTTP_REFERER" => root_url }

    expect(response).to redirect_to(root_url)
    expect(Routine.checked_keys).not_to include("m1")
  end

  it "returns 404 for unknown items" do
    post toggle_routine_path(key: "zz")

    expect(response).to have_http_status(:not_found)
  end
end
