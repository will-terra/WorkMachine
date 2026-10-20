require "rails_helper"

RSpec.describe Radar do
  it "has every search with a known builder" do
    expect(described_class.searches).not_to be_empty
    expect(described_class.searches.map { it.fetch("builder") }.uniq - Radar::BUILDERS).to be_empty
  end

  it "has a default for every filter used by a section" do
    used = described_class.sections.flat_map { it.fetch("filters", []) }.uniq

    expect(used).to all(satisfy { described_class.filters.dig(it, "default") })
  end
end
