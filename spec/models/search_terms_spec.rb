require "rails_helper"

RSpec.describe SearchTerms do
  let(:terms) { described_class.new(Profile.current) }

  it "turns the profile's lists into boolean groups" do
    expect(terms.variables).to include(
      "stack" => "Rails",
      "stack_or" => '(Rails OR "Ruby on Rails")',
      "cargos_en_or" => '("Ruby on Rails Developer" OR "Full Stack Engineer")',
      "area" => '"Full stack"',
      "senioridade_or" => '(pleno OR "mid-level" OR "mid level")',
      "termos" => "“rails” e “ruby”"
    )
  end

  it "leaves a search out when a placeholder is empty, and complains about unknown ones" do
    empty = described_class.new(Profile.new)

    expect(empty.render("{{plano_b_or}} AND x")).to be_nil
    expect(empty.render_text("Busque {{termos}}.")).to eq("Busque os termos do seu perfil.")
    expect { terms.render("{{nope}}") }.to raise_error(KeyError, /nope/)
  end

  it "falls back to the area's titles and to the search terms" do
    profile = build(:profile, target_titles: [], target_titles_en: [], skills: [], primary_area: "qa")
    variables = described_class.new(profile).variables

    expect(variables["cargo"]).to eq("Analista de QA")
    expect(variables["stack"]).to eq("rails")
  end
end
