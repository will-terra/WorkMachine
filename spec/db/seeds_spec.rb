require "rails_helper"

RSpec.describe "db/seeds.rb" do
  def run_seeds
    expect { load Rails.root.join("db/seeds.rb") }.to output(/Seeds:/).to_stdout
  end

  it "creates consultancies, templates and example companies, idempotently" do
    run_seeds
    run_seeds

    expect(Consultancy.count).to eq(26)
    expect(Consultancy.platform.count).to eq(10)
    expect(MessageTemplate.count).to eq(7)
    expect(TargetCompany.where(example: true).count).to eq(7)
  end

  it "keeps connection notes under the LinkedIn limit" do
    run_seeds

    MessageTemplate.where.not(max_chars: nil).find_each do |template|
      expect(template.render(nome: "Maria Eduarda").length).to be <= template.max_chars
    end
  end

  it "does not overwrite a template edited in the app" do
    run_seeds
    MessageTemplate.find_by!(name: "Connection note (EN)").update!(body: "Editado")

    run_seeds

    expect(MessageTemplate.find_by!(name: "Connection note (EN)").body).to eq("Editado")
  end
end
