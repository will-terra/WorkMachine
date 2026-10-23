require "rails_helper"

RSpec.describe ActivatedAlert do
  let(:searches) do
    [ { "key" => "alert_cargos", "query" => "(Rails OR Ruby)" }, { "key" => "alert_area", "query" => "Rails AND backend" },
      { "key" => "alert_nivel", "query" => "Rails AND senior" } ]
  end

  it "puts the alerts to turn on first and the ones already on at the end, the latest last" do
    nivel = described_class.create!(search_key: "alert_nivel", query: "Rails AND senior", created_at: 2.days.ago)
    cargos = described_class.create!(search_key: "alert_cargos", query: "(Rails OR Ruby)", created_at: 1.day.ago)

    sorted = described_class.sorted(searches)

    expect(sorted.map { it.first["key"] }).to eq(%w[alert_area alert_nivel alert_cargos])
    expect(sorted.map(&:last)).to eq([ nil, nivel, cargos ])
    expect(described_class.pending_count(searches)).to eq(1)
  end

  it "lists as outdated the alerts turned on for a query the profile no longer makes" do
    described_class.create!(search_key: "alert_area", query: "Rails AND backend")
    old = described_class.create!(search_key: "alert_area", query: "Ruby AND backend")

    expect(described_class.outdated(searches)).to eq([ old ])
  end

  it "keeps one alert per query" do
    described_class.create!(search_key: "alert_area", query: "Rails AND backend")

    expect(described_class.new(search_key: "alert_nivel", query: "Rails AND backend")).not_to be_valid
  end
end
