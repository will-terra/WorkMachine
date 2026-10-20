require "rails_helper"

RSpec.describe Routine do
  let(:monday) { Date.new(2026, 10, 19) }
  let(:wednesday) { Date.new(2026, 10, 21) }

  it "loads the slots from config/routine.yml" do
    expect(described_class.slots.map(&:title)).to include("Manhã", "Uma vez por semana")
    expect(described_class.find_item("w1")).to be_weekly
    expect(described_class.rules).to be_present
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

  it "unchecks on the second toggle" do
    described_class.toggle!("m2", monday)

    expect(described_class.toggle!("m2", monday)).to be(false)
    expect(described_class.checked_keys(monday)).to be_empty
  end

  it "rejects unknown keys" do
    expect { described_class.toggle!("zz") }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
