require "rails_helper"

# Sites without an API, read from their pages (fixtures recorded from the real pages, cut down).
RSpec.describe "Brazilian job sites" do
  before { stub_all_sources }

  describe Sources::Gupy do
    it "reads the jobs from the portal's search, without the closed ones nor the ones off the profile" do
      postings = described_class.new.fetch

      expect(postings.size).to eq(1)
      expect(postings.first).to include(title: "Pessoa Desenvolvedora Ruby on Rails - Especialista", company: "Fcamara", location_text: "Remoto",
                                        url: start_with("https://fcamara.gupy.io/job/"), external_id: "12724726", remote_scope_hint: "brazil", source: "gupy")
      expect(postings.first[:description]).to start_with("Contrato: CLT\n\nEstamos em busca")
      expect(postings.first[:posted_at]).to eq(Time.zone.parse("2026-10-14T17:29:30.139Z"))
    end

    it "keeps the hybrid and PJ jobs that match, with the city" do
      Profile.current.update!(search_terms: [ "java", "full stack" ])
      %w[java full%20stack].each { stub_source("https://portal.gupy.io/job-search/term=#{it}", "gupy.html", content_type: "text/html") }

      postings = described_class.new.fetch

      expect(postings.map { it[:location_text] }).to include("Híbrido · São Paulo")
      expect(postings.map { it[:description] }).to include(start_with("Contrato: PJ"))
      expect(postings.map { it[:description] }.join).not_to include("&nbsp;")
    end

    it "takes the company from the career page, without emojis or slogans" do
      source = described_class.new
      name = ->(career_page) { source.send(:company, { "careerPageName" => career_page, "jobUrl" => "https://fcamara.gupy.io/job/1" }) }

      expect([ name.("KOVI ❤️"), name.("Encontre aqui uma vaga na Logicalis Brasil"), name.("Grupo Boticário"), name.("#sejaveriter") ])
        .to eq([ "KOVI", "Logicalis Brasil", "Grupo Boticário", "Fcamara" ])
    end

    it "fails clearly when the page comes without the jobs" do
      stub_request(:get, "https://portal.gupy.io/job-search/term=rails").to_return(body: "<html><body>Manutenção</body></html>")

      expect { described_class.new.fetch }.to raise_error(HttpClient::Error, /sem os dados das vagas/)
    end
  end

  describe Sources::Programathor do
    it "skips expired jobs and technologies the site does not have" do
      expect(described_class.new.fetch).to eq([])
    end

    it "reads the open cards of a technology page" do
      Profile.current.update!(search_terms: %w[react])
      stub_source("https://programathor.com.br/jobs-react", "programathor_react.html", content_type: "text/html")

      postings = described_class.new.fetch

      expect(postings.map { it[:title] }).to eq([ "Desenvolvedor Full-Stack Estágio", "Desenvolvedor(a) Full Stack Júnior — React e TypeScript" ])
      expect(postings.second).to include(company: "Viradev", location_text: "Remoto", salary_text: "Até R$10.000", remote_scope_hint: "brazil",
                                        url: "https://programathor.com.br/jobs/33838-desenvolvedor-a-full-stack-junior-react-e-typescript",
                                        external_id: "33838", source: "programathor")
      expect(postings.second[:description]).to eq("Tecnologias: CSS, Git, HTML, JavaScript, TypeScript, ReactJS\nJúnior · PJ · Pequena/média empresa")
      expect(postings.first).to include(location_text: "Vinhedo (Presencial)", remote_scope_hint: nil)
    end
  end

  describe Sources::VagasCom do
    it "reads nothing from an empty search" do
      expect(described_class.new.fetch).to eq([])
    end

    it "reads the jobs of a search page" do
      Profile.current.update!(search_terms: %w[react])
      stub_source("https://www.vagas.com.br/vagas-de-react", "vagas_com_react.html", content_type: "text/html")

      postings = described_class.new.fetch

      expect(postings).not_to be_empty
      posting = postings.first
      expect(posting).to include(source: "vagas_com", remote_scope_hint: "brazil", url: match(%r{\Ahttps://www\.vagas\.com\.br/vagas/v\d+/}))
      expect(posting[:external_id]).to match(/\A\d+\z/)
      expect(posting[:title]).to be_present
      expect(posting[:posted_at]).to be_a(ActiveSupport::TimeWithZone)
      expect(postings.map { it[:description] }).to all(match(/react/i))
    end
  end

  describe Sources::TelegramChannels do
    before { Profile.current.update!(seniority: "junior", search_terms: [ "front-end", "dados" ]) }

    it "only runs for a junior profile" do
      expect(described_class.applicable?(Profile.current)).to be(true)
      expect(described_class.applicable?(build(:profile, seniority: "mid"))).to be(false)
    end

    it "reads the job posts of the channel, without its notices" do
      postings = described_class.new.fetch

      expect(postings.map { it[:title] }).to eq([ "Analista de Dados Júnior - Radix", "Desenvolvedor(a) Front-end Júnior", "Desenvolvedor(a) Front-end Júnior",
                                                  "Programa de Estágio Serasa Experian - 2027" ])
      expect(postings.last).to include(company: nil, salary_text: "R$ 2150")
      radix = postings.first
      expect(radix).to include(company: "Radix", location_text: "remoto", url: "https://t.me/CafeinaVagas/5214", external_id: "CafeinaVagas/5214",
                               remote_scope_hint: "brazil", source: "telegram")
      expect(radix[:raw]).to include("apply_url" => start_with("https://radix.inhire.app/"), "tags" => include("dados", "junior", "remoto"))
      expect(radix[:posted_at]).to be_a(ActiveSupport::TimeWithZone)
      expect(postings.third[:raw]["apply_url"]).to eq("https://lnkd.in/p/d5KKtC4C")
    end
  end
end
