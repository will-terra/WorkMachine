require "rails_helper"

RSpec.describe "Aggregator sources" do
  def fetch(source_class) = source_class.new.fetch

  describe Sources::Remotive do
    it "fetches rails and ruby searches, dedups and converts HTML" do
      stub_all_sources

      postings = fetch(described_class)

      expect(postings.size).to eq(3)
      rails_job = postings.find { it[:title] == "Tech Lead Full-Stack Rails Engineer" }
      expect(rails_job).to include(source: "remotive", location_text: "USA, Canada, USA timezones")
      expect(rails_job[:url]).to start_with("https://remotive.com/")
      expect(rails_job[:description]).not_to include("<p>")
      expect(rails_job[:posted_at]).to be_a(ActiveSupport::TimeWithZone)
    end

    it "is due only every 6 hours" do
      travel_to Time.zone.local(2026, 10, 20, 12) do
        expect(described_class).to be_due
        SourceRun.create!(source: "remotive", status: "succeeded", created_at: 3.hours.ago)
        expect(described_class).not_to be_due
      end
      travel_to Time.zone.local(2026, 10, 20, 17, 50) do
        expect(described_class).to be_due
      end
    end
  end

  describe Sources::RemoteOk do
    it "keeps only jobs tagged ruby or rails, with salary" do
      stub_all_sources

      postings = fetch(described_class)

      expect(postings.map { it[:title] }).to eq([ "Senior React Full stack Developer", "Technical Product Manager AI Stockbroking App" ])
      expect(postings.first).to include(company: "Lemon.io", salary_text: "US$ 80.000–200.000/ano")
      expect(postings.first[:description]).to include("Lemon.io — the marketplace")
      expect(postings.first[:url]).to include("remoteOK.com/remote-jobs/")
    end
  end

  describe Sources::WeWorkRemotely do
    it "filters by ruby/rails in the text, not in image URLs" do
      stub_all_sources

      postings = fetch(described_class)

      expect(postings.map { [ it[:company], it[:title] ] }).to eq([ [ "Expel", "Systems Engineer" ], [ "Sanctuary Computer", "Head of Technology" ] ])
      expect(postings.first[:location_text]).to eq("Anywhere in the World")
    end
  end

  describe Sources::BackendBr do
    it "keeps Ruby issues and reads location and company from the title" do
      stub_all_sources

      postings = fetch(described_class)

      expect(postings.size).to eq(1)
      expect(postings.first).to include(location_text: "Remoto", remote_scope_hint: "brazil", source: "backend_br")
      expect(postings.first[:title]).to start_with("Engenheiro(a) de Software Sênior")
      expect(postings.first[:raw]["labels"]).to include("Ruby")
    end

    it "sends the GitHub token when configured" do
      stub = stub_request(:get, /api.github.com/).with(headers: { "Authorization" => "Bearer abc" }).to_return(body: "[]")

      with_env("GITHUB_TOKEN" => "abc") { fetch(described_class) }

      expect(stub).to have_been_requested
    end
  end

  describe Sources::FrontendBr do
    it "keeps React + TypeScript/Next jobs" do
      stub_all_sources

      expect(fetch(described_class).map { it[:title] }).to eq([ "Full-stack Engineer (HealthTech, EHR/EMR, Terraform, React) USD - Strider" ])
    end
  end

  describe Sources::HackerNews do
    it "reads the latest Who is hiring thread and keeps remote Rails comments" do
      stub_all_sources

      postings = fetch(described_class)

      expect(postings).not_to be_empty
      expect(postings).to all(include(source: "hacker_news"))
      relevant = postings.find { it[:company] == "Relevant Healthcare" }
      expect(relevant).to include(title: "Lead Engineer", location_text: "Remote (US/Canada only)")
      expect(relevant[:url]).to start_with("https://news.ycombinator.com/item?id=")
    end

    it "returns nothing when there is no thread" do
      stub_request(:get, Sources::HackerNews::SEARCH_URL).to_return(body: { hits: [] }.to_json)

      expect(fetch(described_class)).to eq([])
    end
  end

  describe Sources::GoRails do
    it "splits role, company and location from the title" do
      stub_all_sources

      postings = fetch(described_class)

      expect(postings.size).to eq(4)
      expect(postings.first).to include(title: "Senior Full Stack Engineer", company: "Sincere Corporation", location_text: "Framingham, MA, Remote")
      expect(postings.second).to include(company: "SME Careers (via AI Gig Scout)")
      expect(postings.second[:title]).to start_with("Ruby Engineer (Remote, Contract, AI training)")
    end
  end

  def with_env(values)
    old = values.keys.index_with { ENV[it] }
    values.each { ENV[_1] = _2 }
    yield
  ensure
    old.each { ENV[_1] = _2 }
  end
end
