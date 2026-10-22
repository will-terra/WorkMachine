require "rails_helper"

RSpec.describe Routine do
  let(:monday) { Date.new(2026, 10, 19) }
  let(:wednesday) { Date.new(2026, 10, 21) }

  it "copies the ready-made routines from config/routine.yml on first use" do
    expect(described_class.current.map(&:name)).to eq([ "Configuração do app", "Rotina de busca" ])
    expect(described_class.current.first).to be_once
    expect(described_class.current.last.slots.map(&:title)).to include("Manhã", "Uma vez por semana")
    expect(described_class.find_item("w1")).to be_weekly
    expect(described_class.find_item("m4")).to have_attributes(label: "Cadastrar seu perfil em uma plataforma da lista do Radar", url: "/radar#cadastros")
    expect(described_class.rules).to be_present
  end

  it "does not copy them again after the routines are edited or deleted" do
    described_class.current.each(&:destroy!)

    expect(described_class.current).to be_empty
  end

  it "restores the ready-made routines and keeps the checks of the same keys" do
    described_class.toggle!("m1")
    described_class.current.each(&:destroy!)

    described_class.restore_defaults!

    expect(described_class.current.size).to eq(2)
    expect(described_class.checked_keys).to include("m1")
  end

  it "keeps daily checks for the day only" do
    expect(described_class.toggle!("m1", monday)).to be(true)

    expect(described_class.checked_keys(monday)).to include("m1")
    expect(described_class.checked_keys(wednesday)).not_to include("m1")
  end

  it "keeps weekly checks for the whole week" do
    described_class.toggle!("w1", wednesday)

    expect(RoutineCheck.last.date).to eq(monday)
    expect(described_class.checked_keys(monday + 6)).to include("w1")
    expect(described_class.checked_keys(monday + 7)).not_to include("w1")
  end

  it "keeps the setup checks for good" do
    described_class.toggle!("s1", monday)

    expect(described_class.checked_keys(monday + 90)).to include("s1")
    expect(described_class.toggle!("s1", monday + 90)).to be(false)
    expect(described_class.checked_keys(monday)).not_to include("s1")
  end

  it "unchecks on the second toggle" do
    described_class.toggle!("m2", monday)

    expect(described_class.toggle!("m2", monday)).to be(false)
    expect(described_class.checked_keys(monday)).to be_empty
  end

  it "counts the progress of a routine" do
    routine = described_class.current.last
    described_class.toggle!("m1")

    expect(routine.progress(described_class.checked_keys)).to eq([ 1, routine.items.size ])
  end

  it "rejects unknown keys" do
    expect { described_class.toggle!("zz") }.to raise_error(ActiveRecord::RecordNotFound)
  end

  describe RoutineItem do
    let(:slot) { Routine.current.first.slots.first }

    it "gets a random key and accepts only app paths and https links" do
      item = slot.items.create!(label: " Nova tarefa ", url: "/radar")

      expect(item).to have_attributes(label: "Nova tarefa", key: match(/\Ai\h{8}\z/))
      expect(slot.items.build(label: "x", url: "javascript:alert(1)")).not_to be_valid
      expect(slot.items.build(label: "x", url: "https://openrouter.ai")).to be_valid
    end
  end
end
