require "rails_helper"

RSpec.describe LinkedinJobText do
  let(:page) do
    <<~TEXT
      Velozient

      Senior Software Engineer (RoR)

      México · há 1 semana · 78 candidaturas
      Reative Premium: 50% de desconto
      Sobre a vaga

      We are looking for a Senior Software Engineer.

      About The Company

      A healthtech client.



      … mais

      Requisitos adicionados pelo anunciante da vaga

      • Mais de 5 anos de experiência profissional com Ruby on Rails

      Ative um alerta para vagas semelhantes

      Sobre a empresa

      Mais vagas

      LinkedIn Corporation © 2026
      English (Inglês)
    TEXT
  end

  it "keeps only the description, up to the alert box" do
    expect(described_class.call(page)).to eq(<<~TEXT.strip)
      We are looking for a Senior Software Engineer.

      About The Company

      A healthtech client.

      Requisitos adicionados pelo anunciante da vaga

      • Mais de 5 anos de experiência profissional com Ruby on Rails
    TEXT
  end

  it "stops at the next LinkedIn heading when there is no alert box" do
    expect(described_class.call("About the job\nRails and React\n...more\nAbout the company\nAcme")).to eq("Rails and React")
  end

  it "drops a whole page saved without a description" do
    expect(described_class.call("BairesDev\nRuby Developer\nAnunciar vaga\nLinkedIn Corporation © 2026")).to be_nil
  end

  it "leaves a plain description alone" do
    expect(described_class.call("Ruby on Rails and React")).to eq("Ruby on Rails and React")
    expect(described_class.call(nil)).to be_nil
  end

  it "recognizes LinkedIn URLs" do
    expect(described_class.linkedin?("https://www.linkedin.com/jobs/view/1")).to be(true)
    expect(described_class.linkedin?("https://notlinkedin.com/jobs/1")).to be(false)
    expect(described_class.linkedin?("not a url ^")).to be(false)
  end
end
