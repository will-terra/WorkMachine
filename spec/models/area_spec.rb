require "rails_helper"

RSpec.describe Area do
  it "loads every technology area with its starting points" do
    expect(described_class.keys).to eq(%w[backend frontend fullstack mobile qa devops data design product])
    described_class.all.each do |area|
      expect([ area.name, area.group, area.titles_pt, area.titles_en, area.terms, area.hirers, area.title_filter ]).to all(be_present), area.key
    end
  end

  it "suggests skills with a starting level" do
    skills = described_class.find("data").suggested_skills

    expect(skills.first).to eq({ "name" => "Python", "level" => "essential" })
    expect(skills.map { it["level"] }.uniq).to eq(%w[essential important extra])
  end

  it "groups the areas for selects" do
    expect(described_class.grouped_options.first).to eq([ "Desenvolvimento", [ [ "Back-end", "backend" ], [ "Front-end", "frontend" ], [ "Full stack", "fullstack" ], [ "Mobile", "mobile" ] ] ])
  end
end
