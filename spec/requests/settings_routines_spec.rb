require "rails_helper"

RSpec.describe "Settings routines" do
  let(:routine) { Routine.current.find { it.name == "Rotina de busca" } }

  before { sign_in }

  it "lists the routines" do
    get settings_routines_path

    expect(response.body).to include("Configuração do app", "Rotina de busca", "Restaurar as rotinas prontas")
  end

  it "shows the form with the slots, the items and the templates for new rows" do
    get edit_settings_routine_path(routine)

    expect(response.body).to include("Manhã", "Triar as vagas novas", "NEW_SLOT", "NEW_ITEM", "Toda semana")
  end

  it "creates a routine with slots and items, skipping blank items" do
    get new_settings_routine_path
    expect(response).to have_http_status(:ok)

    post settings_routines_path, params: { routine: { name: "Entrevistas", position: 2, slots_attributes: {
      "0" => { title: "Antes", period: "once", position: 0, items_attributes: {
        "0" => { label: "Pesquisar a empresa", url: "/empresas-alvo", position: 0 },
        "1" => { label: "", position: 1 }
      } }
    } } }

    expect(response).to redirect_to(settings_routines_path)
    created = Routine.find_by!(name: "Entrevistas")
    expect(created.slots.sole).to have_attributes(title: "Antes", period: "once")
    expect(created.items.map(&:label)).to eq([ "Pesquisar a empresa" ])
  end

  it "edits, reorders and removes items" do
    slot = routine.slots.first
    first, second, *rest = slot.items

    patch settings_routine_path(routine), params: { routine: { name: "Minha rotina", slots_attributes: {
      "0" => { id: slot.id, title: "Cedo", period: "daily", items_attributes: {
        "0" => { id: first.id, label: "Triar", position: 1 },
        "1" => { id: second.id, label: second.label, position: 0 },
        "2" => { id: rest.first.id, _destroy: "1" }
      } }
    } } }

    expect(response).to redirect_to(settings_routines_path)
    expect(routine.reload.name).to eq("Minha rotina")
    expect(slot.reload.title).to eq("Cedo")
    expect(slot.items.map(&:label).first(2)).to eq([ second.label, "Triar" ])
    expect(RoutineItem.exists?(rest.first.id)).to be(false)
  end

  it "keeps the form on invalid data" do
    patch settings_routine_path(routine), params: { routine: { name: "" } }

    expect(response).to have_http_status(:unprocessable_content)

    post settings_routines_path, params: { routine: { name: "" } }

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "deletes a routine and restores the ready-made ones" do
    delete settings_routine_path(routine)

    expect(response).to redirect_to(settings_routines_path)
    expect(Routine.pluck(:name)).to eq([ "Configuração do app" ])

    post restore_settings_routines_path

    expect(Routine.pluck(:name)).to contain_exactly("Configuração do app", "Rotina de busca")
  end
end
