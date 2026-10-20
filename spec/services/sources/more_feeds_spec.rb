require "rails_helper"

RSpec.describe "More aggregator sources" do
  before { stub_all_sources }

  describe Sources::WorkingNomads do
    it "keeps jobs whose title or tags mention Ruby or Rails" do
      postings = described_class.new.fetch

      expect(postings.map { it[:title] }).to eq([ "Ruby on Rails Developer" ])
      expect(postings.first).to include(company: "Exemplo Remoto", location_text: "Anywhere", source: "working_nomads")
      expect(postings.first[:url]).to start_with("https://www.workingnomads.com/job/")
    end
  end

  describe Sources::Himalayas do
    it "reads the search results with location restrictions" do
      postings = described_class.new.fetch

      expect(postings.size).to eq(3)
      expect(postings.first).to include(title: "Ruby on Rails Developer", company: "Pavago", location_text: "Brazil", source: "himalayas")
      expect(postings.first[:url]).to start_with("https://himalayas.app/companies/")
      expect(postings.third[:salary_text]).to match(/USD 120.000–165.000/)
    end
  end

  describe Sources::Remotar do
    it "reads the jobs with the Brazil hint, tags and salary" do
      postings = described_class.new.fetch

      expect(postings.size).to eq(3)
      clicksign = postings.find { it[:company] == "Clicksign" }
      expect(clicksign).to include(url: "https://remotar.com.br/job/167097", location_text: "Remoto", remote_scope_hint: "brazil")
      expect(clicksign[:description]).to include("Ruby on Rails", "Tags:", "Pleno")
      expect(postings.find { it[:title] == "Full Stack Engineer (Ruby On Rails)" }[:salary_text]).to eq("USD 60.000–110.000/ano")
      expect(clicksign[:raw]["apply_url"]).to include("gupy.io")
    end
  end
end
