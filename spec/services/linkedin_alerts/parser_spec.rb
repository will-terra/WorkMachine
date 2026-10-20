require "rails_helper"

RSpec.describe LinkedinAlerts::Parser do
  def parse_fixture(name)
    LinkedinAlerts::Importer.parse(fixture_text("emails/#{name}")).last
  end

  let(:expected) do
    [
      { title: "Desenvolvedor Ruby on Rails Pleno", company: "Acme Tecnologia", location_text: "São Paulo, Brasil (Remoto)", url: "https://www.linkedin.com/jobs/view/4012345678" },
      { title: "Full Stack Engineer (Rails/React)", company: "Globex", location_text: "América Latina (Remoto)", url: "https://www.linkedin.com/jobs/view/4023456789" },
      { title: "Backend Engineer – Ruby", company: "Initech", location_text: "Porto Alegre, Rio Grande do Sul, Brasil (Híbrido)", url: "https://www.linkedin.com/jobs/view/4034567890" }
    ]
  end

  it "reads title, company, location and canonical link from the HTML part" do
    jobs = parse_fixture("linkedin_job_alert.eml")

    expect(jobs.map { it.except(:external_id) }).to eq(expected)
    expect(jobs.first[:external_id]).to eq("4012345678")
  end

  it "falls back to the plain-text part" do
    expect(parse_fixture("linkedin_job_alert_text_only.eml").map { it.except(:external_id) }).to eq(expected)
  end

  it "keeps a \"|\" inside the company name" do
    html = '<a href="https://www.linkedin.com/comm/jobs/view/777"><p>Dev Web</p><p>Contato Seguro | Canal de Denúncias · Porto Alegre (Remoto)</p></a>'

    expect(described_class.call(html:).first).to include(company: "Contato Seguro | Canal de Denúncias", location_text: "Porto Alegre (Remoto)")
  end

  it "tolerates a layout with only a title link" do
    html = '<div><a href="https://br.linkedin.com/jobs/view/rails-dev-at-acme-555">Rails Dev</a></div><a href="https://www.linkedin.com/jobs/view/555">Ver vaga</a>'

    expect(described_class.call(html:)).to eq([ { title: "Rails Dev", company: nil, location_text: nil, url: "https://www.linkedin.com/jobs/view/555", external_id: "555" } ])
  end

  it "ignores links without a usable title and e-mails without jobs" do
    expect(described_class.call(html: '<a href="https://www.linkedin.com/comm/jobs/view/1"><img alt=""></a>')).to eq([])
    expect(described_class.call(html: "<p>Nada aqui</p>", text: "Nada aqui")).to eq([])
    expect(described_class.call).to eq([])
  end
end
